{CompositeDisposable} = require 'atom'
fs = require 'fs'
path = require 'path'

module.exports = Header42 =
  subscriptions: null
  insertTemplateStr: null

  activate: (state) ->
    atom.workspace.observeTextEditors (editor) =>
      editor.getBuffer().onWillSave =>
        @update(editor.getBuffer())

    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'header-42:insert':
      => @insert()

  deactivate: ->
    @subscriptions.dispose()

  get_header_type: (basename) ->
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

  get_header_text: (editor) ->
    basename = path.basename(editor.getPath())
    filename = @get_header_type(basename)
    if filename != null
      return fs.readFileSync(filename, encoding: "utf8")
    null

  get_header: (editor) ->
    dirty_header = @get_header_text(editor)
    index = 0
    dirty_header.replace /%-(\d*)s/g, (match, p1) ->

      # do it cleanestly !!!!
      infos = [
        path.basename(editor.getPath()), # filename
      ]
      if index < infos.length
        text = infos[index]
      else
        text = ""
      # !!!!!!!!!!!!

      index++ # to know which text to add
      len = parseInt(p1)
      text.concat(Array((len - text.length) + 1).join(' '))

  update: (buffer) ->
    # console.log(buffer)

  insert: (event) ->
    editor = atom.workspace.getActiveTextEditor()
    buffer = editor.getBuffer()
    header = @get_header(editor)
    if header != null
      buffer.insert([0, 0], header, normalizeLineEndings: true)
      buffer.save()
