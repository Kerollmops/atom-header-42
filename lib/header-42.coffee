{CompositeDisposable} = require 'atom'
fs = require 'fs'
path = require 'path'
util = require 'util'
sprintf = require('sprintf-js').sprintf
moment = require 'moment'

module.exports = Header42 =
  subscriptions: null
  notifManager: null
  insertTemplateStr: null

  dateTimeFormat: null
  login: null
  mail: null
  byName: null
  timestampBy: null

  activate: (state) ->
    atom.workspace.observeTextEditors (editor) =>
      editor.getBuffer().onWillSave => @update(editor)

    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # all informations fields
    @dateTimeFormat = "YYYY/MM/DD HH:mm:ss"
    @login = process.env.USER ? "anonymous"
    @mail = "%s@student.42.fr"
    @byName = "%s <%s>"
    @timestampBy = "%s by %s"

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'header-42:insert': => @insert()

  deactivate: ->
    @subscriptions.dispose()

  getHeaderType: (basename) ->
    headers = [
        ['^(Makefile)$',                                'Makefile.header'],
        ['^.*\.(c|cpp|h|js|css|cs|scala|rs|go|swift)$', 'C.header'],
        ['^.*\.(php)$',                                 'Php.header'],
        ['^.*\.(html)$',                                'Html.header'],
        ['^.*\.(lua)$',                                 'Lua.header'],
        ['^.*\.(ml|mli)$',                              'OCaml.header'],
        ['^.*\.(hs)$',                                  'Haskell.header'],
        ['^.*\.(s|s64|asm|hs|h64|inc)$',                'ASM.header']
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

  # TODO don't need moment dependency
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
        return [matches[1], matches[2]]
    return (null)

  update: (editor) ->
    if matches = @hasHeader(editor.getBuffer().getText())
      buffer = editor.getBuffer()
      lines = buffer.getLines()
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
