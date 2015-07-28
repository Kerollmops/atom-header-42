Header42 = require '../lib/header-42'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Header42", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('header-42')

  describe "when the header-42:insert event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.header-42')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'header-42:insert'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.header-42')).toExist()

        # header42Element = workspaceElement.querySelector('.header-42')
        # expect(header42Element).toExist()
        #
        # header42Panel = atom.workspace.panelForItem(header42Element)
        # expect(header42Panel.isVisible()).toBe true
        # atom.commands.dispatch workspaceElement, 'header-42:insert'
        # expect(header42Panel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.header-42')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'header-42:insert'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        header42Element = workspaceElement.querySelector('.header-42')
        expect(header42Element).toBeVisible()
        atom.commands.dispatch workspaceElement, 'header-42:insert'
        expect(header42Element).not.toBeVisible()
