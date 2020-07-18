"use strict"
smBlocks = do !->>
	# TODO: paginator lock
	# TODO: orderer
	# TODO: expanded paginator page enlargement (when count is low)
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
	BlockState = (name, handler) !-> # {{{
		@name   = name
		@event  = handler
		@data   = null
		@master = null
		@ready  = false
	###
	BlockState.prototype = {
		set: (data) !->
			@data = data
			@master.resolve @
	}
	# }}}
	# widgets
	smProducts = do -> # (singleton) {{{
		# prepare
		# base {{{
		# get container
		if not root = document.querySelector '#sm-products'
			return null
		# get grid
		if not grid = root.querySelector '.main'
			return null
		# create control vars
		gridList    = [...grid.children]
		gridControl = []
		gridLock    = null
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
			cooldown = 400  # update timeout
			state = {
				first: true   # first loader run
				initiator: '' # update origin
				dirty: 0      # resolved-in-process flag
				total: 0      # items in the set
				count: 0      # displayed items
				pageCount: 0  # calculated from total/count
				pageIndex: 0  # current page number
			}
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
				func: 'products'
				limit: gridList.length
				offset: 0
				order: 'default'
				category: null
			}
			# }}}
			setState = (s) !-> # {{{
				console.log 'new state arrived!'
				switch state.initiator = s.name
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
					req.offset = state.pageIndex = 0
					# }}}
				case 'page'
					# {{{
					# set new page index and
					# determine first record offset
					state.pageIndex = s.data.0
					req.offset = state.pageIndex * req.limit
					# }}}
			# }}}
			unloadItems = !-> # {{{
				# check
				if not (c = state.count)
					return
				# discard items in the reverse order
				while --c >= 0
					gridList[c].cls!
				# reset
				state.count = 0
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
					setState data if data
					# check
					if p.pending
						# resolve clean
						p.pending = false
						r!
					else if not state.dirty
						# set dirty
						++state.dirty
						# terminate fetcher
						res.cancel! if res
				# done
				return p
			# }}}
			return ->>
				# check
				if state.dirty
					# reset everything
					state.dirty = 0
					unloadItems!
					# to guard against excessive dirty loads
					# caused by multiple user actions,
					# it's important to do a short cooldown..
					await delay cooldown
				else
					# set master lock
					gridLock := newMasterPromise!
					for c in gridControl
						c.master = gridLock
					# check
					if state.first
						# first load is instant
						gridLock.resolve!
						state.first = false
					else
						# wait for the update
						await gridLock
						# unload everything
						unloadItems!
				# multiple updates may not squeeze in here,
				# check it and restart early..
				if state.dirty
					return true
				# new update arrived,
				# dispatch change event before processing..
				for c in gridControl when c.ready
					if not (c.event 'change', state)
						# some controller is about to change again,
						# dont rush, just restart
						return true
				# start fetching
				console.log 'fetching items..'
				a = await (res := iFetch req)
				# cleanup
				res := null
				# check the result
				if a instanceof Error
					return if a.id == 4
						then true   # dirty update, cancelled
						else false  # fatal failure
				# get total items count
				if (state.total = await a.readInt!) == null
					a.cancel!
					return false
				# determine count of displayed items
				b = gridList.length
				state.count = if b > state.total
					then state.total
					else if (c = state.total - req.offset) < b
						then c
						else b
				# determine count of pages
				state.pageCount = Math.ceil (state.total / b)
				# base parameters loaded,
				# dispatch init event before reading items..
				for c in gridControl
					# execute callback
					c.event 'init', state
					# set ready
					if not c.ready
						c.ready = true
				# async loop
				c = -1
				while ++c < state.count and not state.dirty
					# get item data
					if (b = await a.readJSON!) == null
						a.cancel!
						return false
					# apply
					gridList[c].set b
				# check the loop aborted
				if c != state.count
					# fix display count
					state.count = c
				else
					# satisfy chrome browser (2020-04),
					# as it produces unnecessary console error
					await a.read!
				# complete
				a.cancel!
				return true
		# }}}
		# constructors
		Block = (box) !-> # {{{
			@box  = box
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
				a = new Block node
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
				a = new Block node
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
				c = data.currency
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
					if data.currency.4
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
				a = new Block node
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
					x = smCart.get data.id
					if s.count == 0 or (x and s.count <= x.quantity)
						e.disabled = true
					# create event handler and
					# store it for later removal
					c[i] = f = (a) !->>
						# prepare
						a.preventDefault!
						e.disabled = true
						# add simple single product to cart
						if not (a = await smCart.add data.id)
							return
						# reload cart items and
						# check if more items may be added
						if not await smCart.load!
							return
						x = smCart.get data.id
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
				a = new Block node
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
		# create api
		return
			resize: gridResizer
			load: do -> # {{{
				# TODO
				started = false
				active  = false
				return ->>
					# check
					if started
						# unleash loader
						gridLock.resolve! if gridLock
						# done
						return true
					# lock
					started := true
					# activate
					if not active
						# construct grid items
						gridList := gridList.map (a) -> newItem a
						# force first resize
						gridResizer!
						# remove class
						root.classList.remove 'inactive'
						active := true
					# loop forever
					loop
						if not await gridLoader!
							# ...
							console.log 'FATAL ERROR'
							break
					# unlock
					return started := false
			# }}}
			add: (s) !-> # {{{
				# append control
				gridControl[*] = s
			# }}}
		###
	# }}}
	smCart = do -> # (singleton) {{{
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
	smCategoryFilter = do -> # {{{
		# constructors
		Block = (root) !-> # {{{
			# {{{
			# create object shape
			@root  = root
			@op    = root.dataset.op
			@index = 0
			@item  = item = {} # all
			@sect  = sect = {} # parents
			# initialize
			# create items map
			list = [...root.querySelectorAll '.item']
			for a in list
				# set item
				b = new Item @, a
				item[b.id] = b
				# set section
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
			# }}}
		Block.prototype =
			init: (index) !-> # {{{
				# create block's data
				@index = index
				state.data[index] = [@op, []]
				# iterate items
				for a of @item
					# get the item
					item = @item[a]
					# attach event handlers
					item.events.attach!
				# activate
				@root.classList.remove 'inactive'
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
				state.master.resolve state
				# done
			# }}}
		# }}}
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
		# initialize
		# {{{
		# create common state
		state = new BlockState 'category', (event, data) ->
			switch event
			case 'init'
				if not state.ready
					# initialize once
					state.data = []
					blocks.forEach (a, b) !->
						a.init b
			# done
			return true
		# create individual blocks
		blocks = [...(document.querySelectorAll '.sm-category-filter')]
		blocks = blocks.map (root) -> new Block root
		# }}}
		# done
		return state
	# }}}
	smPaginator = do -> # {{{
		# constructors
		Control = (block) !-> # {{{
			# create object shape
			@block     = block
			@lock      = null
			@lockType  = 0
			@rootCS    = getComputedStyle block.root
			@rootBoxCS = getComputedStyle block.rootBox
			@rootPads  = [0, 0, 0, 0]
			@baseSz    = [0, 0]
			@currentSz = [0, 0]
			@pageSz    = [0, 0]
			@dragbox   = []
			@maxSpeed  = 10
			@brake     = 15
			# create bound handlers
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
				# hover
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
				# capture pointer
				node = @block.rangeBox
				node.classList.add 'active', 'drag'
				if not node.hasPointerCapture e.pointerId
					node.setPointerCapture e.pointerId
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
				# calculate drag area sizes
				a   = @pageSz
				d   = @dragbox
				d.0 = a.0 + b * a.1
				d.1 = d.0 / (b + 1)
				d.0 = d.0 - d.1
				d.1 = d.1 / 2
				d.4 = a.0 + c * a.1
				d.3 = d.4 / (c + 1)
				d.4 = d.4 - d.3
				d.3 = d.3 / 2
				d.2 = node.clientWidth - d.0 - d.1 - d.3 - d.4
				# drag area page counts
				d.5 = b
				d.7 = c
				d.6 = state.data.1 - d.5 - d.7 - 2 # >0
				# }}}
				# wait released
				a = state.data.0
				await @lock
				@lock = null
				# release capture
				if node.hasPointerCapture e.pointerId
					node.releasePointerCapture e.pointerId
				node.classList.remove 'active', 'drag'
				# update global state
				if a != state.data.0
					state.master.resolve state
					for a in blocks when a != @block
						a.refresh!
				# done
				return true
			# }}}
			@drag = (e) !~> # {{{
				# fulfil event
				e.preventDefault!
				e.stopPropagation!
				# check
				if not @lock or @lockType != 2
					return
				# prepare
				d = @dragbox
				c = state.data.1
				# calculate page index
				if (b = e.offsetX) <= 0
					# out of first
					a = 0
				else if b <= d.0
					# first
					a = (b*d.5 / d.0) .|. 0
				else if (b -= d.0) <= d.1
					# first-end
					a = d.5
				else if (b -= d.1) <= d.2
					# middle
					a = d.5 + 1 + (b*d.6 / d.2) .|. 0
				else if (b -= d.2) <= d.3
					# last-end
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
				if @lock and @lockType == 2
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
			# initialize resizer
			@resize   = @resizeFunc!
			@observer = new ResizeObserver @resize
		###
		Control.prototype = {
			attach: !-> # {{{
				# prepare
				B = @block
				R = B.range
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
					# resizer
					@observer.observe B.root
			# }}}
			detach: !-> # {{{
				# range
				if R
					# resizer
					@observer.disconnect!
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
			resizeFunc: -> # {{{
				# determine root pads
				pads = [
					'padding-top'
					'padding-right'
					'padding-bottom'
					'padding-left'
				]
				for a,b in pads
					@rootPads[b] = parseInt (@rootCS.getPropertyValue a)
				# determine page container sizes (current & normal)
				a   = @block.range
				b   = @pageSz
				cs0 = getComputedStyle a.pages[a.index]
				b.0 = parseFloat (cs0.getPropertyValue 'min-width')
				cs1 = null
				if a.pages.length > 1
					cs1 = if a.index > 0
						then 0
						else a.index + 1
					cs1 = getComputedStyle a.pages[cs1]
					b.1 = parseFloat (cs1.getPropertyValue 'min-width')
				# determine initial static axis size
				@baseSz.1 = parseInt (@rootCS.getPropertyValue '--height')
				# create resize handler
				return (e) !~>
					# operate on dynamic axis
					# check mode
					if e
						# observed
						# get current
						e = e.0.contentRect.width
					else
						# forced
						# determine current
						a = @rootPads
						a = a.1 + a.3
						if (e = @block.root.clientWidth - a) < 0
							e = 0
						# determine base
						@baseSz.0 = parseFloat (@rootBoxCS.getPropertyValue 'width')
					# update current
					@currentSz.0 = e
					# determine deviation from the base
					if (e = e / @baseSz.0) > 0.98
						e = 1
					# operate on static axis
					# determine ideal
					a = e * @baseSz.1
					# compare against current
					if (Math.abs (a - @currentSz.1)) > 0.1
						# update current
						@block.root.style.setProperty '--height', a+'px'
						@currentSz.1 = a
						# update page container sizes
						a   = @pageSz
						a.0 = parseFloat (cs0.getPropertyValue 'min-width')
						a.1 = parseFloat (cs1.getPropertyValue 'min-width')
					# done
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
				@block.rootBox.classList.add 'active'
				node.parentNode.classList.add 'fast'
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
				# update global state
				state.master.resolve state
				for b in blocks when b != @block
					b.refresh!
				# release capture
				if id != null and node.hasPointerCapture id
					node.releasePointerCapture id if id != null
				node.parentNode.classList.remove 'fast'
				@block.rootBox.classList.remove 'active'
				# release lock
				await delay 100
				@lock = null
				# complete
				@block.focus!
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
		Block = (root) !-> # {{{
			# {{{
			# create object shape
			# base container
			@root    = root
			@rootBox = root.firstChild
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
			@locked = false
			@mode   = 0
			@ctrl   = new Control @
			# }}}
		Block.prototype =
			init: !-> # {{{
				# get count
				c = state.data.1
				# set controller
				if c and not @mode
					@ctrl.attach!
				else if not c and @mode
					@ctrl.detach!
				# done
				@refresh!
			# }}}
			focus: !-> # {{{
				# set focus to the current node
				if not @locked and @range and @range.current
					@range.current.focus!
			# }}}
			refresh: !-> # {{{
				# check
				if R = @range
					# update range
					# prepare
					index  = state.data.0
					count  = state.data.1
					nPages = R.nPages.slice!fill 0
					nGap1  = 0
					nGap2  = 0
					nFirst = 0
					nLast  = 0
					nCount = 0
					# determine current state
					# {{{
					if not count
						# empty
						mode    = 0
						current = null
						nCount  = 0
					else if count > R.size
						# flexy (with gaps)
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
						# static (no gaps)
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
							@root.classList.remove 'inactive'
						if not mode
							@rootBox.classList.remove 'v'
							@root.classList.add 'inactive'
						else if mode == 1
							@rangeBox.classList.remove 'nogaps'
						else
							@rangeBox.classList.add 'nogaps'
						@mode = mode
					# range capacity
					if R.nCount != nCount
						@rangeBox.style.setProperty '--count', nCount
						R.nCount = nCount
						# re-calculate range size
						if nCount
							@rootBox.classList.remove 'v'
							@ctrl.resize!
							@rootBox.classList.add 'v'
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
					if (c = @last) and x.last != y.last
						c.classList.toggle 'v', !!x.last
						c.firstChild.textContent = x.last
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
				else
					# range doesn't exist,
					# always static
					mode = 2
				# done
			# }}}
			lock: !-> # {{{
				if not @locked
					@locked = true
					@rootBox.classList.add 'locked'
					if (R = @range) and R.current
						R.current.parentNode.classList.remove 'current'
						R.current = null
			# }}}
			unlock: !-> # {{{
				if @locked
					@rootBox.classList.remove 'locked'
					@locked = false
			# }}}
		# }}}
		# initialize
		# {{{
		# create common state
		state = new BlockState 'page', (event, data) !->
			switch event
			case 'change'
				# check any block is active/locked
				for a in blocks
					if (a = a.ctrl.lock) and a.pending
						# another update will arrive soon,
						# prevent current change
						return false
				# check update origin and
				# lock all blocks until initialized
				if data.initiator != 'page'
					for a in blocks
						a.lock!
			case 'init'
				if not state.ready
					# initialize once
					state.data = [data.pageIndex, data.pageCount]
					for a in blocks
						a.init!
				else if state.data.0 != data.pageIndex or \
				        state.data.1 != data.pageCount
					# update
					state.data.0 = data.pageIndex
					state.data.1 = data.pageCount
					for a in blocks
						a.unlock! if a.locked
						a.refresh!
			# done
			return true
		# create individual blocks
		blocks = [...(document.querySelectorAll '.sm-paginator')]
		blocks = blocks.map (root) -> new Block root
		# }}}
		return state
	# }}}
	smOrderer = do -> # {{{
		# constructors
		Block = (root) !-> # {{{
			# {{{
			# create object shape
			@root = root
			# }}}
		Block.prototype =
			init: !-> # {{{
				true
			# }}}
			refresh: !-> # {{{
				true
			# }}}
		# }}}
		# initialize
		# {{{
		# create common state
		state = new BlockState 'order', (event, data) ->
			switch event
			case 'init'
				true
			case 'change'
				true
			# done
			return true
		# create individual blocks
		blocks = [...(document.querySelectorAll '.sm-order')]
		blocks = blocks.map (root) -> new Block root
		# }}}
		return state
	# }}}
	smSizer = do -> # {{{
		# constructors
		Block = (root) !-> # {{{
			@root = root
		Block.prototype =
			refresh: (data) !->
				# update root
				@root.style.setProperty '--sm-width',  data.width+'px'
				@root.style.setProperty '--sm-height', data.height+'px'
		# }}}
		# initialize
		# {{{
		# create common state
		state = new BlockState 'sizer', (event, data) ->
			switch event
			case 'resize'
				blocks.forEach (b) !->
					b.refresh data
			# done
			return true
		# create individual blocks
		blocks = [...(document.querySelectorAll '.sm-sizer')]
		blocks = blocks.map (root) -> new Block root
		# }}}
		return state
	# }}}
	# initialize
	# {{{
	if smProducts
		# load helpers
		if not await smCart.load!
			return null
		# assemble widgets
		if smCategoryFilter
			smProducts.add smCategoryFilter
		if smPaginator
			smProducts.add smPaginator
		if smSizer
			smProducts.add smSizer
		# start main loader
		smProducts.load!
	# }}}
	# done
	return smProducts
###
