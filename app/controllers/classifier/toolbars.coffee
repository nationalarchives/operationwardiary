Spine = require 'spine'

Editor = require '../../lib/text-widgets'
{WidgetFactory} = Editor
{toolbars} = Editor


class Toolbars extends Spine.Controller
  template: require '../../views/classifier/toolbars'
      
  elements:
    '#document-metadata': 'metadata'
    
  helper:
    selectedCategory: (note) =>
      return
    selectedDocument: (document) =>
      return
        
  events:
    'change .documents': ->
      @el.trigger 'pickDocument'
      @toggleCategories()
    'change .categories': ->
      @el.trigger 'pickCategory'

  constructor: ->
    super
    
    @render()

  render: =>
    @html @template(@)
    
  toggleCategories: ->
    category = $('.documents :checked').val()
    @metadata.html ''
    
    toolbar = toolbars[ category ] ? { template: '' }
      
    switch category
      when 'orders'
        orders = WidgetFactory.makeWidget 'orders'
        @metadata.html orders.template
      
    $('.toolbar').html toolbar.template
    $('.categories').css
      'visibility': 'visible'
  

module.exports = Toolbars