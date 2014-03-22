cssauron = require 'cssauron'

class Model
  constructor: (@root) ->
    @root.model = @
    @root.root  = @root

    @ids      = {}
    @classes  = {}
    @types    = {}
    @nodes    = []

    # Prepare CSSauron
    @language = cssauron
      tag:      'type'
      id:       'id'
      class:    "classes.join(' ')"
      parent:   'parent'
      children: 'children'

    # Track object lifecycle
    @_add = (event) =>
      object = event.object
      @_adopt object
      @_update event, object, true

    @_remove = (event) =>
      object = event.object
      @_dispose object

    # Triggered by node addition/removal
    @on 'added',   @_add
    @on 'removed', @_remove

    @_adopt = (object) ->
      addNode object
      addType object
      object.on 'change', @_update

    @_dispose = (object) ->
      removeNode object
      removeType object
      removeID      object.id
      removeClasses object.classes
      object.off 'change', @_update

    # Track id/class changes
    @_update = (event, object, force) =>
      _id    = force or event.changed['node.id']
      _klass = force or event.changed['node.classes']
      return unless _id or _klass

      if _id
        id = object.get 'node.id'
        if id != object.id
          removeID object.id, object
          addID    id,          object

      if _klass
        classes = object.get 'node.classes'
        klass = classes.join ','
        if klass != object.klass
          removeClasses object.classes, object
          addClasses    classes,        object
          object.klass   = klass
          object.classes = classes.slice()

    addID = (id, object) =>
      if @ids[id]
        throw "Duplicate id `#{id}`"

      @ids[id] = object if id
      object.id = id

    removeID = (id, object) =>
      if id?
        delete @ids[id]
      delete object.id

    addClasses = (classes, object) =>
      if classes?
        for k in classes
          list = @classes[k] ? []
          list.push object
          @classes[k] = list

    removeClasses = (classes, object) =>
      if classes?
        for k in classes
          list = @classes[k]
          index = list.indexOf object
          list.splice index, 1 if index >= 0
          if list.length == 0
            delete @classes[k]

    # Track nodes and types
    addNode = (object) =>
      @nodes.push object

    removeNode = (object) =>
      @nodes.splice @nodes.indexOf(object), 1

    # Track objects by type
    addType = (object) =>
      type = object.type
      list = @types[type] ? []
      list.push object
      @types[type] = list

    removeType = (object) =>
      type = object.type
      list = @types[type] ? []
      index = list.indexOf object
      list.splice index, 1 if index >= 0
      if list.length == 0
        delete @types[type]

  # Querying via CSS selectors

  filter: (nodes, selector) ->
    selector = @language selector
    node for node in nodes when selector(node)

  select: (selectors) ->
    out    = []
    out    = out.concat @_select s for s in selectors.split /,/g
    unique = out.filter (object, i) -> out.indexOf(object) == i

  _select: (s) ->
    # Trim
    s = s.replace /^\s+/, ''
    s = s.replace /\s+$/, ''

    # Check for simple #id, .class or type selector
    id    = s.match /^#([A-Za-z0-9_]+)$/
    return        @ids[id[1]] || [] if id

    klass = s.match /^\.([A-Za-z0-9_]+)$/
    return @classes[klass[1]] || [] if klass

    type  = s.match /^[A-Za-z0-9_]+$/
    return    @types[type[0]] || [] if type

    # Otherwise iterate over everything
    @filter @nodes, s

  # Notify primitives of update
  update: () ->
    @trigger
      type: 'update'

  getRoot: () ->
    @root

THREE.Binder.apply Model::

module.exports = Model