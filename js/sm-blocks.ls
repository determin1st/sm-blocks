"use strict"
smBlocks = do ->>
	# TODO {{{
	# - price filter (!)
	# - ...
	# - static paginator max-width auto-calc
	# - grid's goto next page + scroll up (?)
	# }}}
	# prepare
	# {{{
	# constants
	BRAND = 'sm-blocks'
	# common fetcher
	soFetch = httpFetch.create {
		baseUrl: '/?rest_route=/'+BRAND+'/kiss'
		mounted: true
		notNull: true
		method: 'POST'
	}
	# helpers
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
	delay = (ms, f) -> # {{{
		# create custom promise
		p = newPromise!
		# start timer
		t = setTimeout !->
			p.resolve true
			f! if f
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
	newMetaObject = do -> # {{{
		handler =
			get: (o, k) -> # {{{
				# get current value
				if o.0.hasOwnProperty k
					return o[0][k]
				# get difference flag
				if k.0 == '$'
					k = k.slice 1
					return if k and o.0.hasOwnProperty k
						then o[0][k] != o[1][k]
						else true
				# get previous value
				if k.0 == '_'
					k = k.slice 1
					return if k and o.1.hasOwnProperty k
						then o[1][k]
						else null
				# nothing
				return null
			# }}}
			set: (o, k, v) -> # {{{
				# check exists
				if o.0.hasOwnProperty k
					# backup and set new value
					o[1][k] = o[0][k]
					o[0][k] = v
				# done
				return true
			# }}}
		return (o) ->
			return new Proxy [o, {} <<< o], handler
	# }}}
	BlockState = (name, level, handler) !-> # {{{
		@name    = name
		@level   = level
		@event   = handler
		@data    = null
		@master  = null
		@ready   = []
		@pending = false
	###
	BlockState.prototype = {
		change: !->
			# set the flag
			@pending = true
			# let the master find the solution
			@master.resolve @
		onChange: (m) ->
			# OBEY only to higher update levels
			if @level < m.level
				# dispatch lock request
				@event 'lock'
				return true
			# dispatch notification and
			# allow the negative response for the group control,
			# by the privilege of being first
			return @event 'change', m
		onLoad: (m) ->
			# reset the flag
			@pending = false if @pending
			# dispatch notification
			return @event 'load', m
	}
	# }}}
	# }}}
	# slaves
	sMainSection = do -> # {{{
		# constructors
		Control = (block) !-> # {{{
			# data
			@block = block
			# handlers
			# ...
		###
		Control.prototype = {
			attach: !-> # {{{
				# iterate items
				for a of b = @block.item
					b[a].attach!
				# done
			# }}}
			detach: !-> # {{{
				true
			# }}}
		}
		# }}}
		Item = do -> # {{{
			Events = (item) !-> # {{{
				@item    = item
				@hovered = false
				@focused = false
				block = item.block
				@switchHover = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if not block.locked and not @hovered
						item.node.classList.add 'hovered'
						@hovered = true
				# }}}
				@switchUnhover = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if @hovered
						item.node.classList.remove 'hovered'
						@hovered = false
				# }}}
				@switchFocus = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if not block.locked and not @focused
						item.node.classList.add 'focused'
						@focused = true
				# }}}
				@switchUnfocus = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if not block.locked and @focused
						item.node.classList.remove 'focused'
						@focused = false
				# }}}
				@switch = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if not block.locked
						item.opened = !item.opened
						item.node.classList.toggle 'opened', item.opened
						if not @focused and item.switch
							item.switch.focus!
				# }}}
			# }}}
			return Item = (block, node, parent) !->
				# item base
				@block    = block
				@node     = node
				@id       = +node.dataset.id    # unique identifier
				@order    = +node.dataset.order # position in the list
				@parent   = parent
				@opened   = node.classList.contains 'opened'
				# containers
				@titleBox = box = node.firstChild
				@arrowBox = arrow = querySelectorChild box, '.arrow'
				@extraBox = querySelectorChild box, '.extra'
				@section  = sect = querySelectorChild node, '.section'
				# controls
				@title    = box.firstChild
				@switch   = if arrow
					then querySelectorChild arrow, '.switch'
					else null
				# children
				if (a = querySelectorChildren sect, '.item').length
					# store
					@children = a
					# initialize
					for b,c in a
						a[c] = new Item block, b, @
				else
					@children = null
				# event handlers
				@events = new Events @
		#####
		Item.prototype =
			attach: !-> # {{{
				# prepare
				B = @block
				E = @events
				# check arrow mode enabled and
				# set switch handlers
				if B.mode .&. 4
					if a = @switch
						a.addEventListener 'click', E.switch
						a.addEventListener 'pointerenter', E.switchHover
						a.addEventListener 'pointerleave', E.switchUnhover
						a.addEventListener 'focusin', E.switchFocus
						a.addEventListener 'focusout', E.switchUnfocus
					a = @title
					a.addEventListener 'click', E.switch
					a.addEventListener 'pointerenter', E.switchHover
					a.addEventListener 'pointerleave', E.switchUnhover
				# done
			# }}}
			detach: !-> # {{{
				true
			# }}}
		# }}}
		Block = (root, state) !-> # {{{
			# containers
			@root     = root
			@rootBox  = box  = root.firstChild
			@rootItem = root = new Item @, box, null
			@lines    = querySelectorChildren box, 'hr'
			# items
			sect      = {}     # with section (parents)
			item      = {}     # all
			list      = [root] # all ordered
			# initialize
			# {{{
			a = -1
			while ++a < list.length
				if (b = list[a]).children
					sect[b.id] = b
					list ++= b.children
				item[b.id] = b
			# }}}
			@sect     = sect
			@item     = item
			@list     = list
			# state
			@mode     = +box.dataset.mode
			@state    = state
			@locked   = 1
			@class    = {}
			@ctrl     = new Control @
		###
		Block.prototype =
			init: ->> # {{{
				@ctrl.attach!
				@root.classList.add 'v'
				return true
			# }}}
			lock: (level) !-> # {{{
				# check
				switch level
				case 1
					if not @locked
						@rootBox.classList.remove 'v'
				default
					if @locked
						@rootBox.classList.add 'v'
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
			refresh: (list) !-> # {{{
				# iterate changed items
				for a in list
					# get item
					a = @item[a]
					# set visual state
					if b = a.state._checked
						a.checkbox.classList.remove if b == 2
							then 'indeterminated'
							else 'checked'
					if b = a.state.checked
						a.checkbox.classList.add if b == 2
							then 'indeterminated'
							else 'checked'
				# determine new filter
				list = []
				for a,b of @item
					# get state
					a = b.id
					b = b.state
					# collect non-empty category identifiers
					if b.checked == 1 and b.count > 0
						list[*] = a
				# get old filter's data and
				# check the difference exists
				b = state.data[@index][1]
				if b.length == list.length
					a = list.every (a) -> (b.indexOf a) != -1
					return if a
				# set new filter
				state.data[@index][1] = list
				state.change!
				# done
			# }}}
			finit: !-> # {{{
				@root.classList.remove 'v'
				@ctrl.detach!
			# }}}
		# }}}
		# factory
		return (node, state) ->
			return new Block node, state
	# }}}
	sCart = do -> # {{{
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
	sGridCard = do -> # TODO {{{
		return null
	# }}}
	# masters
	KING = do -> # {{{
		# prepare
		# {{{
		# get container
		if not root = document.querySelector '.sm-blocks.grid'
			return null
		# create control vars
		grid        = root.firstChild
		gridList    = [...grid.children]
		gridControl = []
		gridState   = {
			# state
			dirty: false # resolved-in-process flag
			level: 100   # update priority (highest for the first)
			# content
			config: {}   # localized block's data/options
			orderOption: null # TODO: delete
			total: 0     # items in the set
			count: 0     # displayed items
			# modifiers
			pageCount: 0 # calculated total/count
			pageIndex: 0 # current page
			orderFilter: ['',  0] # tag, variant
			# filters
			priceFilter: [false, -1, -1, -1, -1] # enabled, a, b, aMin, bMax
		}
		gridLock = do ->>
			# load configuration
			a = sCart.load!
			b = soFetch {
				func: 'config'
				lang: ''
				category: null
			}
			c = gridState.config
			d = await Promise.all [a, b]
			c <<< d.1
			# set current state
			# order tags
			a = grid.dataset.order.split ','
			if b = a.length
				# set order options
				gridState.orderOption = d = {}
				e = -1
				while ++e < b
					d[a[e]] = c.locale.order[a[e]]
				# set default order
				b = parseInt grid.dataset.index
				b = a[b]
				gridState.orderFilter.0 = b
				gridState.orderFilter.1 = c.locale.order[b].1
			# price range
			if a = c.priceRange
				gridState.priceFilter.3 = a.0
				gridState.priceFilter.4 = a.1
			# total items
			gridState.total = a = c.total
			# count of pages
			gridState.pageCount = Math.ceil (a / gridList.length)
			# done
			return true
		# }}}
		gridResizer = do -> # {{{
			# resize controller
			# initialize
			style = getComputedStyle grid
			state =
				columnsMax:  +(style.getPropertyValue '--columns')
				columnsMin:  +(grid.dataset.cols)
				columnGap:   parseInt (style.getPropertyValue '--column-gap')
				rowsMin:     +(style.getPropertyValue '--rows')
				rowsMax:     0
				rowGap:      parseInt (style.getPropertyValue '--row-gap')
				itemX:       parseInt (style.getPropertyValue '--item-max-x')
				itemXA:      0
				itemY:       parseInt (style.getPropertyValue '--item-max-y')
				itemYA:      0
				fontSizeMax: parseInt (style.getPropertyValue '--font-size')
				ratio:       0
				width:       0
				fontSize:    0
				columns:     0
				rows:        0
			###
			state.ratio   = state.itemY / state.itemX # aspect ratio (ideal proportion)
			state.rowsMax = Math.ceil (gridList.length / state.columnsMin)
			state.itemXA  = state.itemX + state.columnGap / 2
			state.itemYA  = state.itemY + state.rowGap / 2
			# create handler
			f = (e) !->
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
				grid.style.setProperty '--columns', state.columns
				grid.style.setProperty '--rows', state.rows
				grid.style.setProperty '--height', state.height+'px'
				grid.style.setProperty '--font-size', state.fontSize+'px'
				# dispatch resize event
				for c in gridControl
					c.event 'resize', state
			# observe root resizing
			(new ResizeObserver f).observe root, {
				box: 'border-box'
			}
			# done
			return f
		# }}}
		gridLoader = do -> # {{{
			# {{{
			cooldown = 800  # update timeout
			# create items fetcher
			iFetch = httpFetch.create {
				baseUrl: '/?rest_route=/'+BRAND+'/kiss'
				mounted: true
				notNull: true
				method: 'POST'
				timeout: 0
				parseResponse: 'stream'
			}
			res = null
			req = {
				func: 'grid'
				limit: gridList.length
				offset: 0
				category: null
				order: gridState.orderFilter
				price: gridState.priceFilter
			}
			# }}}
			setState = (s) -> # {{{
				# manage update priority
				# prevent changes from lower levels
				if gridState.level > s.level
					return false
				# rise current
				if gridState.level < s.level
					gridState.level = s.level
				# change state
				switch s.name
				case 'category'
					# {{{
					# format category filter's data
					# prepare
					a = [] # AND
					b = [] # OR
					# aggregate
					for c in s.data
						switch c.0
						case 'AND'
							# simple append
							a[*] = c.1 if c.1.length
						case 'OR'
							# merge unique
							for d in c.1 when (b.indexOf d) == -1
								b[*] = d
					# merge
					a[*] = b if b.length
					# set filter
					req.category = if a.length
						then a
						else null
					# reset offset & page index
					req.offset = gridState.pageIndex = 0
					# }}}
				case 'page'
					# {{{
					# set new page index and
					# determine first record offset
					gridState.pageIndex = s.data.0
					req.offset = gridState.pageIndex * req.limit
					# }}}
				case 'order'
					# {{{
					gridState.orderFilter.0 = s.data.0
					gridState.orderFilter.1 = s.data.1
					# }}}
				# done
				return true
			# }}}
			clearState = !-> # {{{
				true
			# }}}
			unloadItems = !-> # {{{
				if c = gridState.count
					# clear product cards in the reverse order
					while --c >= 0
						gridList[c].cls!
					# reset
					gridState.count = 0
			# }}}
			newMasterPromise = -> # {{{
				# create custom promise
				r = null
				p = new Promise (resolve) !->
					r := resolve
				# create custom resolver
				p.pending = true
				p.resolve = (data) !->
					# update state
					if data and not setState data
						return
					# check
					if p.pending
						# resolve clean
						p.pending = false
						r!
					else if not gridState.dirty
						# set dirty
						gridState.dirty = true
						# terminate fetcher
						res.cancel! if res
				# done
				return p
			# }}}
			return ->>
				# check
				if gridState.dirty
					# reset
					gridState.dirty = false
					# to guard against excessive load calls
					# caused by multiple user actions,
					# it's important to do a short cooldown..
					gridLock := delay cooldown
				else if not gridLock
					# set master lock
					gridLock := newMasterPromise!
					for c in gridControl
						c.master = gridLock
				# wait for the update
				await gridLock
				# unload grid items
				unloadItems!
				# multiple updates may not squeeze in here,
				# otherwise, restart early..
				if gridState.dirty
					return true
				# new update arrived,
				# sync state of the masters
				for c in gridControl
					if not c.onChange gridState
						# master wants to restart
						return true
				# start fetching
				a = await (res := iFetch req)
				# cleanup
				res := null
				# check the result
				if a instanceof Error
					return if a.id == 4
						then true   # dirty update, cancelled
						else false  # fatal failure
				# get total
				if (b = await a.readInt!) == null or gridState.dirty
					a.cancel!
					return gridState.dirty
				# update internal state
				# {{{
				# set total items
				gridState.total = b
				# set count of displayed
				gridState.count = if (c = b - req.offset) < gridList.length
					then c
					else gridList.length
				# set count of pages
				gridState.pageCount = Math.ceil (b / gridList.length)
				# dispatch load event
				for c in gridControl
					c.onLoad gridState
				# reset
				gridState.level = 0
				# }}}
				# async loop
				c = -1
				while ++c < gridState.count and not gridState.dirty
					# get item data
					if (b = await a.readJSON!) == null
						a.cancel!
						return false
					# apply
					gridList[c].set b
				# check the loop aborted
				if c != gridState.count
					# fix display count
					gridState.count = c
				else
					# satisfy chrome browser (2020-04),
					# as it produces unnecessary console error
					await a.read!
				# complete
				a.cancel!
				return true
		# }}}
		# CARD handler
		# {{{
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
					x = sCart.get data.id
					if s.count == 0 or (x and s.count <= x.quantity)
						e.disabled = true
					# create event handler and
					# store it for later removal
					c[i] = f = (a) !->>
						# prepare
						a.preventDefault!
						e.disabled = true
						# add simple single product to cart
						if not (a = await sCart.add data.id)
							return
						# reload cart items and
						# check if more items may be added
						if not await sCart.load!
							return
						x = sCart.get data.id
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
		# api
		return {
			resize: gridResizer
			rule: (c) ->> # {{{
				# construct and activate grid
				if not grid.classList.contains 'v'
					for a,b in gridList
						gridList[b] = newItem a
					gridResizer!
					root.classList.add 'v'
				# wait until state is ready to use
				a = [gridLock]
				for b in c when b
					a ++= b.ready
				await Promise.all a
				# add new controllers
				for a in c when a
					gridControl[*] = a
					a.event 'init', gridState
				# enter the dragon
				if await gridLoader!
					# activate
					grid.classList.add 'v'
					gridLock := null
					# loop forever
					while await gridLoader!
						gridLock := null
				# terminate
				console.log 'FATAL ERROR?'
				return true
			# }}}
		}
	# }}}
	mProductsGrid = do -> # {{{
		###
		Block = (root) !-> # {{{
			# root
			@root    = root
			@rootBox = root.firstChild
			# controller
			@state = new State @
		# }}}
		State = (block) !-> # {{{
			# grid
			@block = block
			@lock  = null  # master lock
			@dirty = false # resolved-in-process flag
			@level = 0     # update priority level
			@total = 0     # items in the set
			@count = 0     # displayed items
			# paginator
			@pageCount = 0 # calculated total/count
			@pageIndex = 0 # current page
			# orderer
			@orderOption = null
			@orderFilter = ['', 0]
			# cart
			# ...
			# initialize
			# ...
		# }}}
		# api
		# initialize
		# {{{
		# create common state
		state = new BlockState 'grid', 0, (event, data) ->
			# done
			return true
		# }}}
		return state
	# }}}
	mCategoryFilter = do -> # {{{
		# constructors
		Item = (block, node) !-> # {{{
			# {{{
			@block    = block
			@node     = node
			@id       = +node.dataset.id
			@parent   = null
			@children = null
			@name     = name = node.children.0
			@nameBox  = name.querySelector '.box'
			@input    = name.querySelector '.box > input'
			@checkbox = name.querySelector '.box > .check'
			@count    = name.querySelector '.count'
			@arrow    = name.querySelector '.arrow'
			@sect     = if node.children.1
				then node.children.1
				else null
			@state    = newMetaObject (new ItemState @)
			@events   = new ItemEvents @
			# }}}
		Item.prototype =
			toggleCheckbox: do -> # {{{
				setChildren = (items, checked) !-> # {{{
					# create change list
					list = []
					# iterate items
					for a in items when a.state.checked != checked
						# set child
						a.state.checked = checked
						list[*] = a.id
						# recurse
						if a.children
							list = list ++ (setChildren a.children, checked)
					# done
					return list
				# }}}
				setParent = (item, checked) !-> # {{{
					# check
					if checked == 2
						# this value may only come from another parent,
						# no need to check children
						a = 2
					else
						# assume state homogeneity and
						# iterate children to find the opposite
						a = checked
						for b in item.children when b.state.checked != a
							a = 2
							break
					# set
					if item.state.checked == a
						b = []
					else
						item.state.checked = a
						b = [item.id]
					# recurse and complete
					return if item.parent
						then (setParent item.parent, a) ++ b
						else b
				# }}}
				return !->
					# prepare
					s = @state
					# settle self first
					s.checked = if s.checked == 2
						then 1 # force positive determinism
						else if s.checked
							then 0
							else 1
					# create change list
					list = [@id]
					# set parents
					if @parent
						list = list ++ (setParent @parent, s.checked)
					# set children
					if @children
						list = list ++ (setChildren @children, s.checked)
					# done
					@block.refresh list
			# }}}
		# }}}
		ItemState = (item) !-> # {{{
			@checked = 0 # 0=false, 1=true, 2=indeterminated
			@opened  = if item.sect
				then item.sect.classList.contains 'opened'
				else false
			@count   = +item.node.dataset.count
			@order   = +item.node.dataset.order
		# }}}
		ItemEvents = (item) !-> # {{{
			@item = item
			@toggleSection = (e) !~> # {{{
				# prepare
				e.preventDefault!
				e.stopPropagation!
				# set state
				s = item.state
				s.opened = !s.opened
				item.sect.classList.toggle  'opened', s.opened
				item.arrow.classList.toggle 'opened', s.opened
				# set focus
				item.input.focus!
			# }}}
			@toggleCheckbox = (e) !~> # {{{
				# prepare
				e.preventDefault!
				e.stopPropagation!
				# set state
				item.toggleCheckbox!
				# set focus
				item.input.focus!
			# }}}
		ItemEvents.prototype =
			attach: !-> # {{{
				# set event handlers
				if (item = @item).sect
					item.arrow.addEventListener 'click', @toggleSection
				item.nameBox.addEventListener 'click', @toggleCheckbox, true
			# }}}
			detach: !-> # {{{
				# remove event handlers
				if (item = @item).sect
					item.arrow.removeEventListener 'click', @toggleSection
				item.nameBox.removeEventListener 'click', @toggleCheckbox, true
			# }}}
		# }}}
		Block = (root) !-> # {{{
			# {{{
			# create object shape
			@root    = root
			@rootBox = rootBox = root.firstChild
			@op      = rootBox.dataset.op
			@index   = 0
			@item    = item = {} # all
			@sect    = sect = {} # parents
			@locked  = true
			# initialize
			# create items map
			list = [...root.querySelectorAll '.item']
			for a in list
				# set item and section
				b = new Item @, a
				item[b.id] = b
				sect[b.id] = b if b.sect
			# set parent-child relations
			for a,b of sect
				# create array
				b.children = c = []
				# aggregate children items
				# in the order rendered
				for a in b.sect.children
					# get child
					d = item[a.dataset.id]
					# set parent
					d.parent = b
					# add to the parent
					c[*] = item[a.dataset.id]
			# complete
			# set event handlers
			for a of item
				a = item[a]
				a.events.attach!
			# set ready
			root.classList.add 'v'
			# }}}
		Block.prototype =
			init: (index) !-> # {{{
				# create block's data
				@index = index
				state.data[index] = [@op, []]
			# }}}
			refresh: (list) !-> # {{{
				# iterate changed items
				for a in list
					# get item
					a = @item[a]
					# set visual state
					if b = a.state._checked
						a.checkbox.classList.remove if b == 2
							then 'indeterminated'
							else 'checked'
					if b = a.state.checked
						a.checkbox.classList.add if b == 2
							then 'indeterminated'
							else 'checked'
				# determine new filter
				list = []
				for a,b of @item
					# get state
					a = b.id
					b = b.state
					# collect non-empty category identifiers
					if b.checked == 1 and b.count > 0
						list[*] = a
				# get old filter's data and
				# check the difference exists
				b = state.data[@index][1]
				if b.length == list.length
					a = list.every (a) -> (b.indexOf a) != -1
					return if a
				# set new filter
				state.data[@index][1] = list
				state.change!
				# done
			# }}}
			unlock: !-> # {{{
				@rootBox.classList.add 'v'
				@locked = false
			# }}}
		# }}}
		# initialize
		# {{{
		# create common state
		state = new BlockState 'category', 2, (event, data) ->
			switch event
			case 'init'
				# initialize
				for a,b in blocks
					a.init b
			case 'load'
				# check locked
				for a in blocks when a.locked
					a.unlock!
			# done
			return true
		# create widget's data
		state.data = []
		# create individual blocks
		blocks = [...(document.querySelectorAll '.sm-blocks.category-filter')]
		blocks = blocks.map (root) -> new Block root
		# }}}
		return state
	# }}}
	mPriceFilter = do -> # {{{
		# constructors
		TextInputs = (block) !-> # {{{
			# parent
			@block = block
			# containers
			a = block.rootBox
			b = a.children.0
			c = a.children.2
			@boxes = [b, c]
			# controls
			@svg = a.children.1
			@resetBtn = querySelectorChild @svg, '.state'
			@input = [b.children.0, c.children.0]
			@label = [b.children.1, c.children.1]
			# event handlers
			@rootHover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if not block.locked and not @hovered.3
					@hovered.3 = true
					block.rootBox.classList.add 'hovered'
			# }}}
			@rootUnhover = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# operate
				if @hovered.3
					@hovered.3 = false
					block.rootBox.classList.remove 'hovered'
			# }}}
			# {{{
			@boxHovers = [
				@boxHover   0
				@boxUnhover 0
				@boxHover   1
				@boxUnhover 1
			]
			@inputFocus = [
				@inputFocusIn  0
				@inputFocusOut 0
				@inputFocusIn  1
				@inputFocusOut 1
			]
			@labelClicks = [
				@labelClick 0
				@labelClick 1
			]
			@inputEvents = [
				@inputChange 0
				@inputChange 1
				@inputKey  0
				@inputKey  1
			]
			@inputWheels = [
				@inputWheel 0
				@inputWheel 1
				@inputWheel -1
			]
			# }}}
			@reset = (e) !~> # {{{
				# check
				if @block.locked
					return
				# fulfil event
				if e
					e.preventDefault!
					e.stopPropagation!
				# check
				if (c = @block.current).0
					# reset
					c.0 = false
					c.1 = c.2 = -1
					# submit instantly
					@set c.3, c.4
					@submit!
			# }}}
			# state
			@hovered = [false, false, false]
			@focused = [false, false, false]
			@values  = ['', '', 0, 0, 0, 0]
			@changed = 0
			@locked  = 1
			@regex   = /^[0-9]{0,9}$/
			@stepSz  = 10/100
			@waiter  = delay 0
		###
		TextInputs.prototype =
			init: (cfg) !-> # {{{
				# set label names
				@label.0.textContent = cfg.min
				@label.1.textContent = cfg.max
			# }}}
			attach: !-> # {{{
				# hover maze
				B = @block
				B.rootBox.addEventListener 'pointerenter', @rootHover
				B.rootBox.addEventListener 'pointerleave', @rootUnhover
				a = @boxHovers
				b = @boxes
				b.0.addEventListener 'pointerenter', a.0
				b.0.addEventListener 'pointerleave', a.1
				b.1.addEventListener 'pointerenter', a.2
				b.1.addEventListener 'pointerleave', a.3
				# focus maze
				a = @inputFocus
				b = @input
				b.0.addEventListener 'focusin',  a.0
				b.0.addEventListener 'focusout', a.1
				b.1.addEventListener 'focusin',  a.2
				b.1.addEventListener 'focusout', a.3
				# label when focused:
				# resets to default min/max value
				a = @label
				b = @labelClicks
				a.0.addEventListener 'pointerdown', b.0, true
				a.1.addEventListener 'pointerdown', b.1, true
				# input maze
				a = @inputEvents
				b = @input
				b.0.addEventListener 'input', a.0, true
				b.1.addEventListener 'input', a.1, true
				b.0.addEventListener 'keydown', a.2, true
				b.1.addEventListener 'keydown', a.3, true
				a = @inputWheels
				b = @boxes
				b.0.addEventListener 'wheel', a.0
				b.1.addEventListener 'wheel', a.1
				@svg.addEventListener 'wheel', a.2
				if a = @resetBtn
					a.addEventListener 'click', @reset
				# done
			# }}}
			detach: !-> # {{{
				# done
			# }}}
			set: (min, max) !-> # {{{
				v   = @values
				v.0 = @input.0.value = '' + min
				v.1 = @input.1.value = '' + max
				v.2 = v.3 = 0
				v.4 = v.0.length
				v.5 = v.1.length
			# }}}
			check: (n) -> # {{{
				# get the values
				a = +@input.0.value
				b = +@input.1.value
				c = @block.current
				d = true # input is correct
				# check range numbers
				if a > b
					# swap values (user mixed-up min>max)
					d = a
					a = b
					b = d
					d = false
				else if a == b
					# push inactive border
					if n
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
			submit: !-> # {{{
				# reset and notify
				@changed = 0
				@block.submit!
			# }}}
			lock: (level) !-> # {{{
				# prepare
				I = @input
				B = @boxes
				F = @focused
				# check
				switch level
				case 1
					if not @locked
						I.0.readOnly = true
						I.1.readOnly = true
						B.0.classList.add 'locked'
						B.1.classList.add 'locked'
						if F.2
							if F.1
								I.1.setSelectionRange 0, 0
							else
								I.0.setSelectionRange 0, 0
				default
					if @locked
						I.0.readOnly = false
						I.1.readOnly = false
						B.0.classList.remove 'locked'
						B.1.classList.remove 'locked'
						if F.2
							if F.1
								I.1.select!
							else
								I.0.select!
				# set
				@locked = level
			# }}}
			inputScroll: (n, direction) !-> # {{{
				# determine step size
				c = @block.current
				a = if c.4 > 100
					then 0.01
					else 0.1
				# determine current position
				d = c.4 - c.3
				b = (+@values[n] - c.3) / d
				# check the direction and
				# increment or decrement current
				if direction
					b += 1.5 * a
				else
					b -= 0.5 * a
				# clamp to the step and
				# determine new position
				b = a * (b/a .|. 0)
				a = c.3 + b * d .|. 0
				# determine new range
				if n
					b = a
					a = +@values.0
					if b >= c.4
						b = c.4
					else if b <= a
						b = a + 1
				else
					b = +@values.1
					if a <= c.3
						a = c.3
					else if a >= b
						a = b - 1
				# apply
				@set a, b
				# done
			# }}}
			boxHover: (n) -> (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check
				if not (B = @block).locked
					# operate
					H    = @hovered
					H[n] = true
					# set root state
					if not H.2
						H.2 = true
						B.rootBox.classList.add 'hovered'
					B.rootBox.classList.add if n
						then 'R'
						else 'L'
					# set own state
					@boxes[n].classList.add 'hovered'
			# }}}
			boxUnhover: (n) -> (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				# check
				if (H = @hovered)[n]
					# operate
					B    = @block
					H[n] = false
					# set root state
					if not @focused[n]
						B.rootBox.classList.remove if n
							then 'R'
							else 'L'
					# set own state
					@boxes[n].classList.remove 'hovered'
			# }}}
			inputFocusIn: (n) -> (e) !~> # {{{
				# check
				if (B = @block).locked
					# inactive
					e.preventDefault!
					e.stopPropagation!
				else
					# operate
					H    = @hovered
					F    = @focused
					F[n] = true
					# set root state
					if not F.2
						F.2 = true
						B.rootBox.classList.add 'focused'
					if not H[n]
						B.rootBox.classList.add if n
							then 'R'
							else 'L'
					# set own state
					@input[n].select!
					@boxes[n].classList.add 'focused'
			# }}}
			inputFocusOut: (n) -> (e) !~> # {{{
				# operate
				B    = @block
				F    = @focused
				F[n] = false
				F.2  = false
				# set root state
				B.rootBox.classList.remove 'focused'
				if not @hovered[n]
					B.rootBox.classList.remove if n
						then 'R'
						else 'L'
				# set own state
				@boxes[n].classList.remove 'focused'
				# checkout and try to submit
				@check n
				@submit! if @changed
			# }}}
			labelClick: (n) -> (e) !~> # {{{
				# check
				if @block.locked or not @focused[n]
					return
				# fulfil the event
				e.preventDefault!
				e.stopPropagation!
				# prepare
				a = ''+@block.current[3 + n]
				e = @values
				# check current against default
				if e[n] != a
					# restore default
					e[n]   = @input[n].value = a
					e[2+n] = 0
					e[4+n] = a.length
					# submit fluently
					@check n
					@submit! if @changed
				# select text
				@input[n].select!
			# }}}
			inputChange: (n) -> (e) ~> # {{{
				# prepare
				v = @values
				a = @input[n]
				b = a.value
				# check
				if b.length
					# non-empty
					if not @regex.test b
						# invalid,
						# restore previous
						a.value = v[n]
						a.setSelectionRange v[2+n], v[4+n]
					else
						# save and continue typing..
						v[n]   = b
						v[2+n] = a.selectionStart
						v[4+n] = a.selectionEnd
						return true
				else
					# empty,
					# restore the default
					c = @block.current
					if (b = c[3+n]) >= 0 or \
					   (b = c[1+n]) >= 0
						###
						v[n]   = a.value = "" + b
						v[2+n] = 0
						v[4+n] = v[n].length
						a.select!
				# dont do the default
				e.preventDefault!
				e.stopPropagation!
				return false
			# }}}
			inputKey: (n) -> (e) !~> # {{{
				# check
				if @block.locked
					return
				# operate
				if e.keyCode == 13
					# Enter {{{
					# cancel default action
					e.preventDefault!
					e.stopPropagation!
					# determine action type
					if e.ctrlKey
						# fluent submit
						@check n
						@submit! if @changed
					else
						# validate input and submit
						if @check n and @changed
							@submit!
						# focus the opposite input
						@input[n.^.1].focus!
					# done
					# }}}
				else if e.keyCode in [38 40]
					# Up, Down {{{
					# cancel default action
					e.preventDefault!
					e.stopPropagation!
					# scroll number
					@inputScroll n, (e.keyCode == 38)
					@input[n].select!
					# }}}
				# done
			# }}}
			inputWheel: (n) -> (e) ~>> # {{{
				# check
				if @block.locked
					return
				# fulfil the event
				e.preventDefault!
				e.stopPropagation!
				# operate
				# terminate waiter
				@waiter.cancel!
				# scroll numbers
				if n < 0
					e = e.deltaY < 0
					@inputScroll 0, not e
					@inputScroll 1, e
				else
					@inputScroll n, (e.deltaY < 0)
					@input[n].select! if @focused[n]
				# initiate submit sequence
				if await (@waiter = delay 400)
					# timeout passed, submit fluently
					@check n
					@submit! if @changed
				# done
				return true
			# }}}
		# }}}
		Block = (root, state) !-> # {{{
			# {{{
			# containers
			@root    = root
			@rootBox = box = root.firstChild
			# determine UI mode
			mode = if box.classList.contains 'text'
				then 0
				else 1
			# controls
			@ctrl = if mode == 0
				then new TextInputs @
				else null
			box = root.parentNode.parentNode.parentNode
			@section = box = new sMainSection box
			# state
			@mode    = mode
			@state   = state
			@locked  = 2
			@current = [false, -1, -1, -1, -1]
			# initialize
			state.ready[*] = box.init!
				.then (x) ~>
					# activate controls
					if x
						@ctrl.attach!
						@root.classList.add 'v'
					# done
					return x
			# }}}
		Block.prototype =
			init: (cfg) !-> # {{{
				@ctrl.init cfg
				@refresh!
			# }}}
			refresh: !-> # {{{
				# prepare
				a = @state.data # source
				b = @current    # destination
				# check status changed
				if a.0 != b.0
					@rootBox.classList.toggle 'active', a.0
					@section.setClass 'active', a.0
				# check current changed
				if a.0 != b.0 or a.1 != b.1 or a.2 != b.2
					@ctrl.set a.1, a.2
				# check range limits (TODO: delete)
				if a.3 != b.3 or a.4 != b.4
					@ctrl.set a.3, a.4
				# sync
				b[0 to 4] = a
			# }}}
			submit: !-> # {{{
				# prepare
				a = @current    # source
				b = @state.data # destination
				# check status changed
				if a.0 != b.0
					@rootBox.classList.toggle 'active', a.0
					@section.setClass 'active', a.0
				# sync
				b[0 to 2] = a
				# notify
				@state.change!
			# }}}
			lock: (level) !-> # {{{
				# check
				switch level
				case 2
					# full lock
					switch @locked
					case 1
						@ctrl.lock 1
						fallthrough
					case 0
						@rootBox.classList.remove 'v'
						@section.lock!
					###
				case 1
					# partial lock
					if not @locked
						@ctrl.lock 1
					###
				default
					# full unlock
					switch @locked
					case 2
						@section.lock 0
						@rootBox.classList.add 'v'
						fallthrough
					case 1
						@ctrl.lock 0
					###
				# set
				@locked = level
			# }}}
		# }}}
		# initialize
		# {{{
		# create common state
		state = new BlockState 'price', 2, (event, data) ->
			switch event
			case 'init'
				# initialize
				@data = data.priceFilter
				for b in blocks
					b.init data.config.locale.price
			case 'change'
				# when foreign update initiator,
				# sieze input processing
				if not @pending
					for a in blocks
						a.lock 1
			case 'lock'
				# stop any interactions
				for a in blocks
					a.lock 2
			case 'load'
				# update and unlock
				for a in blocks
					a.refresh!
					a.lock 0
			# done
			return true
		# create individual blocks
		blocks = [...(document.querySelectorAll '.sm-blocks.price-filter')]
		blocks = blocks.map (root) ->
			new Block root, state
		# }}}
		return state
	# }}}
	mPaginator = do -> # {{{
		# constructors
		Control = (block) !-> # {{{
			# data {{{
			@block     = block
			@lock      = null
			@lockType  = 0
			@rootCS    = getComputedStyle block.root
			@rootBoxCS = getComputedStyle block.rootBox
			@rangeCS   = getComputedStyle block.rangeBox
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
			@dragbox   = []
			@maxSpeed  = 10
			@brake     = 15
			@observer  = null # resize observer
			# }}}
			# handlers
			@keyDown = (e) !~> # {{{
				# check requirements
				if @lock or @block.locked or \
				   not @block.range or \
				   not @block.mode
					###
					return
				# check key-code
				switch e.code
				case <[ArrowLeft ArrowDown]>
					# fast-backward
					# get node
					a = if @block.gotoP
						then @block.gotoP.firstChild
						else null
					# start
					@lockType = 1
					@fast null, a, false
				case <[ArrowRight ArrowUp]>
					# fast-forward
					# get node
					a = if @block.gotoN
						then @block.gotoN.firstChild
						else null
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
				if not @block.locked and @block.mode and \
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
				if @lock or @block.locked or not @block.mode
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
				if @block.mode == 1 and \
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
				if @block.mode == 1 and \
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
				if @lock or @block.locked or @block.mode != 1 or \
				   not e.isPrimary or e.button or \
				   typeof e.offsetX != 'number'
					###
					return true
				# lock
				@lock = newPromise!
				@lockType = 2
				@block.focus!
				# cooldown
				await Promise.race [(delay 200), @lock]
				if not @lock.pending
					# prevent false startup
					@lock = null
					return true
				# set capture
				node = @block.rangeBox
				node.classList.add 'active', 'drag'
				if not node.hasPointerCapture e.pointerId
					node.setPointerCapture e.pointerId
				# PIXEL PERFECT:
				# calculate dragbox parameters
				# {{{
				# determine first-last page counts (excluding current)
				a = @block.range
				if (c = a.pages.length) > 1
					b = a.index
					c = c - a.index - 1
				else
					b = 0
				if a.first
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
				e.2 = parseFloat @rangeCS.getPropertyValue 'width'
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
				if @lock or @block.locked or not @block.mode
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
				# dynamic axis {{{
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
					@baseSz.2 = parseFloat (@rangeCS.getPropertyValue 'width')
				# update
				@currentSz.0 = w
				# }}}
				# static axis {{{
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
				if @block.flexy and @block.mode == 1
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
					if (d = a / state.data.1) <= b
						d = 0
					@currentSz.4 = d
					# update style only if required
					if c and not d
						@block.rangeBox.style.removeProperty '--page-size'
					else if d and (Math.abs (d - b)) > 0.1
						@block.rangeBox.style.setProperty '--page-size', d+'px'
				# }}}
			# }}}
		###
		Control.prototype = {
			attach: !-> # {{{
				# prepare
				B = @block
				R = B.range
				# initialize data
				# {{{
				# determine root pads
				a = [
					'padding-top'
					'padding-right'
					'padding-bottom'
					'padding-left'
				]
				for b,c in a
					@rootPads[c] = parseInt (@rootCS.getPropertyValue b)
				# determine base sizes
				@baseSz.0 = 0
				@baseSz.1 = parseInt (@rootCS.getPropertyValue '--height')
				@baseSz.2 = parseFloat (@rangeCS.getPropertyValue 'width')
				# determine range and page-buttons
				if R
					a = getComputedStyle R.pages[R.index]
					@baseSz.3 = parseFloat (a.getPropertyValue 'min-width')
					@baseSz.4 = 0
					if R.pages.length > 1
						a = if R.index > 0
							then 0
							else R.index + 1
						a = getComputedStyle R.pages[a]
						@baseSz.4 = parseFloat (a.getPropertyValue 'min-width')
				# }}}
				# attach event handlers
				# base
				# keyboard controls
				B.root.addEventListener 'keydown', @keyDown, true
				B.root.addEventListener 'keyup', @keyUp, true
				# mouse controls
				B.root.addEventListener 'click', @setFocus
				B.rootBox.addEventListener 'wheel', @wheel, true
				B.rootBox.addEventListener 'pointerenter', @hover
				B.rootBox.addEventListener 'pointerleave', @unhover
				# outer gotos
				# first-last
				if B.gotoF
					a = B.gotoF.firstChild
					a.addEventListener 'click', @goto
					a = B.gotoL.firstChild
					a.addEventListener 'click', @goto
				# prev-next
				if B.gotoP
					a = B.gotoP.firstChild
					a.addEventListener 'pointerdown', @fastBackward
					a.addEventListener 'pointerup', @fastStop
					a.addEventListener 'click', @goto
					a = B.gotoN.firstChild
					a.addEventListener 'pointerdown', @fastForward
					a.addEventListener 'pointerup', @fastStop
					a.addEventListener 'click', @goto
				# range
				if R
					# first-last
					if R.first
						a = R.first.firstChild
						a.addEventListener 'click', @goto
						a = R.last.firstChild
						a.addEventListener 'click', @goto
					# range gotos
					for a,b in R.buttons
						a.addEventListener 'click', @rangeGoto[b]
					# drag (current page & range box)
					a = R.buttons[R.index]
					a.addEventListener 'pointerdown', @dragStart
					B.rangeBox.addEventListener 'pointermove', @drag
					B.rangeBox.addEventListener 'pointerup', @dragStop
					# resize observer
					@observer = a = new ResizeObserver @resize
					a.observe B.root
			# }}}
			detach: !-> # {{{
				if a = @observer
					a.disconnect!
					@observer = null
			# }}}
			rangeGotoFunc: (i) -> (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check
				if @lock or @block.locked or not @block.mode
					return
				# determine page index
				if @block.mode == 1
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
				await Promise.race [(delay 200), @lock]
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
				@block.rangeBox.classList.add 'active'
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
						await Promise.race [(delay d), @lock]
					else if inc*b < @maxSpeed and --c == 0
						# accelerate
						b = b + inc
						c = @brake
				# release capture
				if id != null and node.hasPointerCapture id
					node.releasePointerCapture id if id != null
				node.parentNode.classList.remove 'active'
				@block.rangeBox.classList.remove 'active'
				# update global state
				if not @block.locked
					state.master.resolve state
					for b in blocks when b != @block
						b.refresh!
				# release lock and complete
				@lock.resolve!
				await delay 60 # omit click event
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
					b.focus! if b.mode == 2
					requestAnimationFrame !->
						a.resolve!
				# done
				return a
			# }}}
		}
		# }}}
		BlockRange = (box) !-> # {{{
			# create object shape
			# set nodes
			@pages   = a = [...(box.querySelectorAll '.page.x')]
			@buttons = a.map (a) -> a.firstChild
			@gap1    = box.querySelector '.gap.first'
			@gap2    = box.querySelector '.gap.last'
			@first   = box.querySelector '.page.first'
			@last    = box.querySelector '.page.last'
			# determine projected page index
			b = -1
			c = a.length
			while ++b < c
				if a[b].classList.contains 'current'
					break
			# set parameters
			@index   = b
			@current = a[b].firstChild
			@size    = if @first
				then c + 2
				else c
			# set state holders
			@nPages = (Array c).fill 0 # [0]*c
			@nGap1  = 0
			@nGap2  = 0
			@nFirst = 0
			@nLast  = 0
			@nCount = 0
		# }}}
		Block = (root, state) !-> # {{{
			# {{{
			# base container
			@root    = root
			@rootBox = rootBox = root.firstChild
			# outer gotos
			a = [...(root.querySelectorAll '.goto.a')]
			b = [...(root.querySelectorAll '.goto.b')]
			@gotoF = (a.length and a.0) or null
			@gotoL = (a.length and a.1) or null
			@gotoP = (b.length and b.0) or null
			@gotoN = (b.length and b.1) or null
			# range
			@rangeBox = a = root.querySelector '.range'
			@range    = (a and new BlockRange a) or null
			# controller
			@state  = state
			@locked = true
			@flexy  = rootBox.classList.contains 'flexy'
			@mode   = 0
			@ctrl   = new Control @
			# set event handlers and refresh
			@ctrl.attach!
			@refresh!
			# }}}
		Block.prototype =
			focus: !-> # {{{
				# set focus to the current node
				if not @locked and \
				   @range and (a = @range.current) and \
				   document.activeElement != a
					###
					a.focus!
			# }}}
			refresh: !-> # {{{
				# check range doesn't exist
				if not (R = @range)
					return
				# determine current state
				# {{{
				# prepare
				index  = @state.data.0
				count  = @state.data.1
				nCount = 0
				nPages = R.nPages.slice!fill 0
				nGap1  = 0
				nGap2  = 0
				nFirst = 0
				nLast  = 0
				# check
				if not count
					# empty
					mode    = 0
					current = null
					nCount  = R.size
					for a from R.index til nPages.length
						nPages[a] = 1
					nGap2 = 100
					nLast = 1
				else if count > R.size
					# dualgap
					mode    = 1
					current = R.buttons[R.index]
					nCount  = R.size
					# determine start position
					if (a = R.index - index) < 0
						# first page is visible,
						# calculate gap size
						nFirst = 1
						nGap1  = 0 - a - 1
						# full backward range
						a = 0
					# determine end position
					b = nPages.length - R.index - 1
					c = count - index - 2
					if b > c
						# forward range is bigger than required,
						# both last page and gap are hidden..
						# truncate range size
						b = R.index + c + 2
					else
						# last page is visible,
						# calculate gap size
						nLast = count
						nGap2 = c - b
						# full forward range
						b = nPages.length
					# set range numbers
					c = a - 1
					d = index - R.index + a
					while ++c < b
						nPages[c] = ++d
					# determine total gap
					if a = nGap1 + nGap2
						# calculate relative gap size (%)
						a = 100 * nGap1 / a
						# prevent edge case fails
						if a > 0 and a < 1
							a = 1
						else if a > 99 and a < 100
							a = 99
						else
							a = Math.round a
						# set
						nGap1 = a
						nGap2 = 100 - a
				else
					# nogap
					mode   = 2
					nCount = count
					# set first
					nFirst = a = (R.first and 1) or 0
					# set range numbers
					b = -1
					c = nPages.length
					while ++b < c and a < count
						nPages[b] = ++a
					# set last
					nLast = if R.last and a < count
						then count
						else 0
					# set current
					a = index + 1
					current = if a == nFirst
						then R.first.firstChild
						else if a == nLast
							then R.last.firstChild
							else R.buttons[(nPages.indexOf a)]
				# }}}
				# apply changes
				# {{{
				# operation mode
				if mode != @mode
					if not @mode
						@rootBox.classList.add 'v'
					if not mode
						@rootBox.classList.remove 'v'
					else if mode == 1
						@rangeBox.classList.remove 'nogap'
					else
						@rangeBox.classList.add 'nogap'
					@mode = mode
				# range capacity
				if R.nCount != nCount
					@rangeBox.style.setProperty '--count', nCount
					R.nCount = nCount
					# determine new size of the widget
					@root.classList.remove 'v'
					@ctrl.resize!
					@root.classList.add 'v'
				# first page
				if R.nFirst != nFirst
					if not R.nFirst
						R.first.classList.add 'v'
					else if not nFirst
						R.first.classList.remove 'v'
					R.nFirst = nFirst
				# first gap
				if R.nGap1 != nGap1
					if not R.nGap1
						R.gap1.classList.add 'v'
					else if not nGap1
						R.gap1.classList.remove 'v'
					R.gap1.style.flexGrow = R.nGap1 = nGap1
				# pages
				c = R.nPages
				for a,b in nPages when a != c[b]
					if not c[b]
						R.pages[b].classList.add 'v'
					else if not a
						R.pages[b].classList.remove 'v'
					R.buttons[b].textContent = c[b] = a
				# last gap
				if R.nGap2 != nGap2
					if not R.nGap2
						R.gap2.classList.add 'v'
					else if not nGap2
						R.gap2.classList.remove 'v'
					R.gap2.style.flexGrow = R.nGap2 = nGap2
				# last page
				if R.nLast != nLast
					if not R.nLast
						R.last.classList.add 'v'
					else if not nLast
						R.last.classList.remove 'v'
					R.last.firstChild.textContent = R.nLast = nLast
				# current page
				if R.current != current
					if R.current
						R.current.parentNode.classList.remove 'current'
					if current
						current.parentNode.classList.add 'current'
					R.current = current
				# }}}
				# done
			# }}}
			lock: ->> # {{{
				if not @locked
					# terminate activity
					if @ctrl.lock
						await @ctrl.lock.spin!
					# set lock
					@locked = true
					@rootBox.classList.remove 'v'
					if (R = @range) and R.current
						R.current.parentNode.classList.remove 'current'
						R.current = null
				# done
				return true
			# }}}
			unlock: !-> # {{{
				@rootBox.classList.add 'v'
				@locked = false
			# }}}
		# }}}
		# initialize
		# {{{
		# create group state
		state = new BlockState 'page', 1, (event, data) !->
			switch event
			case 'lock'
				# stop any interactions..
				for a in blocks
					a.lock!
			case 'change'
				# in case of any block active,
				# prevent current change
				for a in blocks
					if (a = a.ctrl.lock) and a.pending
						return false
			case 'load'
				# check first
				for a in blocks
					# continue interactions..
					a.unlock! if a.locked
					# in case of active block,
					# prevent self-refreshing..
					return true if a.ctrl.lock
				# update
				state.data.0 = data.pageIndex
				state.data.1 = data.pageCount
				for a in blocks
					a.refresh!
			# done
			return true
		# create widget's data
		state.data = [0, 0]
		# create individual blocks
		blocks = [...(document.querySelectorAll '.sm-blocks.paginator')]
		blocks = blocks.map (root) ->
			new Block root, state
		# }}}
		return state
	# }}}
	mOrderer = do -> # {{{
		# constructors
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
					state.data.0 = B.oList[a]
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
		Block = (root, state) !-> # {{{
			# containers
			@root    = root
			@rootBox = root.firstChild
			@variant = a = [...(root.querySelectorAll '.variant')]
			# controls
			@switch  = a.map (a) -> a.firstChild
			@select  = root.querySelector 'select'
			# state
			@oMap    = null
			@oList   = null
			@state   = state
			@locked  = true
			@current = ['', -1]
			@ctrl    = new Control @
			# set event handlers and refresh
			@ctrl.attach!
			@root.classList.add 'v'
		###
		Block.prototype =
			load: (options, current) !-> # {{{
				# check
				if @oMap = options
					# set options
					@oList = b = Object.getOwnPropertyNames options
					for a in b
						c = document.createElement 'option'
						c.textContent = options[a].0
						c.value = options[a].1
						@select.appendChild c
					# set state
					@state.data = current
				else
					# clear current options
					a = @oList.length
					b = @select
					while --a > 0
						b.removeChild b.options[a]
					@oList = null
				# done
				@refresh!
			# }}}
			refresh: !-> # {{{
				# get data
				a = @state.data
				b = @current
				# sync tag
				if a.0 != b.0
					# set controls
					if (c = @oList.indexOf a.0) != @select.selectedIndex
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
			unlock: !-> # {{{
				@rootBox.classList.add 'v'
				@locked = false
			# }}}
		# }}}
		# initialize
		# {{{
		# create common state
		state = new BlockState 'order', 0, (event, data) ->
			switch event
			case 'init'
				# load
				for a in blocks
					a.load data.orderOption, data.orderFilter
			case 'load'
				# update
				for a in blocks
					a.unlock! if a.locked
					a.refresh!
			# done
			return true
		# create individual blocks
		blocks = [...(document.querySelectorAll '.sm-blocks.orderer')]
		blocks = blocks.map (root) ->
			new Block root, state
		# }}}
		return state
	# }}}
	# initialize
	# {{{
	KING and KING.rule [
		mCategoryFilter
		mPriceFilter
		mPaginator
		mOrderer
	]
	# }}}
	return await KING
###
