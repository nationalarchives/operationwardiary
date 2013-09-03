$ = require 'jqueryify'
Spine = require 'spine'

require '../lib/jquery-ui-1.10.3.custom.min.js'

require '../lib/google.maps.js'
require '../lib/jquery.ui.map.full.min.js'

Classification = require 'zooniverse/models/classification'
Subject = require 'zooniverse/models/subject'
User = require 'zooniverse/models/user'

ZoomableSurface = require './zoom_surface'
TextTool = require './text-tool'
{ToolControls} = ZoomableSurface
{Tool} = ZoomableSurface

class Classifier extends Spine.Controller
  
  template: require '../views/classifier'

  events:
    'click .task': 'onDoTask'
    'click .finish': 'onFinishTask'
    'click .back': 'onGoBack'
    'mousedown .zoom-in': 'onZoomIn'
    'mousedown .zoom-out': 'onZoomOut'
    'click .documents': ->
      @surface.enable()
      @toggleCategories()
      
    'click .categories': ->
      @surface.markingMode = true
      tool.controls.el.addClass 'closed' for tool in @surface.tools

  elements:
    '.subject-container': 'subjectContainer'
    
  helper:
    selectedCategory: (note) =>
      return
    selectedDocument: (document) =>
      return
        
  defaults = 
    category: 'date'

  constructor: ->
    super
    
    @defaults = defaults
    @surface_history = {}
    
    @render()

    @category = @defaults.category
    @subject_id = 194
	
    @surface ?= new ZoomableSurface
      tool: TextTool
      container: @subjectContainer
      width: 1024
      height: 560
      clickDelay: 300
      
    @surface.dotRadius = 5
      
    @subjectContainer.css 'position', 'relative'
    @surface.image.node.setAttributeNS null,"preserveAspectRatio" , "xMidYMid meet"
    @surface.loadImage "img/0#{@subject_id}.jpg"
    # HACK: turn off image scaling/resizing in SVG.
    

    User.on 'change', @onUserChange
    Subject.on 'select', @onSubjectSelect
    

  render: =>

    @html @template(@)
  
  render_annotation: ( history ) ->
    
    $('.categories :checked, .documents :checked')
      .removeAttr('checked')
      .prop('checked', false)
    
    for tool in @surface.tools
      tool.controls.el.remove() 
      tool.shapeSet.remove()
  
    @surface.resetTools()
    
    history?.render()
    @toggleCategories()

  onUserChange: (e, user) =>
    # user, User.current

    if user
      #alert 'hello user!'
    else
      alert 'you arent a user!'

    Subject.next()

  onSubjectSelect: (e, subject) =>
    # Subject.current

    @classification = new Classification { subject }
    
  onDoTask: =>
    document = $( '.documents :checked' ).val()
    annotation = 
      document: document
      marks: @surface.marks.slice(0)
    @classification.annotate annotation
    console?.log 'Classifying', JSON.stringify @classification

  onFinishTask: =>
    # @classification.send()
      
    @update_history()

    @subject_id++
    @surface
      .loadImage("img/0#{@subject_id}.jpg")
      .done( =>
        @classification.subject.trigger 'select'
        @render_annotation @surface_history[ @subject_id ]
      )

  onZoomIn: ({currentTarget})=>
    @surface.selection?.deselect()
    timeout = null

    zoom_in = =>
      @surface.zoom @surface.zoomBy + .2
      clearTimeout timeout if timeout
      timeout = setTimeout zoom_in, 200
      
    zoom_in()
    
    $( currentTarget ).one( 'mouseup', -> clearTimeout timeout )
    
  onZoomOut: ({currentTarget})=>
    @surface.selection?.deselect()
    timeout = null

    zoom_out = =>
      @surface.zoom @surface.zoomBy - .2
      clearTimeout timeout if timeout
      timeout = setTimeout zoom_out, 200
      
    zoom_out()
    
    $( currentTarget ).one( 'mouseup', -> clearTimeout timeout )
    
    
  onGoBack: ->
    @update_history()
    @subject_id--
    @surface
      .loadImage("img/0#{@subject_id}.jpg")
      .done( =>
        @classification.subject.trigger 'select'
        @render_annotation @surface_history[ @subject_id ]
      )
    
  
  update_history: ->
    
    snapshot = new MarkingHistory @surface
    
    @surface_history[ @subject_id ] = snapshot
    
  toggleCategories: ->
    if $('.documents :checked').val() is 'diary'
      $('.categories').css
        'visibility': 'visible'
    else
      $('.categories').css
        'visibility': 'hidden'
    
class MarkingHistory
  
  surface: null
  
  constructor: ( @surface ) ->
    
    @document = $( '.documents :checked' ).val()
    @tools = []
    @marks = []
    
    for tool in @surface.tools
      @tools.push tool
      @marks.push tool.mark
  
  render: ->
    
    $( "#document-#{@document}")
      .attr('checked', 'checked')
      .prop('checked', true)
    
    for tool in @tools
      @surface.tools.push tool
      @surface.marks.push tool.mark
      tool.draw()
      tool.controls.el.appendTo tool.surface.container
      tool.controls.bind_events()
      tool.render()
      
    @surface.enable()


module.exports = Classifier
