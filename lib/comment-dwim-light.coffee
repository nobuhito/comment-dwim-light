{CompositeDisposable} = require 'atom'

module.exports = CommentDwimLight =
  subscriptions: null

  config:
    commentColumn:
      tilte: "comment-column"
      type: 'integer'
      default: 40
    commentFillColumn:
      tile: "comment-fill-column"
      type: "integer"
      default: 40

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'comment-dwim-light:toggle': => @toggle()

    pll = atom.config.get("editor.preferredLineLength")
    cfc = atom.config.get("comment-dwim-light.commentFillColumn")
    @cc = atom.config.get("comment-dwim-light.commentColumn")
    @cc = @cc + cfc - pll if (pll < @cc + cfc)

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    commentDwimLightViewState: @commentDwimLightView.serialize()

  editor: ->
    atom.workspace.getActiveTextEditor()

  toggle: ->
    e = @editor()
    c = e.getLastCursor()
    scopes = c.getScopeDescriptor().scopes
    config = atom.config.get('editor', scope: scopes)
    @startComment = config.commentStart
    @endComment = config.commentEnd
    @endComment = "" if (@endComment is "*/" and @startComment != "/*")

    @lineText = c.getCurrentBufferLine()

    r = e.getSelectedBufferRange()

    if r.start.row != r.end.row
      @multiLine(e)
    else if @lineText.trim() is ""
      @newLine(e)
    else
      @editedLine(e)

  multiLine: (e) ->
    e.toggleLineCommentsInSelection()

  newLine: (e) ->
    e.autoIndentSelectedRows()
    @insertComment(e)

  editedLine: (e) ->

    if (@lineText.indexOf(@startComment) > -1)
      @addComment(e)
      return undefined

    @cc = @lineText.length + 1 if (@lineText.length > @cc)
    @cp = e.getCursorBufferPosition()
    e.setCursorBufferPosition([@cp.row, @cc])

    space = ""
    space += " " for i in [0..(@cc - @lineText.length)]
    e.insertText(space)

    @insertComment(e)

  insertComment: (e) ->
    e.insertText(@startComment)
    cp = e.getCursorBufferPosition()
    e.insertText(@endComment)
    e.setCursorBufferPosition([cp.row, cp.column])

  addComment: (e) ->
    cp = e.getCursorBufferPosition()
    if (@endComment != "" and @lineText.indexOf(@endComment) > -1)
      e.setCursorBufferPosition([cp.row, @lineText.indexOf(@endComment)])
    else
      e.setCursorBufferPosition([cp.row, @lineText.length + 1])
