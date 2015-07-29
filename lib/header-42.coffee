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
  timestamp: null

  activate: (state) ->
    atom.workspace.observeTextEditors (editor) =>
      editor.getBuffer().onWillSave =>
        @update(editor.getBuffer())

    # all informations filled
    @dateTimeFormat = "YYYY/MM/DD HH:mm:ss"
    @login = process.env.USER ? "anonymous"
    @mail = sprintf("%s@student.42.fr", @login)
    @byName = sprintf("%s <%s>", @login, @mail)
    @timestamp = sprintf("%s by %s", "%s", @login)

    # inform user that the header 42 package has been activated
    atom.notifications.addInfo(sprintf "Header activated for user %s", @login)

    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'header-42:insert':
      => @insert()

  deactivate: ->
    @subscriptions.dispose()

  getHeaderType: (basename) ->
    headers = [
        ['^(Makefile)$',                            'Makefile.header'],
        ['^.*\.(c|h|js|css|cs|scala|rs|go|swift)$', 'C.header'],
        ['^.*\.(php)$',                             'Php.header'],
        ['^.*\.(html)$',                            'Html.header'],
        ['^.*\.(lua)$',                             'Lua.header'],
        ['^.*\.(ml|mli)$',                          'OCaml.header'],
        ['^.*\.(hs)$',                              'Haskell.header'],
        ['^.*\.(s|s64|asm|hs|h64|inc)$',            'ASM.header']
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

  getHeader: (editor) ->
    dirty_header = @getHeaderText(editor)
    filename = path.basename(editor.getPath())
    created = sprintf(@timestamp, moment().format(@dateTimeFormat))
    updated = sprintf(@timestamp, moment().format(@dateTimeFormat))
    sprintf(dirty_header, filename, @byName, created, updated)

  update: (buffer) ->
    # console.log(buffer)
    console.log sprintf(@timestamp, moment().format(@dateTimeFormat))

  insert: (event) ->
    editor = atom.workspace.getActiveTextEditor()
    buffer = editor.getBuffer()
    header = @getHeader(editor)
    if header != null
      buffer.insert([0, 0], header, normalizeLineEndings: true)
      buffer.save()
