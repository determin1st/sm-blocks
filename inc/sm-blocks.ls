"use strict"
smBlocks = do ->
	# base
	# TODO {{{
	# - NEW STRUCTURE REFACTORING!!!!!!!!!!!!!
	# - determine optimal height for paginator/orderer (CSS)
	# - lock -1/0/1
	# - category count display (extra)
	# - static paginator max-width auto-calc
	# - grid's goto next page + scroll up (?)
	# }}}
	# helpers {{{
	consoleError = (msg) !-> # {{{
		a = '%csm-blocks: %c'+msg
		console.log a, 'font-weight:bold;color:slateblue', 'color:orange'
	# }}}
	consoleInfo = (msg) !-> # {{{
		a = '%csm-blocks: %c'+msg
		console.log a, 'font-weight:bold;color:slateblue', 'color:aquamarine'
	# }}}
	newPromise = -> # {{{
		# create a custom promise
		r = null
		p = new Promise (resolve) !->
			r := resolve
		# create a resolver
		p.pending = true
		p.resolve = (data) !->
			p.pending = false
			r data
		# create a continuator
		p.spin = ->
			# create another
			a = newPromise!
			# resolve
			p.pending = false
			r!
			# replace
			p.resolve = a.resolve
			p.spin    = a.spin
			# done
			return a
		# done
		return p
	# }}}
	newDelay = (ms) -> # {{{
		# create custom promise
		p = newPromise!
		# start timer
		t = setTimeout !->
			p.resolve true
		, ms
		# add cancellation
		p.cancel = !->
			clearTimeout t
			p.resolve false
		# done
		return p
	# }}}
	querySelectorChildren = (parentNode, selector) -> # {{{
		# prepare
		a = []
		if not parentNode or not parentNode.children.length
			return a
		# select all and
		# filter into result
		for b in parentNode.querySelectorAll selector
			if b.parentNode == parentNode
				a[*] = b
		# done
		return a
	# }}}
	querySelectorChild = (parentNode, selector) -> # {{{
		# check
		if not parentNode
			return null
		# reuse
		a = querySelectorChildren parentNode, selector
		# done
		return if a.length
			then a.0
			else null
	# }}}
	queryFirstChildren = (list) -> # {{{
		# check
		if not list or not list.length
			return null
		# collect
		a = []
		for b in list
			a[*] = b.firstChild
		# done
		return a
	# }}}
	# }}}
	# fetchers {{{
	soFetch = httpFetch.create {
		baseUrl: '/?rest_route=/sm-blocks/kiss'
		mounted: true
		notNull: true
		method: 'POST'
	}
	oFetch = httpFetch.create {
		baseUrl: '/?rest_route=/sm-blocks/kiss'
		mounted: true
		notNull: true
		method: 'POST'
		timeout: 0
		parseResponse: 'stream'
	}
	# }}}
	# slaves
	sMainSection = do -> # {{{
		# constructors
		Item = (block, node, parent) !-> # {{{
			# base
			@block  = block
			@node   = node
			@parent = parent
			# state
			@config  = JSON.parse node.dataset.cfg
			@hovered = false
			@focused = false
			@opened  = node.classList.contains 'opened'
			# controls
			# {{{
			@titleBox = box  = querySelectorChild node, '.title'
			@section  = sect = querySelectorChild node, '.section'
			if box
				@title = querySelectorChild box, 'h3'
				@arrow = querySelectorChild box, '.arrow'
			else
				@title = null
				@arrow = null
			# }}}
			# handlers
			@hover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if not @block.locked
					e.currentTarget.classList.add 'h'
					if not @hovered and \
					   (not @config.extra or \
					    e.currentTarget == @arrow)
						###
						@hovered = true
						@node.classList.add 'hovered'
						# set extra hover
						if not @config.extra
							if e.currentTarget == @title
								@arrow.classList.add 'h'
							else
								@title.classList.add 'h'
						# autofocus
						if not @block.focused
							@block.onAutofocus @arrow
			# }}}
			@unhover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if not @block.locked
					e.currentTarget.classList.remove 'h'
					if @hovered
						@hovered = false
						@node.classList.remove 'hovered'
						if not @config.extra
							if e.currentTarget == @title
								@arrow.classList.remove 'h'
							else
								@title.classList.remove 'h'
			# }}}
			@focus = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if not @block.locked and not @focused
					@focused = @block.focused = true
					e @ if e = @block.onFocus
					@node.classList.add 'focused'
					@arrow.classList.add 'f'
					if not @config.extra
						@title.classList.add 'f'
			# }}}
			@unfocus = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if not @block.locked and @focused
					@focused = @block.focused = false
					e @ if e = @block.onFocus
					@node.classList.remove 'focused'
					@arrow.classList.remove 'f'
					if not @config.extra
						@title.classList.remove 'f'
			# }}}
			@switch = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# operate
				if not @block.locked and @config.arrow and \
				   (not @config.extra or e.currentTarget == @arrow)
					###
					@opened = !@opened
					@node.classList.toggle 'opened', @opened
					if not @focused and @arrow
						@arrow.focus!
					# callback
					e @ if e = @block.onChange
			# }}}
			@keydown = (e) !~> # {{{
				# check enabled
				if @block.locked or \
				   e.keyCode not in [38 40 37 39 75 74 72 76]
					###
					return
				# fulfil the event
				e.preventDefault!
				e.stopPropagation!
				# operate
				switch e.keyCode
				case 38, 75 # Up|k
					# pass focus up {{{
					# operate
					if a = @searchArrow true
						# ask controller
						if (e = @block.onRefocus) and (e @, a, true)
							return
						# pass
						a.arrow.focus!
					# }}}
				case 40, 74 # Down|j
					# pass focus down {{{
					# operate
					if a = @searchArrow false
						# ask controller
						if (e = @block.onRefocus) and (e @, a, false)
							return
						# pass
						a.arrow.focus!
					# }}}
				case 37, 72 # Left|h
					# close section {{{
					if @opened
						# operate
						@opened = false
						@node.classList.remove 'opened'
						# callback
						e @ if e = @block.onChange
					else if e = @block.onRefocus
						# refocus
						e @, null, true
					# }}}
				case 39, 76 # Right|l
					# open section {{{
					if not @opened
						# operate
						@opened = true
						@node.classList.add 'opened'
						# callback
						e @ if e = @block.onChange
					else if e = @block.onRefocus
						# refocus
						e @, null, false
					# }}}
				# done
			# }}}
			# children
			# {{{
			if (a = querySelectorChildren sect, '.item').length
				# set and recurse
				@children = a
				for b,c in a
					a[c] = new Item block, b, @
			else
				# leaf node
				@children = null
			# }}}
		###
		Item.prototype =
			attach: !-> # {{{
				# prepare
				B = @block
				# check arrow mode enabled and
				# set section switch handlers
				if @block.rootItem.config.mode .&. 4
					if a = @arrow
						a.addEventListener 'pointerenter', @hover
						a.addEventListener 'pointerleave', @unhover
						a.addEventListener 'focusin', @focus
						a.addEventListener 'focusout', @unfocus
						a.addEventListener 'keydown', @keydown
						a.addEventListener 'click', @switch
					if a = @title
						a.addEventListener 'pointerenter', @hover
						a.addEventListener 'pointerleave', @unhover
						a.addEventListener 'click', @switch
				# recurse to children
				if a = @children
					for b in a
						b.attach!
			# }}}
			detach: !-> # {{{
				true
			# }}}
			setClass: (name, flag = true) !-> # {{{
				# recurse to children
				if a = @children
					for b in a
						b.setClass name, flag
				# apply on self
				@node.classList.toggle name, flag
			# }}}
			searchArrow: (direction) !-> # {{{
				# WARNING: highly imperative
				if direction
					# UPWARD {{{
					##[A]##
					# drop to upper siblings
					if (a = @).parent
						# prepare
						b = a.parent.children
						c = b.indexOf a
						# find last sibling section
						while --c >= 0
							if b[c].children
								# focus if closed
								if not (a = b[c]).opened
									return a
								# skip to [B]
								break
						# when no sibling sections found,
						# focus to parent
						if !~c
							return a.parent
					##[B]##
					# drop to the last child section of the opened sibling
					while b = a.children
						# prepare
						c = b.length
						# find last child section
						while --c >= 0
							if b[c].children
								# focus if closed
								if not (a = b[c]).opened
									return a
								# continue diving..
								break
						# end with opened section
						# if it doesn't have any child sections
						break if !~c
					# done
					# }}}
				else
					# DOWNWARD {{{
					##[A]##
					# dive into inner area
					if (a = @).opened
						# prepare
						if not (b = a.children)
							return a
						# find first child section
						c = -1
						while ++c < b.length
							if b[c].children
								return b[c]
					##[B]##
					# drop to lower siblings
					while b = a.parent
						# prepare
						c = b.children
						d = c.indexOf a
						# find first sibling section
						while ++d < c.length
							if c[d].children
								return c[d]
						# no sibling sections found,
						# bubble to parent and try again..
						a = a.parent
					# re-cycle focus to the root..
					# }}}
				# done
				return a
			# }}}
			getLastVisible: -> # {{{
				# check self
				if not (a = @children) or not @opened
					return @
				# search recursively
				return a[a.length - 1].getLastVisible!
			# }}}
			getNextVisible: -> # {{{
				# check self
				if @children and @opened
					return @children.0
				# navigate
				a = @
				while b = a.parent
					# get next sibling
					c = b.children
					if (d = c.indexOf a) < c.length - 1
						return c[d + 1]
					# climb up the tree..
					a = b
				# done
				return a
			# }}}
		# }}}
		Block = (root, state) !-> # {{{
			# base
			@root     = root
			@rootBox  = box  = root.firstChild
			@rootItem = root = new Item @, box, null
			@lines    = querySelectorChildren box, 'svg'
			# controls
			@sect     = sect = {}     # with section (parents)
			@item     = item = {}     # all
			@list     = list = [root] # all ordered
			# assemble tree
			# {{{
			a = -1
			while ++a < list.length
				if (b = list[a]).children
					sect[b.config.id] = b
					list.push ...b.children
				item[b.config.id] = b
			# }}}
			# state
			@state    = state
			@focused  = false
			@locked   = 1
			@class    = {}
			# handlers
			@onChange  = null
			@onFocus   = null
			@onRefocus = null
			@onAutofocus = (node) !~> # {{{
				if @rootItem.config.autofocus
					if @rootItem.arrow
						@rootItem.arrow.focus!
					else if node
						node.focus!
			# }}}
		###
		Block.prototype =
			init: ->> # {{{
				@rootItem.attach!
				@root.classList.add 'v'
				return true
			# }}}
			lock: (level) !-> # {{{
				# check
				switch level
				case 1
					if not @locked
						@rootItem.setClass 'v', false
				default
					if @locked
						@rootItem.setClass 'v', true
				# set
				@locked = level
			# }}}
			setClass: (k, v) !-> # {{{
				# check
				a = @class
				if not (a.hasOwnProperty k) or a[k] != v
					# set
					a[k] = v
					@rootBox.classList.toggle k, !!v
			# }}}
			setTitle: (name) !-> # {{{
				@rootItem.title.firstChild.textContent = name
			# }}}
			refresh: !-> # {{{
				# done
			# }}}
			finit: !-> # {{{
				@root.classList.remove 'v'
				@rootItem.detach!
			# }}}
		# }}}
		# factory
		return (node, state) ->
			return new Block node, state
	# }}}
	sCard = do -> # {{{
		return null
	# }}}
	# masters
	mProducts = do -> # SINGLETON {{{
		mCart = do -> # {{{
			# prepare
			data = null
			# create api
			return {
				add: (id) ->> # {{{
					# fetch
					a = await soFetch {
							func: 'cart'
							op: 'set'
							id: id
					}
					# check
					if a instanceof Error
						return false
					# TODO: optional, back-compat
					# send woo-notification
					# get cart data
					a = wc_add_to_cart_params.wc_ajax_url.replace '%%endpoint%%', 'get_refreshed_fragments'
					a = await httpFetch {
						url: a
						notNull: true
					}
					# check
					if a instanceof Error
						return true
					# notify
					jQuery document.body .trigger 'added_to_cart', [
						a.fragments
						a.cart_hash
						null
					]
					# done
					return true
				# }}}
				get: (id) -> # {{{
					# check
					if not data
						return null
					# search
					for a,b of data when b.product_id == id
						return b
					# not found
					return null
				# }}}
				load: ->> # {{{
					# get cart contents
					a = await soFetch {
						func: 'cart'
						op: 'get'
					}
					# check
					if a instanceof Error
						return null
					# done
					return data := a
				# }}}
			}
		# }}}
		# CARD handler {{{
		# constructors
		Box = (node) !-> # {{{
			@box  = node
			@data = null
			@set  = null
			@cls  = null
		# }}}
		Data = (box, value) !-> # {{{
			# create object shape
			@box         = box
			@container   = box.children.0
			@placeholder = box.children.1
			@value       = value
			@config      = null
		###
		Data.prototype = {
			loaded: !->
				@box.classList.add 'loaded'
			unloaded: !->
				@box.classList.remove 'loaded'
		}
		# }}}
		# factories
		newImageBlock = do -> # {{{
			loaded = (block) -> !-> # {{{
				# prepare
				img = block.data.value
				# check image successfully loaded
				if img.complete and img.naturalWidth != 0
					block.data.loaded!
			# }}}
			set = (data) !-> # {{{
				# get related data
				if data = data.image
					# prepare
					img = @data.value
					# set image attributes
					for a,b of data
						img[a] = b
			# }}}
			cls = !-> # {{{
				# clear image attributes
				a = @data.value
				a.srcset = a.src = ''
				@data.unloaded!
			# }}}
			return (node) ->
				# create a block
				a = new Box node
				# get the image and
				# set event handlers
				img = node.querySelector 'img'
				img.addEventListener 'load', loaded a
				# initialize block
				a.data = new Data node, img
				a.set  = set
				a.cls  = cls
				# done
				return a
		# }}}
		newTitleBlock = do -> # {{{
			set = (data) !-> # {{{
				# apply automatic break-lines feature,
				# using special markers
				a = data.name.replace /\s+([\\\|/.]){1}\s+/, "\n"
				# set text content
				@data.container.innerText = a
				@data.loaded!
			# }}}
			cls = !-> # {{{
				# remove text
				@data.container.innerText = ''
				@data.unloaded!
			# }}}
			return (node) ->
				# create a block
				a = new Box node
				# initialize
				a.data = new Data node, null
				a.set  = set
				a.cls  = cls
				# done
				return a
		# }}}
		newPriceBlock = do -> # {{{
			map = [ # {{{
				'.currency'
				'.dot'
				'.r0'
				'.r1'
				'.c0'
				'.c1'
			]
			expThousandSplit = /\B(?=(\d{3})+(?!\d))/
			expValueSplit = /[^0-9]/
			# }}}
			set = (data) !-> #  # {{{
				# prepare
				v = @data.value
				c = gridState.config.currency # :|
				# check
				if d = data.price # [regular_price,price]
					# split decimal parts
					a = d.0.split expValueSplit, 2
					b = d.1.split expValueSplit, 2
					# truncate mantissa
					a.1 = if a.1
						then (a.1.substring 0, c.3).padEnd c.3, '0'
						else '0'.repeat c.3
					b.1 = if b.1
						then (b.1.substring 0, c.3).padEnd c.3, '0'
						else '0'.repeat c.3
					# split thousands
					if c.2
						a.0 = a.0.replace expThousandSplit, c.2
						b.0 = b.0.replace expThousandSplit, c.2
					# map data
					c = [c.0, c.1, a.0, a.1, b.0, b.1]
					# set values
					for n,i in @data.value when n
						n.forEach (n) !->
							n.textContent = c[i]
					# compose full values (dot notation strings)
					c = a.0 + '.' + a.1
					d = b.0 + '.' + b.1
					# set states
					# the difference class
					if c != d
						# compare and set
						@data.container.classList.add if c > d
							then 'lower'
							else 'higher'
					# currency sign position
					if gridState.config.currency.4 # :|
						# right (the default is left)
						@data.container.classList.add 'right'
				else
					# no price specified
					@data.container.classList.add 'none'
				# complete
				@data.loaded!
			# }}}
			cls = !-> # {{{
				# clear values
				for n,i in @data.value when n
					n.forEach (n) !->
						n.textContent = ''
				# done
				@data.unloaded!
			# }}}
			return (node) ->
				# create a block
				a = new Box node
				# get elements
				e = map.map (e) ->
					e = [...node.querySelectorAll e]
					return if e.length
						then e
						else null
				# check
				if (e.every (e) -> e == null)
					e = null
				# initialize
				a.data = new Data node, e
				a.set  = set
				a.cls  = cls
				# done
				return a
		# }}}
		newControlBlock = do -> # {{{
			map = [ # {{{
				'.link'
				'.cart'
			]
			# }}}
			set = (data) !-> # {{{
				# prepare
				c = @data.config = []
				e = @data.value
				s = data.stock
				# set links
				e.0 and e.0.forEach (e) !->
					e.href = data.link
				# set add-to-carts
				e.1 and e.1.forEach (e, i) !->
					# check if product available
					if s.status != 'instock'
						e.classList.add 'none'
						return
					# check stock count and
					# set initial button state
					x = mCart.get data.id
					if s.count == 0 or (x and s.count <= x.quantity)
						e.disabled = true
					# create event handler and
					# store it for later removal
					c[i] = f = (a) !->>
						# prepare
						a.preventDefault!
						e.disabled = true
						# add simple single product to cart
						if not (a = await mCart.add data.id)
							return
						# reload cart items and
						# check if more items may be added
						if not await mCart.load!
							return
						x = mCart.get data.id
						if not x or s.count <= x.quantity
							return
						# unlock
						e.disabled = false
					# set it
					e.addEventListener 'click', f
				# complete
				@data.loaded!
			# }}}
			cls = !-> # {{{
				# prepare
				c = @data.config
				e = @data.value
				# clear links
				e.0 and e.0.forEach (e) !->
					e.href = ''
				# clear add-to-carts
				e.1 and e.1.forEach (e, i) !->
					e.removeEventListener 'click', c[i]
					e.disabled = false
					e.classList.remove 'none'
				# done
				@data.unloaded!
			# }}}
			return (node) ->
				# create a block
				a = new Box node
				# get elements
				e = map.map (e) ->
					e = [...node.querySelectorAll e]
					return if e.length
						then e
						else null
				# initialize
				a.data = new Data node, e
				a.set  = set
				a.cls  = cls
				# done
				return a
		# }}}
		newItem = do -> # {{{
			map = # name => selector/factory {{{
				name:  ['.title', newTitleBlock]
				image: ['.head', newImageBlock]
				price: ['.price', newPriceBlock]
				controls: ['.controls', newControlBlock]
			# }}}
			Item = (node) !-> # {{{
				# create object shape
				@node     = node
				@id       = 0
				@name     = null
				@image    = null
				@icon     = null
				@features = null
				@price    = null
				@controls = null
			###
			Item.prototype = {
				set: (data) !->
					# display item
					# set data
					@id = data.id
					for a of map when @[a]
						@[a].set data
					# done
					@node.classList.remove 'empty'
				cls: !->
					# clear item
					# remove data
					for a of map when @[a]
						@[a].cls!
					# done
					@node.classList.add 'empty'
			}
			# }}}
			return (node) ->
				# create an item
				a = new Item node
				# assemble blocks
				for b,c of map
					if d = node.querySelector c.0
						a[b] = c.1 d
				# done
				return a
		# }}}
		# }}}
		###
		Resizer = (block) !-> # {{{
			# base
			@block    = block
			@config   = c = block.config
			@style    = s = getComputedStyle block.rootBox
			@observer = o = new ResizeObserver (e) !~> @set e
			# config
			@columnsMin = c.columnsMin
			@columnsMax = c.columnsMax
			@columnsGap = parseInt (s.getPropertyValue '--column-gap')
			@rowsMin    = c.rowsMin
			@rowsMax    = c.rowsMax
			@rowsGap    = parseInt (s.getPropertyValue '--row-gap')
			@itemX      = parseInt (s.getPropertyValue '--item-max-x')
			@itemY      = parseInt (s.getPropertyValue '--item-max-y')
			@itemXA     = @itemX + @columnsGap / 2
			@itemYA     = @itemY + @rowsGap / 2
			@fontSizeMax = parseInt (s.getPropertyValue '--font-size')
			@ratio      = @itemY / @itemX # aspect ratio (ideal proportion)
			# current
			@width      = 0
			@fontSize   = 0
			@columns    = 0
			@rows       = 0
			# initialize
			o.observe block, {box: 'border-box'}
		###
		Resizer.prototype =
			set: (e) !-> # {{{
				# get current width
				x = if e
					then e.0.contentRect.width
					else root.clientWidth
				# determine current column/row count
				if state.columnsMin == state.columnsMax
					# fixed,
					# maximal-minimal
					state.columns = state.columnsMax
					state.rows    = state.rowsMin
				else
					# float
					if (a = x / state.itemXA .|. 0) > state.columnsMax
						# maximal-minimal
						state.columns = state.columnsMax
						state.rows    = state.rowsMin
					else if a < state.columnsMin
						# minimal-maximal
						state.columns = state.columnsMin
						state.rows    = state.rowsMax
					else
						# in between,
						# ceiling effectively covers the case,
						# when item count is less than column count
						state.columns = a
						state.rows    = Math.ceil (gridList.length / a)
				# determine ideal width/height
				# start with width
				a = state.columns
				w = if a == 1
					then state.itemX
					else state.itemX * a + state.columnGap * (a - 1)
				# check against current
				if w <= x
					# perfect fit
					a = state.rows
					state.width  = w
					state.height = if a == 1
						then state.itemY
						else state.itemY * a + state.rowGap * (a - 1)
					state.fontSize = state.fontSizeMax
				else
					# loose fit,
					# preserve aspect ratio
					a = x / w
					state.width  = x
					state.height = state.rows * state.itemYA * a
					state.fontSize = state.fontSizeMax * a
				# update
				@rootBox.style.setProperty '--columns', state.columns
				@rootBox.style.setProperty '--rows', state.rows
				@rootBox.style.setProperty '--height', state.height+'px'
				@rootBox.style.setProperty '--font-size', state.fontSize+'px'
				# dispatch resize event
				for c in gridControl
					c.event 'resize', state
			# }}}
		# }}}
		Block = (state, root) !-> # {{{
			# base
			@state   = state
			@root    = root
			@rootBox = box = root.firstChild
			@config  = JSON.parse box.dataset.cfg
			# controls
			@items   = [...box.children]
			@resizer = null
			# state
			@locked  = -1
			# handlers
			# ...
		###
		Block.prototype =
			group: 'products'
			level: 3
			configure: (o) !-> # {{{
				a = @config.columns
				o.limit = a.0 * a.1
				o.order = @config.orderTag
			# }}}
			init: (cfg) -> # {{{
				# operate
				#@resizer = new Resizer @
				# done
				return true
			# }}}
			lock: (level) ->> # {{{
				###
				@locked = level
				return true
			# }}}
			notify: -> # {{{
				return true
			# }}}
			refresh: !-> # {{{
				true
			# }}}
			eat: (record) -> # {{{
				return true
			# }}}
		# }}}
		return Block
	# }}}
	mCategoryFilter = do -> # {{{
		Checkbox = (block, item, parent = null) !-> # {{{
			# base
			@block  = block
			@item   = item
			@parent = parent
			# controls
			@checkbox = cbox = if item.titleBox
				then querySelectorChild item.titleBox, '.checkbox'
				else null
			# state
			@hovered = false
			@focused = false
			@state   = 0
			# handlers
			@hover = (e) !~> # {{{
				# fulfil the event
				e.preventDefault!
				# check
				if not @block.locked and \
				   not @hovered
					###
					@item.node.classList.add 'hovered-2'
					@hovered = true
					# autofocus
					if not @block.focused
						@block.onAutofocus @checkbox
			# }}}
			@unhover = (e) !~> # {{{
				# fulfil the event
				e.preventDefault!
				# check
				if @hovered
					@item.node.classList.remove 'hovered-2'
					@hovered = false
			# }}}
			@focus = (e) !~> # {{{
				# check
				if not @block.locked and \
				   not @focused
					###
					@item.node.classList.add 'focused-2'
					@focused = true
					@block.onFocus @
				else
					# try to prevent focus
					e.preventDefault!
					e.stopImmediatePropagation!
			# }}}
			@unfocus = (e) !~> # {{{
				# fulfil the event
				e.preventDefault!
				# check
				if @focused
					@item.node.classList.remove 'focused-2'
					@focused = false
					@block.onFocus @
			# }}}
			@check = (e) !~> # {{{
				# fulfil the event
				e.preventDefault!
				e.stopImmediatePropagation!
				# check
				if @block.locked
					return
				# switch current and
				# refresh block state
				@block.refresh @toggleCheckbox!
				# done
				@checkbox.focus!
			# }}}
			@keydown = (e) !~> # {{{
				# check enabled
				if @block.locked or \
				   e.keyCode not in [38 40 37 39 75 74 72 76]
					###
					return
				# fulfil the event
				e.preventDefault!
				e.stopPropagation!
				# operate
				switch e.keyCode
				case 38, 75 # Up|k
					# pass focus up {{{
					# get upper item
					a = @parent.children
					if (b = a.indexOf @) == 0
						a = @parent
					else
						a = a[b - 1].item.getLastVisible!
						a = @parent.get a.config.id
					# operate
					if a.checkbox
						a.checkbox.focus!
					else if a.item.arrow
						a.item.arrow.focus!
					# }}}
				case 40, 74 # Down|j
					# pass focus down {{{
					# get lower item
					a = @item.getNextVisible!
					a = @block.checks.get a.config.id
					# operate
					if a.checkbox
						a.checkbox.focus!
					else if a.item.arrow
						a.item.arrow.focus!
					# }}}
				case 37, 72 # Left|h
					# pass focus left {{{
					a.focus! if a = @item.arrow
					# }}}
				case 39, 76 # Right|l
					# pass focus right {{{
					a.focus! if a = @item.arrow
					# }}}
				# done
			# }}}
			# set children
			# {{{
			if item.children
				@children = a = []
				for c,b in item.children
					a[b] = new Checkbox block, c, @
			else
				@children = null
			# }}}
			# initialize
			# {{{
			# to avoid natural focus navigation problem,
			# re-attach the checkbox
			if cbox
				a = cbox.parentNode
				a.removeChild cbox
				a.insertBefore cbox, a.firstChild
			# }}}
		###
		Checkbox.prototype =
			attach: !-> # {{{
				# operate
				if a = @checkbox
					a.addEventListener 'pointerenter', @hover
					a.addEventListener 'pointerleave', @unhover
					a.addEventListener 'focusin',  @focus
					a.addEventListener 'focusout', @unfocus
					a.addEventListener 'click', @check
					a.addEventListener 'keydown', @keydown
					a = @item.title
					a.addEventListener 'pointerenter', @hover
					a.addEventListener 'pointerleave', @unhover
					a.addEventListener 'click', @check
					a.addEventListener 'keydown', @keydown
				# recurse
				if a = @children
					for c in a
						c.attach!
			# }}}
			detach: !-> # {{{
				true
			# }}}
			get: (id) -> # {{{
				# check self
				if id == @item.config.id
					return @
				# search children recursively
				if c = @children
					for a in c when (a = a.get id)
						return a
				# nothing
				return null
			# }}}
			setChildren: (items, v) -> # {{{
				# create change list
				list = []
				# iterate items
				for a in items when a.state != v
					# set child
					a.state = v
					list[*] = a
					# recurse
					if a.children
						list.push ...(@setChildren a.children, v)
				# done
				return list
			# }}}
			setParent: (item, v) -> # {{{
				# check
				if v == 2
					# this value may only come from another parent,
					# no need to check children
					a = 2
				else
					# assume state homogeneity and
					# iterate children to find the opposite
					a = v
					for b in item.children when b.state != a
						a = 2
						break
				# set
				if item.state == a
					b = []
				else
					item.state = a
					b = [item]
				# recurse and complete
				return if item.parent
					then (@setParent item.parent, a) ++ b
					else b
			# }}}
			toggleCheckbox: -> # {{{
				# settle self first
				@state = if @state == 2
					then 1 # force determinism
					else if @state
						then 0
						else 1
				# create change list
				list = [@]
				# set parents
				if @parent
					list.push ...(@setParent @parent, @state)
				# set children
				if @children
					list.push ...(@setChildren @children, @state)
				# done
				return list
			# }}}
			getCheckedIds: -> # {{{
				# check self
				list = if @state == 1 and @item.config.count > 0
					then [@item.config.id]
					else []
				# check children
				if @children
					for a in @children
						list.push ...(a.getCheckedIds!)
				# done
				return list
			# }}}
		# }}}
		Block = (state, root, index) !-> # {{{
			# base
			@state   = state
			@root    = root
			@index   = index
			@rootBox = rootBox = root.firstChild
			# controls
			@section = S = sMainSection root
			@checks  = new Checkbox @, S.rootItem
			# state
			@locked  = -1
			@focused = false
			# handlers
			S.onRefocus = (i1, i2, direction) ~> # {{{
				# prepare
				a = null
				# check destination
				if i2
					# up/down navigation for root
					if not i1.parent
						# pass to checkbox
						# get item
						if direction
							# last
							a = i1.getLastVisible!
							a = @checks.get a.config.id
						else
							# first
							a = @checks.get i1.children.0.config.id
				else
					# left/right breakout
					# direction doesn't matter for single checkbox
					a = @checks.get i1.config.id
				# custom
				if a and a.checkbox
					a.checkbox.focus!
				# default
				return !!a
			# }}}
			@onFocus = S.onFocus = do ~> # {{{
				p = null
				return (item) ~>>
					# check
					if p and p.pending
						p.resolve false
					# set
					if item.focused
						@focused = true
						@root.classList.add 'f'
					else if await (p := newDelay 60)
						@focused = false
						@root.classList.remove 'f'
					# done
					return true
			# }}}
			@onAutofocus = S.onAutofocus = (node) !~> # {{{
				if not @focused and \
				   (a = S.rootItem).config.autofocus
					###
					if a.arrow
						a.arrow.focus!
					else
						a.checks.checkbox.focus!
			# }}}
		###
		Block.prototype =
			group: 'category'
			level: 2
			init: (cfg) ->> # {{{
				# initialize
				if not (await @section.init!)
					return false
				# activate controls
				@checks.attach!
				# create individual data
				@state.data[@index] = []
				# done
				return true
			# }}}
			lock: (level) ->> # {{{
				###
				if level != @locked
					await @section.lock level
				###
				@locked = level
				return true
			# }}}
			notify: -> # {{{
				return true
			# }}}
			refresh: (list) !-> # {{{
				# it's assumed that categories doesn't intersect
				# in the attached UI root, so there may be
				# only single originator and the refresh is
				# the only source of the change..
				# (no external calls needed)
				if list
					# iterate change list and set visual state
					for a in list
						b = a.item.node.classList
						switch a.state
						case 2
							b.add 'checked', 'c2'
							b.remove 'c1'
						case 1
							b.add 'checked', 'c1'
							b.remove 'c2'
						default
							b.remove 'checked', 'c1', 'c2'
				# check
				if @index < 0
					return
				# determine current filter
				a = @checks.getCheckedIds!
				b = @state.data[@index]
				# compare arrays
				if d = ((c = a.length) == b.length)
					while --c >= 0
						if a[c] != b[c]
							d = false
							break
				# check the difference
				if not d
					# update array
					b.length = c = a.length
					while --c >= 0
						b[c] = a[c]
					# change the filter
					state.change!
				# done
			# }}}
		# }}}
		return Block
	# }}}
	mPriceFilter = do -> # {{{
		InputNum = (id, box) !-> # {{{
			# base
			@id    = id
			@box   = box
			@input = box.children.0
			@label = box.children.1
			# state
			@value   = '' # current
			@state   = ['' '' 0 0] # default/previous/selectionStart/End
			@changed = false
			@hovered = false
			@focused = false
			@locked  = true
			@regex   = /^[0-9]{0,9}$/
			# passive handlers
			@onHover  = null
			@onFocus  = null
			@onSubmit = null
			@onScroll = null
			@onChange = null
			# active handlers
			@hover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# operate
				if not @locked
					@hovered = true
					@box.classList.add 'hovered'
					e @ if e = @onHover
			# }}}
			@unhover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if @hovered
					@hovered = false
					@box.classList.remove 'hovered'
					e @ if e = @onHover
			# }}}
			@focus = (e) !~> # {{{
				# check
				if @locked
					# try to prevent
					e.preventDefault!
					e.stopPropagation!
				else
					# operate
					@focused = true
					@box.classList.add 'focused'
					@select!
					e @ if e = @onFocus
			# }}}
			@unfocus = (e) !~> # {{{
				# operate
				@focused = false
				@box.classList.remove 'focused'
				e @ if e = @onFocus
			# }}}
			@inputChange = (e) ~> # {{{
				# prepare
				s = @state
				v = @input.value
				w = @value
				# check
				if v.length
					# non-empty
					if not @regex.test v
						# invalid,
						# restore previous
						@input.value = s.1
						@input.setSelectionRange s.2, s.3
					else
						# callback (value replacement?)
						if @onChange and v != @value
							v = @onChange @, v
						# save and continue typing..
						s.1 = @value = v
						s.2 = @input.selectionStart
						s.3 = @input.selectionEnd
						return true
				else
					# empty,
					# restore the default
					@set s.0
					@input.select!
				# dont do the default
				e.preventDefault!
				e.stopPropagation!
				return false
			# }}}
			@inputKey = (e) !~> # {{{
				# check
				if @locked
					return
				# operate
				if e.keyCode == 13
					# Enter {{{
					# check
					if not @onSubmit
						return
					# callback
					@onSubmit @, e.ctrlKey
					# }}}
				else if e.keyCode in [38 40]
					# Up, Down {{{
					# check
					if not @onScroll
						return
					# scroll
					if @onScroll @, (e.keyCode == 38)
						@input.select!
					# }}}
				else
					return
				# fulfil the event
				e.preventDefault!
				e.stopPropagation!
			# }}}
			@inputWheel = (e) !~> # {{{
				# check
				if @locked or not @onScroll
					return false
				# fulfil the event
				e.preventDefault!
				e.stopPropagation!
				# callback
				@onScroll @, (e.deltaY < 0)
				# select text
				@select! if @focused
			# }}}
			@onLabel = (e) !~> # {{{
				# check
				if @locked or not @focused or not @onSubmit
					return
				# fulfil the event
				e.preventDefault!
				e.stopPropagation!
				# check current against default
				if @value != @state.0
					# restore and submit
					@set @state.0
					@input.select!
					@onSubmit @, true
			# }}}
		###
		InputNum.prototype =
			init: (label, v) !-> # {{{
				@label.textContent = label
				@set v
				@state.0 = v
			# }}}
			attach: !-> # {{{
				###
				@box.addEventListener 'pointerenter', @hover
				@box.addEventListener 'pointerleave', @unhover
				@box.addEventListener 'wheel', @inputWheel
				###
				@input.addEventListener 'focusin',  @focus
				@input.addEventListener 'focusout', @unfocus
				@input.addEventListener 'input', @inputChange, true
				@input.addEventListener 'keydown', @inputKey, true
				###
				@label.addEventListener 'pointerdown', @labelClick, true
			# }}}
			detach: !-> # {{{
				# done
			# }}}
			set: (v) !-> # {{{
				s = @state
				s.1 = @input.value = @value = '' + v
				s.2 = 0
				s.3 = s.1.length
			# }}}
			lock: (flag) !-> # {{{
				# check
				if flag == @locked
					return
				# operate
				@locked = flag
				@input.readOnly = flag
				@input.value = if flag
					then ''
					else @value
				@box.classList.toggle 'locked', flag
			# }}}
			select: !-> # {{{
				s   = @state
				s.2 = 0
				s.3 = @value.length
				###
				@input.select!
			# }}}
		# }}}
		TextInputs = (block, box) !-> # {{{
			# base
			@block = block
			@box   = box
			# controls
			@n0    = n0 = new InputNum 0, box.children.0
			@svg   = box.children.1
			@rst   = querySelectorChild @svg, '.X'
			@n1    = n1 = new InputNum 1, box.children.2
			# state
			@changed = 0
			@hovered = false
			@focused = false
			@locked  = true
			# handlers
			@onFocus = null
			n0.onHover = n1.onHover = (o) !~> # {{{
				# set
				@box.classList.toggle 'h'+o.id, o.hovered
				# callback
				if not @block.focused
					@block.onAutofocus o.input
			# }}}
			n0.onFocus = n1.onFocus = (o) !~> # {{{
				# set
				v = o.focused
				@box.classList.toggle 'f'+o.id, v
				if @focused = v
					# select current
					o.select!
				else
					# checkout and submit
					@check o.id
					if @changed
						@changed = 0
						@block.submit!
				# callback
				o @ if o = @onFocus
			# }}}
			n0.onSubmit = n1.onSubmit = (o, strict) !~> # {{{
				# check
				if not @check o.id and strict
					o.select!
					return
				# submit
				if @changed
					@changed = 0
					@block.submit!
				# swap focus
				if not strict
					o = if o == @n1
						then @n0
						else @n1
					o.input.focus!
			# }}}
			n0.onScroll = n1.onScroll = (o, direction) !~> # {{{
				# prepare
				c = @block.current
				d = c.4 - c.3
				# determine step and 0-alignment
				# {{{
				if d > 200
					# 1% of the range
					a = d / 100 .|. 0
					b = '' + a
					# check alignment possible
					if (e = b.length) > 1
						# determine aligned step
						e = if e > 2
							then e - 2
							else 1
						b = (b.slice 0, -e) + ('0'.repeat e)
						a = +b
					else
						e = 0
				else
					# simpliest
					e = 0
					a = 1
				# }}}
				# determine current
				b = +o.value
				# increment
				if direction
					b += a
				else
					b -= a
				# align
				a = if e
					then +(((''+b).slice 0, -e) + ('0'.repeat e))
					else b
				# determine new range
				if o.id
					# right
					b = a
					a = +@n0.value
					if b >= c.4
						b = c.4
					else if b <= a
						b = a + 1
				else
					# left
					b = +@n1.value
					if a <= c.3
						a = c.3
					else if a >= b
						a = b - 1
				# apply and submit
				@set a, b
				@check o.id
				if @changed
					@changed = 0
					@block.submit!
				# done
				return true
			# }}}
			@hover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if not @locked and not @hovered
					@hovered = true
					@box.classList.add 'hovered'
					# callback
					if not @block.focused
						@block.onAutofocus!
			# }}}
			@unhover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if @hovered
					@hovered = false
					@box.classList.remove 'hovered'
			# }}}
			@reset = (e) !~> # {{{
				# check
				if not @locked
					# fulfil the event
					if e
						e.preventDefault!
						e.stopPropagation!
					# check
					if (c = @block.current).0
						# reset and submit
						c.0 = false
						c.1 = c.2 = -1
						@set c.3, c.4
						@changed = 0
						@block.submit!
			# }}}
		###
		TextInputs.prototype =
			init: (locale) !-> # {{{
				c = @block.current
				@n0.init locale.min, c.3
				@n1.init locale.max, c.4
			# }}}
			attach: !-> # {{{
				###
				@box.addEventListener 'pointerenter', @hover
				@box.addEventListener 'pointerleave', @unhover
				###
				@n0.attach!
				@n1.attach!
				###
				#@svg.addEventListener 'wheel', @onScroll
				@rst.addEventListener 'click', @reset if @rst
			# }}}
			detach: !-> # {{{
				# done
			# }}}
			set: (min, max) !-> # {{{
				@n0.set min
				@n1.set max
			# }}}
			check: (id) -> # {{{
				# get the values
				a = +@n0.value
				b = +@n1.value
				c = @block.current
				d = true # input is correct
				# check range numbers
				if a > b
					# swap values (if user mixed-up min>max)
					d = a
					a = b
					b = d
					d = false
				else if a == b
					# push inactive border
					if id
						if (a = c.3) == b
							++b
					else
						if (b = c.4) == a
							--a
					d = false
				# check out of the valid range
				if a >= c.4 or a < c.3
					d = false
					a = if c.0
						then c.1
						else c.3
				else if a < c.3
					d = false
					a = c.3
				if b <= c.3
					d = false
					b = if c.0
						then c.2
						else c.4
				else if b > c.4
					d = false
					b = c.4
				# fix incorrect input
				@set a, b if not d
				# determine current state
				if a == c.3 and b == c.4
					# inactive
					# set pending change
					++@changed if c.0
					# reset
					c.0 = false
					c.1 = c.2 = -1
				else
					# active
					# set pending change
					++@changed if not c.0 or (a != c.1 or b != c.2)
					# set filter
					c.0 = true
					c.1 = a
					c.2 = b
				# done
				return d
			# }}}
			lock: (flag) !-> # {{{
				# check
				if @locked == flag
					return
				# opearate
				@locked = flag
				@n0.lock flag
				@n1.lock flag
			# }}}
			focus: !-> # {{{
				@n0.input.focus!
			# }}}
		# }}}
		Block = (state, root, index) !-> # {{{
			# base
			@state   = state
			@root    = root
			@index   = index
			@rootBox = box = root.firstChild
			@config  = JSON.parse root.dataset.cfg
			# controls
			# {{{
			# determine UI mode
			mode = if box.classList.contains 'text'
				then 0
				else 1
			@inputs  = I = new TextInputs @, box
			@section = S = sMainSection root.parentNode.parentNode.parentNode
			# }}}
			# state
			@locked  = -1
			@mode    = mode
			@focused = false
			@current = [false,-1,-1,-1,-1]
			@pending = false
			# handlers
			@onAutofocus = S.onAutofocus
			S.onChange = (o) !~> # {{{
				# check
				if not @config.sectionSwitch or o.parent
					return
				# operate
				c = @current
				if o.opened
					# enable
					if not c.0 and (~c.1 or ~c.2)
						c.0 = true
						@submit!
				else
					# disable
					if c.0
						c.0 = false
						@submit!
			# }}}
			I.onFocus = S.onFocus = do ~> # {{{
				p = null
				return (o) ~>>
					# check
					if p and p.pending
						p.resolve false
					# set
					if o.focused
						@focused = @section.focused = true
						@section.root.classList.add 'f'
					else if await (p := newDelay 60)
						@focused = @section.focused = false
						@section.root.classList.remove 'f'
					# done
					return true
			# }}}
			S.onRefocus = (i1, i2, direction) ~> # {{{
				# check
				if i2
					if direction
						# last
						@inputs.n1.input.focus!
					else
						# first
						@inputs.n0.input.focus!
					# done
					return true
				# done
				return false
			# }}}
		###
		Block.prototype =
			group: 'price'
			level: 2
			init: (cfg) ->> # {{{
				if not (await @section.init!)
					return false
				# copy current
				@current[0 to 4] = @state.data
				# initialize controls
				@inputs.init cfg.locale.price
				@inputs.attach!
				# done
				return true
			# }}}
			lock: (level) ->> # {{{
				###
				if level != @locked
					console.log 'price-filter.lock', @locked, level
					if not level
						# unlock
						@section.lock 0
						@rootBox.classList.add 'v'
						@inputs.lock 0
						###
					else if ~level
						# full
						true
						###
					else if level == 1
						# loader
						@inputs.lock 1
						@rootBox.classList.remove 'v'
						@section.lock 1
						###
					else
						# partial
						@inputs.lock 1
						###
				###
				@locked = level
				return true
			# }}}
			notify: -> # {{{
				return true
			# }}}
			refresh: !-> # {{{
				# prepare
				a = @state.data # source
				b = @current    # destination
				# sync status changed
				if a.0 != b.0
					@rootBox.classList.toggle 'active', a.0
					@section.setClass 'active', a.0
				# check current changed
				if a.0 != b.0 or a.1 != b.1 or a.2 != b.2
					@inputs.set a.1, a.2
				# sync
				b[0 to 4] = a
			# }}}
			submit: do -> # {{{
				p = newDelay 0
				return ->>
					# reset
					p.cancel!
					# prepare
					a = @current    # source
					b = @state.data # destination
					# check status changed
					if a.0 != b.0
						@rootBox.classList.toggle 'active', a.0
						@section.setClass 'active', a.0
					# sync
					b[0 to 2] = a
					@pending = true
					# throttle
					if await (p := newDelay 400)
						# notify
						@pending = false
						@state.change!
					# done
					return true
			# }}}
		# }}}
		return Block
	# }}}
	mPaginator = do -> # {{{
		Control = (block) !-> # {{{
			# data
			# {{{
			@block     = block
			@lock      = null
			@lockType  = 0
			@rootCS    = getComputedStyle block.root
			@rootBoxCS = getComputedStyle block.rootBox
			@rootPads  = [0, 0, 0, 0]
			@baseSz    = [ # initial sizes
				0, 0, # 0/1: root-x, root-y
				0,    #   2: range-x
				0, 0  # 3/4: current-page-x, page-x
			]
			@currentSz = [ # calculated sizes
				0, 0, # 0/1: root-x, root-y
				0, 0, # 2/3: current-page-x, page-x
				0     #   4: optimal-page-x
			]
			@observer = null # resize observer
			@dragbox   = []
			@maxSpeed  = 10
			@brake     = 15
			@observer  = null # resize observer
			# }}}
			# handlers
			@keyDown = (e) !~> # {{{
				# check requirements
				if @lock or @block.locked or \
				   not @block.range.mode
					###
					return
				# check key-code
				switch e.code
				case <[ArrowLeft ArrowDown]>
					# fast-backward
					# get node
					a = @block.gotos.btnPN.0
					# start
					@lockType = 1
					@fast null, a, false
				case <[ArrowRight ArrowUp]>
					# fast-forward
					# get node
					a = @block.gotos.btnPN.1
					# start
					@lockType = 1
					@fast null, a, true
				default
					return
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
			# }}}
			@keyUp = (e) !~> # {{{
				if @lock and @lockType == 1
					# fulfil event
					e.preventDefault!
					e.stopPropagation!
					# unlock
					@lock.resolve!
			# }}}
			@setFocus = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# operate
				@block.focus!
			# }}}
			@hover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check block state
				if not @block.locked and @block.range.mode and \
				   (e = e.currentTarget)
					###
					e.classList.add 'hovered'
			# }}}
			@unhover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# operate
				if e = e.currentTarget
					e.classList.remove 'hovered'
			# }}}
			@wheel = (e) !~> # {{{
				# check
				if @lock or @block.locked or not @block.range.mode
					return
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# prepare
				a = state.data.0
				if (b = state.data.1 - 1) == 0
					return
				# determine new index
				a = a + 1*(Math.sign e.deltaY)
				if a > b
					a = 0
				else if a < 0
					a = b
				# update state
				state.data.0 = a
				state.master.resolve state
				for b in blocks
					b.refresh!
				# done
				@block.focus!
			# }}}
			@fastForward = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check requirements
				if @block.range.mode == 2 and \
				   not @lock and not @block.locked and \
				   e.isPrimary and not e.button
					###
					@lockType = 0
					@fast e.pointerId, e.currentTarget, true
			# }}}
			@fastBackward = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check requirements
				if @block.range.mode == 2 and \
				   not @lock and not @block.locked and \
				   e.isPrimary and not e.button
					###
					@lockType = 0
					@fast e.pointerId, e.currentTarget, false
			# }}}
			@fastStop = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# unlock
				if @lock and @lockType == 0
					@lock.resolve!
			# }}}
			@dragStart = (e) ~>> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check requirements
				if @lock or @block.locked or @block.range.mode != 2 or \
				   not e.isPrimary or e.button or \
				   typeof e.offsetX != 'number'
					###
					return true
				# prepare
				B = @block
				R = B.range
				# lock
				@lock = newPromise!
				@lockType = 2
				@block.focus!
				# cooldown
				await Promise.race [(newDelay 200), @lock]
				if not @lock.pending
					# prevent false startup
					@lock = null
					return true
				# set capture
				node = @block.range.box
				node.classList.add 'active', 'drag'
				if not node.hasPointerCapture e.pointerId
					node.setPointerCapture e.pointerId
				# PIXEL PERFECT:
				# calculate dragbox parameters
				# {{{
				# determine first-last page counts (excluding current)
				if (c = R.pages.length) > 1
					b = R.index
					c = c - R.index - 1
				else
					b = 0
				if R.first
					b += 1
					c += 1
				# determine page-button sizes
				if (a = @currentSz).4
					# enlarged mode (optimal current)
					d = a = a.4
				else if a.3
					# reduced mode (current)
					d = a.3 # page-x
					a = a.2 # current-page-x
				else
					# default (base)
					d = @baseSz.4
					a = @baseSz.3
				# calculate offsets
				# first
				e = @dragbox
				e.0 = a + b * d     # total space
				e.1 = e.0 / (b + 1) # average size of the button
				e.0 = e.0 - e.1     # size of the drag area
				# last
				e.4 = a + c * d
				e.3 = e.4 / (c + 1)
				e.4 = e.4 - e.3
				# middle
				e.2 = parseFloat R.cs.getPropertyValue 'width'
				e.2 = e.2 - e.0 - e.4 # - e.1 - e.3
				# determine first/last jump runways
				if not @currentSz.4
					# for proper drag granularity in the middle area,
					# determine penetration quantifier
					a = e.2 / (state.data.1 - (b + c))
					d = e.1 / 2 # limit
					if a < d
						e.1 = d + a
						e.3 = e.3 / 2 + a
				# tune middle
				e.2 = e.2 - e.1 - e.3
				# page counts in the areas
				e.5 = b
				e.7 = c
				e.6 = state.data.1 - e.5 - e.7 - 2 # >=0
				# }}}
				# wait released
				a = state.data.0
				@lockType = 3
				await @lock
				# release capture
				if node.hasPointerCapture e.pointerId
					node.releasePointerCapture e.pointerId
				node.classList.remove 'active', 'drag'
				# update global state
				if not @block.locked and a != state.data.0
					state.master.resolve state
					for a in blocks when a != @block
						a.refresh!
				# done
				@lock.resolve!
				@lock = null
				return true
			# }}}
			@drag = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check
				if not @lock or @lockType != 3
					return
				# prepare
				d = @dragbox # 0-1-2-3-4 | 5-6-7
				c = state.data.1
				# calculate page index
				if (b = e.offsetX) <= 0
					# out of first
					a = 0
				else if b <= d.0
					# first
					a = (b*d.5 / d.0) .|. 0
				else if (b -= d.0) <= d.1
					# first-jump
					a = d.5
				else if (b -= d.1) <= d.2
					# middle
					# {{{
					# determine relative offset and
					# make value discrete
					b = (b*d.6 / d.2) .|. 0
					# add previous counts
					# to determine exact page index
					a = d.5 + 1 + b
					# }}}
				else if (b -= d.2) <= d.3
					# last-jump
					a = d.5 + d.6 + 1
				else if (b -= d.3) <= d.4
					# last
					a = d.5 + d.6 + 2 + (b*d.7 / d.4) .|. 0
				else
					# out of last
					a = c - 1
				# check same
				if state.data.0 == a
					return
				# update local state
				state.data.0 = a
				@block.refresh!
			# }}}
			@dragStop = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# unlock
				if @lock and @lockType in [2 3]
					@lock.resolve!
			# }}}
			@goto = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check
				if @lock or @block.locked or not @block.range.mode
					return
				# prepare
				a = e.currentTarget.parentNode.className
				b = state.data.0
				c = state.data.1 - 1
				# determine new index
				if (a.indexOf 'first') != -1
					a = 0
				else if (a.indexOf 'last') != -1
					a = c
				else if (a.indexOf 'prev') != -1
					if (a = b - 1) < 0
						a = c
				else if (a.indexOf 'next') != -1
					if (a = b + 1) > c
						a = 0
				# check same
				if a == b
					return
				# update state
				state.data.0 = a
				state.master.resolve state
				blocks.forEach (b) -> b.refresh!
				# done
				@block.focus!
			# }}}
			@rangeGoto = do ~> # {{{
				# get range
				if not (R = @block.range)
					return null
				# create page goto handlers
				a = []
				b = -1
				c = R.pages.length
				while ++b < c
					a[b] = @rangeGotoFunc (b - R.index)
				# done
				return a
			# }}}
			@resize = (e) !~> # {{{
				# prepare
				R = @block.range
				debugger
				###
				# dynamic axis
				# check operation mode and
				# determine current
				if e
					# observed
					# get current
					w = e.0.contentRect.width
				else
					# forced
					# determine current
					a = @rootPads
					a = a.1 + a.3
					if (w = @block.root.clientWidth - a) < 0
						w = 0
					# determine base
					@baseSz.0 = parseFloat (@rootBoxCS.getPropertyValue 'width')
					@baseSz.2 = parseFloat (R.cs.getPropertyValue 'width')
				# update
				@currentSz.0 = w
				###
				# static axis
				# determine deviation from the base
				e = w / @baseSz.0
				# calculate current size
				a = @baseSz.1
				b = @currentSz.1
				@currentSz.1 = c = if e > 0.999
					then 0
					else e * a
				# update style only if required
				# also, to avoid layout reflows (by accessing min-width),
				# re-calculate page-button sizes using base multiplier
				if b and not c
					@block.root.style.removeProperty '--height'
					@currentSz.2 = 0
					@currentSz.3 = 0
				else if c and (Math.abs (c - b)) > 0.1
					@block.root.style.setProperty '--height', c+'px'
					@currentSz.2 = e * @baseSz.3
					@currentSz.3 = e * @baseSz.4
				# check flexy dualgap mode and
				# determine page-button size
				if @block.flexy and @block.range.mode == 2
					###
					# the drag problem:
					# when paginator has plenty of space at dynamic axis,
					# the middle area (gaps) may fit all pages,
					# especially when the count is low,
					# which makes button's drag area bigger
					# than the button size and it makes drag "jump",
					# which looks and feels unnatural.
					# that's why size of page-buttons must be controlled.
					###
					# determine current range size
					# (it's proportional, because it may be
					#  modified to preserve aspect ratio)
					a = @baseSz.0 - @baseSz.2
					a = if e > 0.999
						then w - a
						else w - e * a
					# determine current, optimal page-button size
					if (c = @currentSz).2
						b = if c.3
							then (c.3 + c.2) / 2
							else c.2
						c = c.4
					else
						b = @baseSz.3
						c = c.4
					# update value
					if (d = a / @block.state.data.1) <= b
						d = 0
					@currentSz.4 = d
					# update style only if required
					if c and not d
						@block.range.box.style.removeProperty '--page-size'
					else if d and (Math.abs (d - b)) > 0.1
						@block.range.box.style.setProperty '--page-size', d+'px'
				# done
			# }}}
		###
		Control.prototype = {
			init: !-> # {{{
				# prepare
				R = @block.range
				# determine container paddings
				a = [
					'padding-top'
					'padding-right'
					'padding-bottom'
					'padding-left'
				]
				b = -1
				while ++b < a.length
					@rootPads[b] = parseInt (@rootCS.getPropertyValue a[b])
				# determine container sizes
				@baseSz.0 = 0
				@baseSz.1 = parseInt (@rootCS.getPropertyValue '--height')
				@baseSz.2 = parseFloat (R.cs.getPropertyValue 'width')
				# determine page sizes
				a = getComputedStyle R.pages.0
				@baseSz.3 = parseFloat (a.getPropertyValue 'min-width')
				a = 1 + @block.config.index
				a = getComputedStyle R.pages[a]
				@baseSz.4 = parseFloat (a.getPropertyValue 'min-width')
			# }}}
			attach: !-> # {{{
				# prepare
				B = @block
				R = B.range
				@init!
				# operate
				# set keyboard controls
				B.root.addEventListener 'keydown', @keyDown, true
				B.root.addEventListener 'keyup', @keyUp, true
				# set mouse controls
				B.root.addEventListener 'click', @setFocus
				B.rootBox.addEventListener 'wheel', @wheel, true
				B.rootBox.addEventListener 'pointerenter', @hover
				B.rootBox.addEventListener 'pointerleave', @unhover
				# set range
				# first-last
				a = R.pages[0].firstChild
				a.addEventListener 'click', @goto
				a = R.pages.length - 1
				a = R.pages[a].firstChild
				a.addEventListener 'click', @goto
				# gotos
				for a,b in R.pages
					a.firstChild.addEventListener 'click', @rangeGoto[b]
				# drag (current page & range box)
				a = R.pages[R.index].firstChild
				a.addEventListener 'pointerdown', @dragStart
				B.range.box.addEventListener 'pointermove', @drag
				B.range.box.addEventListener 'pointerup', @dragStop
				# set observer
				@observer = a = new ResizeObserver @resize
				a.observe B.root
			# }}}
			detach: !-> # {{{
				if @observer
					@observer.disconnect!
					@observer = null
			# }}}
			rangeGotoFunc: (i) -> (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check
				if @lock or @block.locked or not @block.range.mode
					return
				# determine page index
				if @block.range.mode == 2
					a = state.data.0 + i
				else
					a = if @block.range.first
						then 1 + i + @block.range.index
						else i + @block.range.index
				# check
				if a == state.data.0
					return
				# update state
				state.data.0 = a
				state.master.resolve state
				blocks.forEach (b) -> b.refresh!
				# done
				@block.focus!
			# }}}
			fast: (id, node, forward) ->> # {{{
				# get final index
				if (a = state.data.1) == 1
					return false
				# lock and suspend
				# to prevent false startups
				@lock = newPromise!
				await Promise.race [(newDelay 200), @lock]
				# calculate initial values
				if forward
					inc = 1
					beg = 0
					end = a
				else
					inc = -1
					beg = a - 1
					end = -1
				a = state.data.0
				b = inc
				c = @brake
				# check unlocked (false startup)
				if not @lock.pending
					# check interface type
					if not id
						# no pointer means keyboard,
						# it should move index at least once
						if (a = state.data.0 + b) == end
							a = beg
						# update global state
						state.data.0 = a
						state.master.resolve state
						for b in blocks
							b.refresh!
					# release lock
					@lock = null
					# complete
					@block.focus!
					return true
				# set capture
				@block.focus!
				@block.range.box.classList.add 'active'
				node.parentNode.classList.add 'active'
				if id != null and not node.hasPointerCapture id
					node.setPointerCapture id
				# start
				while @lock.pending
					# increment
					if (a = a + b) == end
						# end reached, re-start
						a = beg
						b = inc
						c = @brake
					# update local state
					state.data.0 = a
					await @refresh!
					# determine distance left
					if (d = end - inc - inc*a) <= @brake
						# throttle
						b = inc
						d = 1000 / (1 + d)
						await Promise.race [(newDelay d), @lock]
					else if inc*b < @maxSpeed and --c == 0
						# accelerate
						b = b + inc
						c = @brake
				# release capture
				if id != null and node.hasPointerCapture id
					node.releasePointerCapture id if id != null
				node.parentNode.classList.remove 'active'
				@block.range.box.classList.remove 'active'
				# update global state
				if not @block.locked
					state.master.resolve state
					for b in blocks when b != @block
						b.refresh!
				# release lock and complete
				@lock.resolve!
				await newDelay 60 # omit click event
				@lock = null
				return true
			# }}}
			refresh: -> # {{{
				# prepare
				a = newPromise!
				b = @block
				# compose render sequence
				requestAnimationFrame !->
					b.refresh!
					b.focus! if b.range.mode == 2
					requestAnimationFrame !->
						a.resolve!
				# done
				return a
			# }}}
		}
		# }}}
		PageGoto = (block) !-> # {{{
			###
			@block = block
			@boxFL = a = querySelectorChildren block.rootBox, '.goto.a'
			@boxPN = b = querySelectorChildren block.rootBox, '.goto.b'
			@btnFL = queryFirstChildren a
			@btnPN = queryFirstChildren b
			@sepFL = querySelectorChildren block.rootBox, '.sep'
			###
		###
		PageGoto.prototype =
			attach: !-> # {{{
				# prepare
				E = @block.ctrl
				# first-last
				if a = @btnFL
					a.0.addEventListener 'click', E.goto
					a.1.addEventListener 'click', E.goto
				# prev-next
				if a = @btnPN
					a.0.addEventListener 'pointerdown', E.fastBackward
					a.0.addEventListener 'pointerup', E.fastStop
					a.0.addEventListener 'click', E.goto
					a.1.addEventListener 'pointerdown', E.fastForward
					a.1.addEventListener 'pointerup', E.fastStop
					a.1.addEventListener 'click', E.goto
			# }}}
			detach: !-> # {{{
				true
			# }}}
		# }}}
		PageRange = (block) !-> # {{{
			# controls
			@block = block
			@box   = box = querySelectorChild block.rootBox, '.range'
			@cs    = getComputedStyle box
			@pages = pages = querySelectorChildren box, '.page'
			@gaps  = gaps = querySelectorChildren box, '.gap'
			# constants
			@index = i = 1 + block.config.index # range "center"
			@size  = pages.length - 2 # rendered range size
			# state
			@mode    = 0  # current mode: 0=empty, 1=dualgap, 2=nogap
			@current = -1 # current page index
			@count   = 0  # current count of page buttons
			@nPages  = pages.slice!fill 0
			@nGaps   = gaps.slice!fill 0
			@pFirst  = -1 # first page index
			@pLast   = -1 # last page index
		###
		PageRange.prototype =
			set: (v) !-> # {{{
				# prepare defaults
				pages = @pages.slice!fill 0
				gaps  = [0,0]
				first = -1
				last  = -1
				# determine current state
				if v.1 == 0
					# empty
					# {{{
					# no range/current, gap only
					mode    = 0
					current = -1
					count   = 0
					gaps.0  = 100
					# }}}
				else if v.1 <= pages.length
					# nogap (pages only)
					# {{{
					mode    = 1
					current = v.0
					count   = pages.length # justify
					# set page numbers
					a = -1
					b = 0
					while ++a < v.1
						pages[a] = ++b
					# set edge pages
					first = 0
					last  = a - 1
					# }}}
				else
					# dualgap
					# {{{
					mode    = 2
					current = @index
					count   = pages.length
					# determine left side parameters
					if (a = @index - v.0 - 1) < 0
						# set first page number and
						# determine gap size
						pages.0 = 1
						first   = 0
						gaps.0  = -a - 1
						# positive gap, full range
						b = -a
						a = 0
					else
						# negative gap, reduced range
						first = a + 1
						b = -a
					# set left range numbers
					while ++a < @index
						pages[a] = a + b
					# set center
					pages[current] = v.0 + 1
					# determine right side parameters
					b = v.0 + 1
					c = count - 1
					if (a = v.1 - b - @size + @index - 1) >= 0
						# full range,
						# set last page number and gap size
						last     = c
						pages[c] = v.1
						gaps.1   = a
					else
						# reduced range
						last = c + a
						c    = last + 1
					# set right range numbers
					a = @index
					while ++a < c
						pages[a] = ++b
					# determine relative gap sizes
					a = 100 * gaps.0 / (gaps.0 + gaps.1)
					# fix edge cases
					if a > 0 and a < 1
						a = 1
					else if a > 99 and a < 100
						a = 99
					else
						a = Math.round a
					# done
					gaps.0 = a
					gaps.1 = 100 - a
					# }}}
				###
				# apply changes
				# range mode
				if mode != @mode
					a = @box.classList
					if not @mode
						a.add 'v'
					if mode == 1
						a.add 'nogap'
					else if not mode
						a.remove 'v'
					if @mode == 1
						a.remove 'nogap'
					@mode = mode
				# range capacity (page buttons count)
				if count != @count
					@box.style.setProperty '--count', count
					@count = count
					# re-calculate block size
					@block.resize!
				# pages
				a = @nPages
				for c,b in pages when a[b] != c
					if not a[b]
						@pages[b].classList.add 'v'
					if not c
						@pages[b].classList.remove 'v'
					else
						@pages[b].firstChild.textContent = if ~c
							then c
							else ''
					a[b] = c
				# gaps
				a = @nGaps
				for c,b in gaps when a[b] != c
					if not a[b]
						@gaps[b].classList.add 'v'
					if not c
						@gaps[b].classList.remove 'v'
					@gaps[b].style.flexGrow = a[b] = c
				# current page
				if @current != current
					if ~@current
						@pages[@current].classList.remove 'x'
					if ~current
						@pages[current].classList.add 'x'
					@current = current
				# range edges
				if (a = @pFirst) != first
					if ~a
						@pages[a].classList.remove 'F'
					if ~first
						@pages[first].classList.add 'F'
					@pFirst = first
				if (a = @pLast) != last
					if ~a
						@pages[a].classList.remove 'L'
					if ~last
						@pages[last].classList.add 'L'
					@pLast = last
				# done
			# }}}
		# }}}
		Block = (state, root) !-> # {{{
			# base
			@state   = state
			@root    = root
			@rootBox = rootBox = root.firstChild
			@config  = JSON.parse rootBox.dataset.cfg
			# controls
			@range   = new PageRange @
			@gotos   = new PageGoto @
			@control = new Control @
			# state
			@locked  = -1
			@current = [-1,-1] # page index, count
			# handlers
			# ...
		###
		Block.prototype =
			group: 'page'
			level: 1
			init: (cfg) -> # {{{
				# set classes
				a = @rootBox.classList
				if @config.range == 2
					a.add 'flexy'
				if not @gotos.sepFL
					a.add 'nosep'
				###
				@refresh!
				@control.attach!
				return true
			# }}}
			lock: (level) ->> # {{{
				###
				if level != @locked
					if not level
						# unlock
						@rootBox.classList.add 'v'
					else
						# deactivate
						if a = @control.lock
							await a.spin!
						# lock
						@rootBox.classList.remove 'v'
						if ~(a = @range.current)
							@range.pages[a].classList.remove 'x'
							@range.current = -1
						###
				###
				@locked = level
				return true
			# }}}
			notify: -> # {{{
				# check active
				if (a = @control.lock) and a.pending
					return false
				# done
				return true
			# }}}
			refresh: !-> # {{{
				# prepare
				a = @current
				b = @state.data
				# check
				if a.0 == b.0 and a.1 == b.1
					return
				# set
				@range.set b if @range
				# sync
				a[0 to 1] = b
			# }}}
			resize: !-> # {{{
				@root.classList.remove 'v'
				@control.resize!
				@root.classList.add 'v'
			# }}}
			focus: !-> # {{{
				# set focus to the current node
				if not @locked and \
				   @range and (a = @range.current) and \
				   document.activeElement != a
					###
					a.focus!
			# }}}
		# }}}
		return Block
	# }}}
	mOrderer = do -> # {{{
		Control = (block) !-> # {{{
			# create object shape
			# data
			@block   = block
			@hovered = 0
			@focused = false
			# bound handlers
			@hover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if not @block.locked and not @hovered
					@hovered = 1
					@block.rootBox.classList.add 'hovered'
			# }}}
			@unhover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if @hovered == 1
					@hovered = 0
					@block.rootBox.classList.remove 'hovered'
			# }}}
			@switchVariant = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# operate
				B = @block
				D = state.data
				if not B.locked and (a = B.current.1) > 0
					# set variant
					state.data.1 = a = if a == 1
						then 2
						else 1
					# update DOM
					b = B.select.selectedIndex
					b = B.select.options[b]
					b.value = a
					# move focus
					B.select.focus!
					# update state
					state.master.resolve state
					for a in blocks
						a.refresh!
			# }}}
			@switchFocusIn = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# operate
				if not @block.locked and @hovered != 2
					@hovered = 2
					@block.rootBox.classList.add 'hovered'
			# }}}
			@switchFocusOut = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# operate
				if not @block.locked and @hovered == 2
					@hovered = 0
					@block.rootBox.classList.remove 'hovered'
			# }}}
			@selected = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# operate
				B = @block
				if not B.locked
					# set new index and variant
					a = B.select.selectedIndex
					state.data.0 = B.keys[a]
					state.data.1 = +B.select.options[a].value
					# update state
					state.master.resolve state
					for a in blocks
						a.refresh!
			# }}}
		###
		Control.prototype = {
			attach: !-> # {{{
				B = @block
				B.rootBox.addEventListener 'pointerenter', @hover
				B.rootBox.addEventListener 'pointerleave', @unhover
				B.switch.forEach (a) !~>
					a.addEventListener 'click', @switchVariant
					a.addEventListener 'focusin', @switchFocusIn
					a.addEventListener 'focusout', @switchFocusOut
				B.select.addEventListener 'input', @selected
			# }}}
			detach: !-> # {{{
				true
			# }}}
		}
		# }}}
		Block = (state, root) !-> # {{{
			# base
			@state   = state
			@root    = root
			@rootBox = root.firstChild
			# controls
			@variant = a = [...(root.querySelectorAll '.variant')]
			@switch  = a.map (a) -> a.firstChild
			@select  = root.querySelector 'select'
			# state
			@locked  = -1
			@current = ['',-1]
			@options = null
			@keys    = null
			@ctrl    = new Control @
			# handlers
			@onResize = null
		###
		Block.prototype =
			group: 'order'
			level: 1
			init: (cfg) -> # {{{
				# initialize state
				s = @state
				@options = o = cfg.locale.order
				@keys    = k = s.config.orderOptions or (Object.getOwnPropertyNames o)
				# create select options
				s = @select
				for a in k
					# create
					b = document.createElement 'option'
					b.textContent = o[a].0
					b.value = o[a].1
					# add
					s.appendChild b
				# complete
				@refresh!
				@ctrl.attach!
				return true
			# }}}
			lock: (level) ->> # {{{
				###
				if level != @locked
					if not level
						# unlock
						true
						###
					else
						# lock
						true
						###
				###
				@locked = level
				return true
			# }}}
			notify: -> # {{{
				return true
			# }}}
			refresh: !-> # {{{
				# get data
				a = @state.data
				b = @current
				# sync tag
				if a.0 != b.0
					# set controls
					if (c = @keys.indexOf a.0) != @select.selectedIndex
						@select.selectedIndex = c
					if (not a.1 and b.1) or (a.1 and not b.1)
						c = !a.1
						@switch.forEach (d) !->
							d.disabled = c
					# store
					b.0 = a.0
				# sync variant
				if a.1 != b.1
					# set controls
					if b.1 >= 0
						c = ('abc')[b.1]
						@variant.forEach (d) !->
							d.classList.remove c
					if a.1 >= 0
						c = ('abc')[a.1]
						@variant.forEach (d) !->
							d.classList.add c
					# store
					b.1 = a.1
			# }}}
		# }}}
		return Block
	# }}}
	# leader
	M = # masters map [constructor, selector] {{{
		[mProducts,       '.sm-blocks.products']
		[mCategoryFilter, '.sm-blocks.category-filter']
		[mPriceFilter,    '.sm-blocks.price-filter']
		[mPaginator,      '.sm-blocks.paginator']
		[mOrderer,        '.sm-blocks.orderer']
	# }}}
	SUPERVISOR = do -> # {{{
		# controllers
		newLoader  = do -> # {{{
			State = !-> # {{{
				@config   = {}   # shared store
				@records  = []   # currently loaded records
				@total    = 0    # number of records
				@page     = null # [current, total pages]
				@category = null # [[id1..N][..][..]]
				@price    = null # [isEnabled, a, b, aMin, bMax]
				@order    = null # [tag, variant]
			# }}}
			RequestData = !-> # {{{
				@func     = 'config'
				@lang     = ''
				@category = []
				@price    = null
				@order    = null
				@offset   = 0
				@limit    = 0
			# }}}
			Loader = (s) !-> # {{{
				@super = s     # s-supervisor
				@dirty = true  # resolved-in-process flag
				@level = 0     # current priority (lowest for the first)
				@lock  = null  # current load promise
				@fetch = null  # request promise
				@state = null
				@data  = null
			###
			Loader.prototype =
				name: 'loader'
				init: ->> # {{{
					# prepare
					T = window.performance.now!
					S = new State!
					D = new RequestData!
					B = @super.blocks
					###
					# manage configuration
					# set local (low -> high)
					for a in B when a.configure
						a.configure D
						S.config <<< a.config
					# get remote
					if (cfg = await soFetch D) instanceof Error
						consoleError c.message
						return false
					###
					# initialize state
					# import server-side configuration
					for a of cfg when S.hasOwnProperty a
						S[a] = cfg[a]
					# link with request data
					for a of D when S.hasOwnProperty a
						D[a] = S[a]
					# determine records offset
					D.offset = S.page.0 * D.limit
					# switch in data mode
					D.func = 'data'
					###
					# initialize groups
					for a in @super.groups
						# shared
						a.state.config = S.config
						# individual
						if S.hasOwnProperty a.name
							a.state.data = S[a.name]
					###
					# initialize blocks
					# execute standard method
					a = []
					for b in B
						a[*] = if b.init
							then b.init cfg
							else true
					# wait for completion and iterate results
					c = []
					for a,b in (await Promise.all a)
						# check
						if not a
							consoleError 'Failed to initialize a block'
							return false
						# unlock
						c[*] = B[b].lock 0
					# gracefully await unlock completion
					await Promise.all c
					# set constructed & functional class
					for a in B
						a.root.classList.add 'v'
						a.rootBox.classList.add 'v'
					# done
					@state = S
					@data  = D
					T = (window.performance.now! - T) .|. 0
					consoleInfo 'loader initialized in '+T+'ms'
					return true
				# }}}
				finit: !-> # {{{
					# interrupt
					@lock.resolve! if @lock
					@fetch.cancel! if @fetch
					# restore defaults
					@dirty = false
					@level = 100
					# cleanup
					@lock = @fetch = @state = @data = null
				# }}}
				charge: -> # {{{
					# check
					if @dirty
						# lazy pull
						# to guard against excessive fetch requests,
						# resulted by fast, multiple user actions,
						# actions are throttled here:
						@lock  = p = newDelay 400
						@dirty = false
					else
						# charge the trigger
						# create custom promise
						r = null
						p = new Promise (resolve) !->
							r := resolve
						# initialize
						p.pending = true
						p.resolve = r = @set p, r
						# set promise and resolver
						@lock = p
						for a in @super.groups
							a.resolve = r
					# done
					return p
				# }}}
				set: (p, r) -> # {{{
					loader = @
					return ->
						# GROUP RESOLVER
						# prevent lower level change
						if @level < loader.level
							return false
						# prepare
						S = loader.state
						D = loader.data
						# rise priority level
						if @level > loader.level
							loader.level = @level
						# operate
						switch @name
						case 'category'
							# it's assumed that filter combinations
							# does not interset.. so, always
							# reset query offset & page index
							D.offset = S.page.0 = 0
						case 'price'
							# TODO: price range may limit the same
							# set of items (be ineffective),
							# which means that page index should not
							# reset for better optimization & integrity,
							# but for the sake of dev speed,
							# let's reset it for now..
							D.offset = S.page.0 = 0
						case 'page'
							# determine first record offset
							D.offset = S.page.0 * D.limit
						###
						# complete
						if p.pending
							# clean
							p.pending = false
							r!
						else if not @dirty
							# dirty
							@dirty = true
							@fetch.cancel! if @fetch
						# done
						return true
				# }}}
				reset: !-> # {{{
					if (a = @state.records).length
						# clear product cards in the reverse order
						#while --c >= 0
						#	gridList[c].cls!
						# cleanup
						a.length = 0
				# }}}
				operate: ->> # {{{
					###
					# wait for update
					if not (await @charge!)
						return true
					###
					# manage blocks (high -> low)
					B = @super.blocks
					a = B.length
					while ~--a
						if (b = B[a]).level < @level
							# lock lower levels (dont wait)
							if not b.locked
								b.lock 1, @level
						else
							# notify higher levels (allow restart)
							if not b.notify!
								return true
					# check for restart
					return true if @dirty
					###
					# execute fetcher
					R = await (@fetch = oFetch @data)
					@fetch = null
					# check
					if R instanceof Error
						return if R.id == 4
							then true   # cancelled, dirty state
							else false  # fatal failure
					# read metadata
					if (a = await R.readInt!) == null
						R.cancel!
						return false
					###
					# manage state
					# update total records and page count
					@state.total  = a
					@state.page.1 = Math.ceil (a / @data.limit)
					# unlock and refresh blocks
					for a in B
						a.lock 0, @level if a.locked
						a.refresh!
					# clear group flags
					for a in @super.groups when a.state.pending
						a.state.pending = false
					# reset priority
					@level = 0
					###
					# feed eaters (with records)
					if (B = @super.eaters).length
						# iterate for projected count
						a = @data.limit
						while ~--a and not @dirty
							# get record
							if (b = await R.readJSON!) == null
								R.cancel!
								return false
							# feed
							for c in B
								c.eat b
						# end feed
						for c in B
							c.eat null
						# satisfy chrome (2020-04), it produces unnecessary errors
						await R.read!
					# complete
					R.cancel!
					return true
				# }}}
			# }}}
			return (s) -> new Loader s
		# }}}
		newResizer = do -> # {{{
			Resizer = (node, parent) !->
				@node     = node
				@parent   = parent
				@children = null
				@blocks   = null
			###
			Resizer.prototype =
				init: (blocks) !-> # {{{
					# collect child nodes
					n = [...(@node.querySelectorAll '.sm-blocks-resizer')]
					# determine children
					c = []
					for a in n
						# lookup node parents
						b = a.parentNode
						while b != @node and (n.indexOf b) == -1
							b = b.parentNode
						# create new child
						if b == @node
							c[*] = b = new Resizer a, @
							b.init blocks
					# store
					@children = c if c.length
					# determine own blocks
					c = []
					for a in blocks
						# lookup block parent nodes
						b = a.root
						while b and b != @node and (n.indexOf b) == -1
							b = b.parentNode
						# add block
						if b == @node
							c[*] = a
					# store
					@blocks = c if c.length
					# done
				# }}}
			###
			return (s) ->
				# create root and construct a tree
				R = new Resizer s.root, null
				R.init s.blocks
				# done
				return R
		# }}}
		# constructors
		GroupState = (group) !-> # {{{
			# create object shape
			@config  = null
			@data    = null
			@pending = false
			@change  = !->
				# group resolution api
				@pending = true
				group.resolve!
		# }}}
		Group = (MasterBlock, nodes) !-> # {{{
			# initialize
			s = new GroupState @
			a = -1
			while ++a < nodes.length
				nodes[a] = new MasterBlock s, nodes[a], a
			# get first block
			a = nodes.0
			# create object shape
			@blocks  = nodes
			@name    = a.group
			@level   = a.level
			@resolve = null
			@state   = s
		# }}}
		Visor = (m) !-> # {{{
			@masters = (m and M ++ m) or M
			@root    = null
			@resizer = null
			@loader  = null
			@counter = 0 # user's action count
			@groups  = []
			@blocks  = []
			@eaters  = []
			m = (m and 'custom ') or ''
			consoleInfo 'new '+m+'supervisor'
		###
		Visor.prototype =
			attach: (root) ->> # {{{
				###
				# check
				if not root
					return false
				else if @root
					# detach first
					if not (await @detach!)
						return false
					# continue
					consoleInfo 're-attaching..'
				else
					consoleInfo 'attaching..'
				###
				# initialize lists
				# prepare
				groups = @groups
				blocks = @blocks
				eaters = @eaters
				# create groups
				for [a, b] in @masters
					if (b = [...(root.querySelectorAll b)]).length
						groups[*] = new Group a, b
				# check
				if not groups.length
					return false
				# collect blocks
				for a in groups
					blocks.push ...a.blocks
				# order blocks and groups by priority level (ascending)
				a = (a, b) ->
					return if a.level < b.level
						then -1
						else if a.level == b.level
							then 0
							else 1
				groups.sort a
				blocks.sort a
				# collect eaters
				for a in blocks when a.eat
					eaters[*] = a
				###
				# initialize controllers
				@root    = root
				@loader  = loader = newLoader @
				@resizer = newResizer @
				@counter = 0
				###
				# start
				if not (await loader.init!)
					await @detach!
					consoleError 'attachment failed'
					return false
				# enter the dragon
				consoleInfo 'supervisor attached'
				while await loader.operate!
					++@counter
				# complete
				consoleInfo 'supervisor detached, '+@counter+' actions'
				return true
			# }}}
			detach: ->> # {{{
				# cleanup
				@root = @resizer = @loader = null
				@groups.length = @blocks.length = 0
				# done
				return true
			# }}}
		# }}}
		return Visor
	# }}}
	# factory
	return (m) -> new SUPERVISOR m
###
# DELETE (later) {{{
smBlocks = smBlocks!
smBlocks.attach document
# }}}
