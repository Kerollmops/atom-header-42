{CompositeDisposable} = require 'atom'

module.exports = Header42 =
  subscriptions: null
  insertTemplateStr: null

  activate: (state) ->
    atom.workspace.observeTextEditors (editor) =>
        editor.getBuffer().onWillSave => @update(editor.getBuffer())

    #
    # regex: %-(\d*)s

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'header-42:insert': => @insert()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    header42ViewState: @header42View.serialize()

  update: ->
    #

  insert: ->
    console.log 'Header42 was toggled!'
    textEditor = atom.workspace.getActiveTextEditor()
    textEditor.markBufferPosition([0, 0], invalidate: 'never')
    console.log(textEditor)
