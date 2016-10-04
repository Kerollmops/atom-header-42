{CompositeDisposable} = require 'atom'
fs = require 'fs'
path = require 'path'
util = require 'util'
sprintf = require('sprintf-js').sprintf
moment = require 'moment'

String::rstrip = -> @replace /\s+$/g, ""

module.exports = Header42 =
  config:
    login:
      type: 'string'
      default: (process.env.USER ? "anonymous")
      description: 'Change the default login used in the header.'

  subscriptions: null
  notifManager: null
  insertTemplateStr: null

  dateTimeFormat: "YYYY/MM/DD HH:mm:ss"
  mail: "%s@student.42.fr"
  byName: "%s \<%s\>"
  timestampBy: "%s by %s"

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'header-42.login', (login) =>
      @login = login

    atom.workspace.observeTextEditors (editor) =>
      editor.getBuffer().onWillSave => @update(editor)

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'header-42:insert': => @insert()

  deactivate: ->
    @subscriptions.dispose()

  # TODO: use atom file type and not file extension
  getHeaderType: (basename) ->
    headers = [
        ['^(Makefile)$',                                    'Makefile.header'],
        ['^.*\.(sh)$',										'Makefile.header'],
        ['^.*\.(html|ejs)$',                              	'Html.header'],
        ['^.*\.(c|cpp|h|hpp|js|css|cs|scala|rs|go|swift)$', 'C.header'],
        ['^.*\.(php)$',                                     'Php.header'],
        ['^.*\.(lua)$',                                     'Lua.header'],
        ['^.*\.(ml|mli)$',                                  'OCaml.header'],
        ['^.*\.(hs)$',                                      'Haskell.header'],
        ['^.*\.(s|s64|asm|hs|h64|inc)$',                    'ASM.header']
    ]

    for [regex, file] in headers
      regexPattern = RegExp(regex)
      if (basename.match(regexPattern))
        return path.join(__dirname, "headers", file)
    null

  getHeaderText: (editor) ->
    basename = path.basename(editor.getPath())
    filename = @getHeaderType(basename)

    if filename != null
      return fs.readFileSync(filename, encoding: "utf8")
    null

  getHeader: (editor, createInfo = null) ->
    dirty_header = @getHeaderText(editor)
    filename = path.basename(editor.getPath())
    if createInfo == null
      login = @login
      created = sprintf(@timestampBy, moment().format(@dateTimeFormat), login)
    else
      login = createInfo[1]
      created = sprintf(@timestampBy, createInfo[0], login)
    byName = sprintf(@byName, login, sprintf(@mail, login))
    updated = sprintf(@timestampBy, moment().format(@dateTimeFormat), @login)

    sprintf(dirty_header, filename, byName, created, updated)

  hasHeader: (buffer) ->
    byPat = /By: .{1,8} <.{1,8}@student\.42\.fr>/
    updatedPat = /Updated: \d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} by .{1,8}/
    createdPat = /Created: (\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}) by (.{1,8})/

    if buffer.match byPat && buffer.match updatedPat
      if matches = buffer.match createdPat
        return [matches[1].rstrip(), matches[2].rstrip()]
    return (null)

  update: (editor) ->
    if matches = @hasHeader(editor.getBuffer().getText())
      buffer = editor.getBuffer()
      header = @getHeader(editor, matches)
      header_lines = header.split(/\r\n|\r|\n/).length
      if header != null
        buffer.setTextInRange([[0, 0], [header_lines - 1, 0]], header,
          normalizeLineEndings: true)

  insert: (event) ->
    editor = atom.workspace.getActiveTextEditor()
    header = @getHeader(editor)
    buffer = editor.getBuffer()

    if @hasHeader(buffer.getText()) == null
      if header != null
        buffer.insert([0, 0], header, normalizeLineEndings: true)
