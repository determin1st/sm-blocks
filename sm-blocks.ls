"use strict"
SHOP = (url, cfg = null) -> w3ui.catalog {
	brand: 'sm-blocks'
	root: document.documentElement
	apiURL: url
	config: cfg
	debug: true
	s:
		productCard: do -> # {{{
			init  = w3ui.promise!
			sizes = null # dimensions of the card elements
			template = w3ui.template !-> # {{{
				/*
				<div>
					<div class="a">
						<div class="image">
							<img alt="product">
							<svg preserveAspectRatio="none" fill-rule="evenodd" clip-rule="evenodd" viewBox="0 0 270.92 270.92">
								<path fill-rule="nonzero" d="M135.46 245.27c-28.39 0-54.21-10.93-73.72-28.67L216.6 61.74c17.74 19.51 28.67 45.33 28.67 73.72 0 60.55-49.26 109.81-109.81 109.81zm0-219.62c29.24 0 55.78 11.56 75.47 30.25L55.91 210.93c-18.7-19.7-30.25-46.23-30.25-75.47 0-60.55 49.26-109.81 109.8-109.81zm84.55 27.76c-.12-.16-.18-.35-.33-.5-.1-.09-.22-.12-.32-.2-21.4-21.7-51.09-35.19-83.9-35.19-65.03 0-117.94 52.91-117.94 117.94 0 32.81 13.5 62.52 35.2 83.91.08.09.11.22.2.31.14.14.33.2.49.32 21.24 20.63 50.17 33.4 82.05 33.4 65.03 0 117.94-52.91 117.94-117.94 0-31.88-12.77-60.8-33.39-82.05z"/>
							</svg>
						</div>
					</div>
					<div class="b">
						<div class="title"><div><span></span></div></div>
						<div class="price">
							<div class="currency"><span></span></div>
							<div class="value a">
								<div class="integer"><span></span></div>
								<div class="fraction"><span></span><span></span></div>
							</div>
							<div class="value b">
								<div class="integer"><span></span></div>
								<div class="fraction"><span></span><span></span></div>
							</div>
						</div>
					</div>
					<div class="c">
						<div class="actions"></div>
					</div>
				</div>
				*/
			# }}}
			area = # {{{
				image: do -> # {{{
					Item = (block) !->
						@block  = block
						@box    = box = block.rootBox.querySelector '.image'
						@image  = box.firstChild
						@loaded = false
						@load   = ~>> # {{{
							# check image successfully loaded and valid
							if not @image.complete or \
							   (w = @image.naturalWidth) < 2 or \
							   (h = @image.naturalHeight) < 2
								###
								return false
							# wait variables initialized
							await init
							# get container size
							cw = sizes.3
							ch = sizes.0
							# determine optimal display
							if w >= h
								# stretch by width
								a  = h / w
								b  = cw - w
								w += b # 100%
								h += a*b
								# check overflow
								if (b = h - ch) > 0
									# reduce width
									a = w / h
									w = 100*(w - a*b)/cw
									@image.style.maxWidth = w+'%'
								else
									# reduce height
									h = 100*(h / ch)
									@image.style.maxHeight = h+'%'
							else
								# stretch by height
								a  = w / h
								b  = ch - h
								w += a*b
								h += b
								# check overflow
								if (b = w - cw) > 0
									# reduce height
									a = h / w
									h = 100*(h - a*b)/ch
									@image.style.maxHeight = h+'%'
								else
									# reduce width
									w = 100*(w / cw)
									@image.style.maxWidth = w+'%'
							# done
							@box.classList.add 'v'
							@loaded = true
							return true
						# }}}
					###
					Item.prototype =
						set: (data) !-> # {{{
							# clear
							if @loaded
								@image.removeEventListener 'load', @load
								@box.classList.remove 'v'
								@image.removeAttribute 'style'
								@image.src = ''
								@image.srcset = ''
								@loaded = false
							# set
							if data and data.image
								@image.addEventListener 'load', @load
								for a,b of data.image
									@image[a] = b
						# }}}
					###
					return Item
				# }}}
				title: do -> # {{{
					eBreakMarkers = /\s+([\\\|/.]){1}\s+/
					Item = (block) !->
						@block = block
						@box   = box = block.rootBox.querySelector '.title'
						@title = box = box.firstChild
						@label = box.firstChild
					###
					Item.prototype =
						set: (data) !-> # {{{
							if data and (a = data.title)
								# set
								# TODO: DELETE
								@label.textContent = data.index
								return
								# break title into lines
								a = a.replace eBreakMarkers, "\n"
								# TODO: check it fits the container height and
								# TODO: cut string if required
								# set
								@label.textContent = a
							else
								# clear
								@label.textContent = ''
						# }}}
					###
					return Item
				# }}}
				price: do -> # {{{
					eBreakThousands = /\B(?=(\d{3})+(?!\d))/
					eNotNumber = /[^0-9]/
					Item = (block) !->
						@block    = block
						@box      = box = block.rootBox.querySelector '.price'
						@currency = w3ui.queryChild box, '.currency'
						@boxes    = box = [
							w3ui.queryChild box, '.value.a' # current
							w3ui.queryChild box, '.value.b' # regular
						]
						@values   = [
							box.0.children.0 # integer
							box.0.children.1 # fraction
							box.1.children.0
							box.1.children.1
						]
						@money    = [0,0] # integers (no fraction)
					###
					Item.prototype =
						set: (data) !-> # {{{
							if data and (data = data.price)
								# set
								# prepare
								# get global config
								C = @block.master.group.config.currency
								# split numbers [regular,current] into integer and fraction
								b = data.0.split eNotNumber, 2
								a = data.1.split eNotNumber, 2
								# truncate fraction point
								a.1 = if a.1
									then (a.1.substring 0, C.3).padEnd C.3, '0'
									else '0'.repeat C.3
								b.1 = if b.1
									then (b.1.substring 0, C.3).padEnd C.3, '0'
									else '0'.repeat C.3
								# determine money values
								c = @money
								d = +('1' + ('0'.repeat C.3))
								c.0 = d*(+(a.0)) + (+a.1)
								c.1 = d*(+(b.0)) + (+b.1)
								# separate integer thousands
								if C.2
									a.0 = a.0.replace eBreakThousands, C.2
									b.0 = b.0.replace eBreakThousands, C.2
								# set values
								@currency.firstChild.textContent = C.0
								c = @values
								c.0.firstChild.textContent = a.0
								c.1.firstChild.textContent = C.1
								c.1.lastChild.textContent  = a.1
								c.2.firstChild.textContent = b.0
								c.3.firstChild.textContent = C.1
								c.3.lastChild.textContent  = b.1
								# set styles
								# price difference
								c = @money
								d = if c.0 == c.1
									then 'equal'
									else if c.0 > c.1
										then 'lower'
										else 'higher'
								@box.classList.add d
								# currency sign position
								d = if C.4
									then 'right'
									else 'left'
								@box.classList.add d, 'v'
								###
							else
								# clear
								@box.className = 'price'
						# }}}
					###
					return Item
				# }}}
				actions: do -> # {{{
					tCartIcon = w3ui.template !-> # {{{
						/*
						<svg viewBox="0 0 48 48" preserveAspectRatio="none">
							<circle class="a" cx="13" cy="40" r="4"/>
							<circle class="a" cx="38" cy="40" r="4"/>
							<polygon class="a" points="33,38 18,38 16,36 35,36 "/>
							<polygon class="b" points="43,34 10,35 4,9 0,9 0,5 7,5 13,31 40,30 43.5,14 47.5,14 "/>
							<polygon class="c" points="39,29 14,30 10,12 42.5,14 "/>
							<text class="d" x="26.5" y="29" text-anchor="middle">+</text>
							<text class="e" x="26" y="28" text-anchor="middle">99</text>
						</svg>
						*/
					# }}}
					Item = (block, cfg) !->
						@block   = block
						@box     = box = block.rootBox.querySelector '.actions'
						@buttons = btn = w3ui.append box, [
							w3ui.blocks.button {
								name: 'add'
								html: tCartIcon
								hint: cfg.locale.hint.0
								event:
									click: [@addToCart, @]
							}
							w3ui.blocks.button {
								name: 'open'
								label: cfg.locale.label.1
								event:
									click: [@openDetails, block]
							}
						]
						@cartNum = btn.0.root.querySelector 'text.e'
					###
					Item.prototype =
						set: (data) !-> # {{{
							###
							# prepare
							a = @block.master.group.config.cart
							b = @buttons
							# check
							if data
								# enable
								b.1.lock !data.link
								b.0.lock (data.stock.status != 'instock' or not data.stock.count)
								# set number of items in the cart
								@cartNum.textContent = c = if (c = a[data.id]) and c.count
									then ''+c.count
									else ''
								b.0.root.classList.toggle 'x', !!c
							else
								# disable
								b.1.lock true
								b.0.lock true
						# }}}
						addToCart: (I, e) ~>> # {{{
							# TODO: miniCart block
							# select click mode
							return 1 if not e
							# update cart data
							a = I.block.master.group.config.cart
							b = I.block.data
							if c = a[b.id]
								c.count += 1
							else
								a[b.id] = {count: 1}
							# refresh view
							I.set b
							# send request
							c = await goFetch {
								action: 'a_CartAdd'
								params: [b.id, 1]
							}
							# check
							if c instanceof Error
								# restore previous view
								a[b.id].count -= 1
								I.set b
								return false
							# update total
							a.total.count++
							# refresh mini-cart
							CART.set a.total.count if CART
							# done
							return true
						# }}}
						openDetails: (B, e) ~>> # {{{
							# TODO: productDetails block
							# select click mode
							return 1 if not e
							# naviagate the link
							window.location.assign B.data.link
							# done
							return false
						# }}}
						getProduct: (id) -> # {{{
							# check
							if not data
								return null
							# search
							for a,b of data when b.product_id == id
								return b
							# not found
							return null
						# }}}
					###
					return Item
				# }}}
			# }}}
			Items = (block) !-> # {{{
				cfg = block.master.group.config
				for a of area
					@[a] = new area[a] block, cfg
			# }}}
			Block = (master) !-> # {{{
				# construct
				# create root
				R = document.createElement 'div'
				R.className = 'item'
				R.innerHTML = template
				# create placeholder (reuse master)
				R.appendChild (master.root.children.1.cloneNode true)
				# create object shape
				@master  = master
				@root    = R
				@rootBox = R.firstChild
				@items   = new Items @
				@data    = null
			###
			Block.prototype =
				set: (data) -> # {{{
					# check
					if data
						if not @data or @data.id != data.id
							# set stock status
							a = data.stock.status
							if @data and (b = @data.stock.status) != a
								c = (b == 'instock' and 's1') or 's0'
								@root.classList.remove c
							if not @data or b != a
								c = (a == 'instock' and 's1') or 's0'
								@root.classList.add c
							# set items
							for a,a of @items
								a.set data
							# set self
							@root.classList.add 'x' if not @data
							@data = data
					else if @data
						# clear stock status
						a = @data.stock.status
						c = (a == 'instock' and 's1') or 's0'
						@root.classList.remove c
						# clear items
						for a,a of @items
							a.set!
						# clear self
						@root.classList.remove 'x'
						@data = null
					# done
					return true
				# }}}
				refresh: !-> # {{{
					# TODO: refactor
					@items.actions.set @data
				# }}}
			# }}}
			return (m) -> # {{{
				# consruct
				m = new Block m
				# attach to the master
				m.master.rootBox.appendChild m.root
				# initialize last
				if init.pending
					# read container styles
					s = getComputedStyle m.root
					sizes := s = [
						parseInt (s.getPropertyValue '--a-size')
						parseInt (s.getPropertyValue '--b-size')
						parseInt (s.getPropertyValue '--c-size')
						parseInt (s.getPropertyValue 'padding-left')
						parseInt (s.getPropertyValue 'padding-right')
						parseInt (s.getPropertyValue 'padding-top')
						parseInt (s.getPropertyValue 'padding-bottom')
					]
					# determine item size
					c = m.master.resizer.sizes
					s.3 = c.0 - s.3 - s.4 # width
					s.4 = c.1 - s.5 - s.6 # height
					# determine section sizes
					s.0 = s.4 * s.0 / 100
					s.1 = s.4 * s.1 / 100
					s.2 = s.4 * s.2 / 100
					# complete
					s.length = 5
					init.resolve!
				# done
				return m
			# }}}
		# }}}
		productPrice: do -> # {{{
			template = w3ui.template !-> # {{{
				/*
				<div class="currency"><span></span></div>
				<div class="value a">
					<div class="integer"><span></span></div>
					<div class="fraction"><span></span><span></span></div>
				</div>
				<div class="value b">
					<div class="integer"><span></span></div>
					<div class="fraction"><span></span><span></span></div>
				</div>
				*/
			# }}}
			price = do -> # {{{
				eBreakThousands = /\B(?=(\d{3})+(?!\d))/
				eNotNumber = /[^0-9]/
				Item = (block) !->
					@block    = block
					@box      = box = block.rootBox.querySelector '.price'
					@currency = w3ui.queryChild box, '.currency'
					@boxes    = box = [
						w3ui.queryChild box, '.value.a' # current
						w3ui.queryChild box, '.value.b' # regular
					]
					@values   = [
						box.0.children.0 # integer
						box.0.children.1 # fraction
						box.1.children.0
						box.1.children.1
					]
					@money    = [0,0] # integers (no fraction)
				###
				Item.prototype =
					set: (data) !-> # {{{
						if data and (data = data.price)
							# set
							# prepare
							# get global config
							C = @block.master.group.config.currency
							# split numbers [regular,current] into integer and fraction
							b = data.0.split eNotNumber, 2
							a = data.1.split eNotNumber, 2
							# truncate fraction point
							a.1 = if a.1
								then (a.1.substring 0, C.3).padEnd C.3, '0'
								else '0'.repeat C.3
							b.1 = if b.1
								then (b.1.substring 0, C.3).padEnd C.3, '0'
								else '0'.repeat C.3
							# determine money values
							c = @money
							d = +('1' + ('0'.repeat C.3))
							c.0 = d*(+(a.0)) + (+a.1)
							c.1 = d*(+(b.0)) + (+b.1)
							# separate integer thousands
							if C.2
								a.0 = a.0.replace eBreakThousands, C.2
								b.0 = b.0.replace eBreakThousands, C.2
							# set values
							@currency.firstChild.textContent = C.0
							c = @values
							c.0.firstChild.textContent = a.0
							c.1.firstChild.textContent = C.1
							c.1.lastChild.textContent  = a.1
							c.2.firstChild.textContent = b.0
							c.3.firstChild.textContent = C.1
							c.3.lastChild.textContent  = b.1
							# set styles
							# price difference
							c = @money
							d = if c.0 == c.1
								then 'equal'
								else if c.0 > c.1
									then 'lower'
									else 'higher'
							@box.classList.add d
							# currency sign position
							d = if C.4
								then 'right'
								else 'left'
							@box.classList.add d, 'v'
							###
						else
							# clear
							@box.className = 'price'
					# }}}
				###
				return Item
			# }}}
			Block = (master) !-> # {{{
				# create object shape
				@master = master
				@root   = R
				@items  = new Items @
				@data   = null
			###
			Block.prototype =
				set: (data) -> # {{{
					# check
					if data
						if not @data or @data.id != data.id
							# set stock status
							a = data.stock.status
							if @data and (b = @data.stock.status) != a
								c = (b == 'instock' and 's1') or 's0'
								@root.classList.remove c
							if not @data or b != a
								c = (a == 'instock' and 's1') or 's0'
								@root.classList.add c
							# set items
							for a,a of @items
								a.set data
							# set self
							@root.classList.add 'x' if not @data
							@data = data
					else if @data
						# clear stock status
						a = @data.stock.status
						c = (a == 'instock' and 's1') or 's0'
						@root.classList.remove c
						# clear items
						for a,a of @items
							a.set!
						# clear self
						@root.classList.remove 'x'
						@data = null
					# done
					return true
				# }}}
			# }}}
			return (m) -> # {{{
				# construct
				# create root
				R = document.createElement 'div'
				R.className = 'sm-product-price'
				R.innerHTML = template
				# create placeholder (reuse master)
				R.appendChild (master.root.children.1.cloneNode true)
				# done
				return new Block m, R
			# }}}
		# }}}
	m:
		route:
			'main-menu': do -> # TODO {{{
				# {{{
				tRootBox = w3ui.template !-> # {{{
					/*
					<svg class="shield" viewBox="0 0 100 100" preserveAspectRatio="none">
						<polygon class="a" points="0,8 0,0 100,100 100,0 "/>
						<polygon class="b" points="0,0 0,8 100,8 100,0 "/>
					</svg>
					*/
				# }}}
				tItem = w3ui.template !-> # {{{
					/*
					{{lineA}}
					<div class="label">{{name}}</div>{{arrow}}
					{{lineB}}
					*/
				# }}}
				tArrow = w3ui.template !-> # {{{
					/*
					<svg class="arrow" preserveAspectRatio="none" viewBox="0 0 48 48">
						<polygon class="b" points="24,32 34,17 36,16 24,34 "/>
						<polygon class="b" points="24,34 12,16 14,17 24,32 "/>
						<polygon class="b" points="34,17 14,17 12,16 36,16 "/>
						<polygon class="a" points="14,17 34,17 24,32 "/>
					</svg>
					*/
				# }}}
				tLineA = w3ui.template !-> # {{{
					/*
					<div class="line a">
						<svg class="a" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,40 48,28 48,36 0,48 "/>
							<polygon class="b" points="0,0 48,0 48,28 0,40 "/>
						</svg>
						<svg class="b" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,28 48,28 48,36 0,36 "/>
							<polygon class="b" points="0,0 48,0 48,28 0,28 "/>
						</svg>
						<svg class="a" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,28 48,40 48,48 0,36 "/>
							<polygon class="b" points="0,0 48,0 48,40 0,28 "/>
						</svg>
					</div>
					*/
				# }}}
				tLineB = w3ui.template !-> # {{{
					/*
					<div class="line b">
						<svg class="a" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,0 48,12 48,20 0,8 "/>
							<polygon class="b" points="0,8 48,20 48,48 0,48 "/>
						</svg>
						<svg class="b" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,12 48,12 48,20 0,20 "/>
							<polygon class="b" points="0,20 48,20 48,48 0,48 "/>
						</svg>
						<svg class="a" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,12 48,0 48,8 0,20 "/>
							<polygon class="b" points="0,20 48,8 48,48 0,48 "/>
						</svg>
					</div>
					*/
				# }}}
				tSep = w3ui.template !-> # {{{
					/*
					<div class="line b">
						<svg class="a" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,0 48,12 48,20 0,8 "/>
							<polygon class="b" points="0,8 48,20 48,48 0,48 "/>
						</svg>
						<svg class="b" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,12 48,12 48,20 0,20 "/>
							<polygon class="b" points="0,20 48,20 48,48 0,48 "/>
						</svg>
						<svg class="a" preserveAspectRatio="none" viewBox="0 0 48 48">
							<polygon class="a" points="0,12 48,0 48,8 0,20 "/>
							<polygon class="b" points="0,20 48,8 48,48 0,48 "/>
						</svg>
					</div>
					*/
				# }}}
				fOrder = (a, b) -> # {{{
					return if a.data.order < b.data.order
						then -1
						else if a.data.order == b.data.order
							then 0
							else 1
				# }}}
				fAssembly = (block, heap, parent) -> # {{{
					# get parent id
					pid = (parent and parent.id) or 0
					# iterate
					a = []
					for b,c of heap when b and c.parent == pid
						# create item
						a[*] = b = new Item block, +b, c, parent
						# set children (recurse)
						b.children = fAssembly block, heap, b
					# check
					if not a.length
						return null
					# set order
					a.sort fOrder
					# done
					return a
				# }}}
				# }}}
				Dropdown = (item) !-> # {{{
					# create object shape
					@item = item
					@root = a = document.createElement 'div'
					@cs   = getComputedStyle a
					@pads = [0,0,0,0] # [padX,padY,borderX,borderY]
					@rect = null  # DOMRect
					# state
					@hovered = 0
					@locked  = 0 # never true
					# initialize
					a.className = 'dropdown l'+item.level
					w3ui.events.attach @, {
						hover: [item.block.onHover, item]
					}
				###
				Dropdown.prototype =
					resize: !-> # {{{
						# drop current inline style
						@root.removeAttribute 'style'
						# determine pads
						a   = @pads
						b   = 'getPropertyValue'
						a.0 = parseFloat (@cs[b] 'padding-left')
						a.1 = parseFloat (@cs[b] 'padding-top')
						a.2 = parseFloat (@cs[b] 'border-left-width')
						a.3 = parseFloat (@cs[b] 'border-top-width')
						# determine bounding rect
						@rect = @root.getBoundingClientRect!
						# recurse
						if @item.depth
							for a in @item.children when b = a.dropdown
								b.resize!
					# }}}
					getMax: (prop) -> # {{{
						# prepare
						a = @rect[prop]
						# search maximal value
						if @item.depth
							for b in @item.children
								if b.dropdown and (c = b.dropdown.getMax prop) > a
									a = c
						# done
						return a
					# }}}
				# }}}
				Item = (block, id, data, parent) !-> # {{{
					# base
					@block    = block
					@id       = id
					@data     = data
					@parent   = parent
					@children = null
					@level    = 0 # how many parents above?
					@depth    = 0 # how many levels below?
					# controls
					@button   = null
					@dropdown = null
				###
				Item.prototype =
					init: (level = 0) -> # {{{
						# set item's level
						@level = level
						# check type
						if @data.url
							# active menu item {{{
							# create button
							a = w3ui.parse tItem, {
								lineA: (not @parent and tLineA) or ''
								name: @data.name
								arrow: (@children and tArrow) or ''
								lineB: (not @parent and tLineB) or ''
							}
							@button = b = w3ui.blocks.button {
								html: a
								name: (@children and 'drop') or ''
								event:
									hover: [@block.onHover, @]
									click: [@block.onClick, @]
							}
							# TODO: set current
							if @data.current
								b.root.classList.add 'x'
								#b.lock true
							# attach
							a = if @parent
								then @parent.dropdown.root
								else @block.rootBox
							a.appendChild b.root
							# check
							if @children
								# create dropdown
								@dropdown = b = new Dropdown @
								# initialize children and determine depth
								d = 0
								for c in @children
									if (e = c.init (level + 1)) > d
										d = e
								# set item's depth
								@depth = d + 1
								# attach
								a.appendChild b.root
							# }}}
						else if @data.type
							# separator {{{
							true
							# }}}
						###
						# done
						return @depth
					# }}}
					lock: (v) !-> # {{{
						# operate
						if @button and not @data.current
							@button.lock v
						# recurse
						if a = @children
							for b in a
								b.lock v
					# }}}
					resize: (x, y, w, h) !-> # {{{
						# prepare
						a = @dropdown.root.style
						b = @dropdown.pads
						# check
						if @block.cfg.stretch.0
							# determine stretched width
							c = w / @depth
							# determine vertical alignment
							if @level and @block.cfg.align == 1
								y = @button.root.offsetTop - b.1 - b.3
							# apply
							a.left   = x+'px'
							a.top    = y+'px'
							a.width  = c+'px'
							a.height = h+'px' if h
							# determine next level offsets and width
							d = @block.cfg.gap.0
							x = c - b.2 + d
							y = 0 - b.3
							w = w - c - d
							# recurse
							for a in @children when a.depth
								a.resize x, y, w, h
							# cleanup (rects are obsolete now)
							@dropdown.rect = null
							@button.rect   = null
						else
							# TODO: better looking variant,
							# ...
							# 1) SUM(max[1..N]) <= w
							# 2) decrease max[1..N] by % to fit w
							# ...
							true
						# done
					# }}}
					open: !-> # {{{
						@button.root.classList.add 'o'
						@dropdown.root.classList.add 'o'
					# }}}
					close: !-> # {{{
						@button.root.classList.remove 'o'
						@dropdown.root.classList.remove 'o'
					# }}}
				# }}}
				Shield = (block) !-> # {{{
					# INFO: protects from accidental hovering/unhovering
					# create object shape
					@block  = block
					@root   = root = w3ui.queryChild block.rootBox, '.shield'
					@item   = null
					@guided = 0
					@fly    = w3ui.delay!
					@onHover = (node, v, e) !~>> # {{{
						# check
						if not (item = @item)
							return
						# redirect
						@block.onHover item, v, e
						# cancel flight
						@fly.cancel! if @fly.pending
						# operate
						if node == @root.children.1
							# set
							@guided = v
						else if v
							# takeoff,
							# approximate time required to reach item's dropdown,
							# using simplified Fitt's formula, first,
							# determine target [r]adius and [d]istance to go
							r = item.button.rect.height / 2
							a = item.dropdown
							d = (a.rect.x + a.pads.0 + r) - e.clientX
							# determine time
							# https://www.cip.ifi.lmu.de/~drewes/science/fitts/A%20Lecture%20on%20Fitts%20Law.pdf
							t = 80 + 400 * Math.log2 (2*d / r)
							# determine current position and step size
							a = @root.children.0.points
							d = a.0.x
							r = (100 - d) * (30 / t)
							# fly
							while await (@fly = w3ui.delay 30)
								d += r
								a.0.x = d
								a.1.x = d
						else
							# initiate landing
							if await (@fly = w3ui.delay 30)
								# check item preserved
								if item == @item
									# shorten runway
									@set!
					# }}}
					@onGuide = w3ui.debounce (null, e) !~> # {{{
						@set e if @guided
					# }}}
					@onClick = (null, e) !~> # {{{
						if @item
							# redirect
							e = new e.constructor e.type, e
							@item.button.root.dispatchEvent e
					# }}}
					# initialize
					a = root.children
					e = w3ui.events
					e.hover a.0, @onHover
					e.hover a.1, @onHover
					e.mmove a.1, @onGuide
					e.click a.1, @onClick
				###
				Shield.prototype =
					attach: (item, e) !-> # {{{
						# prepare
						#if not b = (a = item.parent.dropdown).rect
						#	b = a.rect = a.root.getBoundingClientRect!
						if not c = (a = item.dropdown).rect
							c = a.rect = a.root.getBoundingClientRect!
						if not d = (a = item.button).rect
							d = a.rect = a.root.getBoundingClientRect!
						a = @block.rect
						# SVG container
						# determine offsets (button/dropdown border) and size
						x = d.x - a.x
						y = c.y - a.y
						w = c.x - d.x + item.dropdown.pads.2
						h = if d.y + d.height > c.y + c.height
							then d.y + d.height - c.y
							else c.height
						# apply
						o = @root.style
						o.left   = x+'px'
						o.top    = y+'px'
						o.width  = w+'px'
						o.height = h+'px'
						# guiding polygon
						# determine opposite side offset
						x = 100 * d.width / w
						# determine base vertical offset and addition
						y = 100 * (d.y - c.y) / h
						z = 100 * d.height / h
						# apply
						o = @root.children.1.points
						o.2.x = o.3.x = x
						o.0.y = o.3.y = y
						o.1.y = o.2.y = y + z
						# tracking polygon
						# determine vertical offsets only (button borders)
						y = d.y - c.y
						z = y + d.height
						# apply
						o = @root.children.0.points
						o.0.y = 100 * y / h
						o.1.y = 100 * z / h
						# check current state
						if @item
							# re-activate
							@fly.cancel! if @fly.pending
							@item = item
							@set e
						else
							# activate
							@item = item
							@set e
							@root.classList.add 'v'
					# }}}
					set: (e) !-> # {{{
						# POLYGON TRIANGLE: guiding point positioning
						# prepare
						c = @item.dropdown.rect
						d = @item.button.rect
						# determine horizontal offset (with alignment)
						if e
							x = e.clientX - d.x
							x = x - (d.height / 2)
							x = 0 if x < 0
						else
							x = d.width
						# determine container's width and point position inside
						w = c.x - d.x + @item.dropdown.pads.2
						x = 100 * (x / w)
						# apply
						c = @root.children.0.points
						c.0.x = x
						c.1.x = x
					# }}}
					detach: !-> # {{{
						if @item
							@item = null
							@fly.cancel! if @fly.pending
							@guided = 0
							@root.classList.remove 'v'
					# }}}
				# }}}
				Block = (root) !-> # {{{
					# base
					@root    = root
					@rootBox = root.firstChild
					@cfg     = w3ui.merge {}, {
						stretch: [true, true] # width,height dropdown stretching
						gap: [1, 1] # px vertical(root),horizontal(inner item)
						delay: [ # hover intents
							300 # root open, item close: 300-500 ms
							600 # full close >500 ms
						]
						intent: 300 # hover intent to open/close item
						align:  0 # dropdowns alignment variant 0=box2box 1=item2item
						shield: true # hover guide/triangle
					}
					# controls
					@items   = null # roots
					@shield  = null # item hover shield
					@resizer = null
					# state
					@rect    = null # rootBox DOMRect
					@opened  = [] # items
					@intent  = w3ui.delay!
					@hovered = 0
					@focused = 0
					@locked  = -1
					# handlers
					@onHover = w3ui.events.hovers @, (item, v, e) !~>> # {{{
						# prepare
						list = @opened
						# check
						if v
							# ENTER THE DRAGON
							# deactivate previous call
							@intent.cancel! if @intent.pending
							# check current level opened
							if item.level < list.length
								# check current item opened
								if item == list[item.level]
									return
								# close items
								a = list.length
								while --a >= item.level
									# unhover if hovered (async recursion)
									if not await (@onHover list[a], 0)
										# was not hovered, close explicitly
										list[a].close!
										list.length = a
							# check has dropdown
							if item.dropdown
								# check root
								if not item.level
									# activate instant unhover
									await @onHover item, -1
									# check intent
									if not await (@intent = w3ui.delay @cfg.intent)
										return
									# deactivate instant unhover
									await @onHover item, -1
								# activate dropdown
								item.open!
								list[*] = item
								# activate shield for non-root item
								if item.level and @shield
									@shield.attach item, e
							###
						else if not @hovered
							# CLOSE ALL
							# deactivate previous call
							@intent.cancel! if @intent.pending
							# deactivate shield
							@shield.detach! if @shield
							# deactivate all dropdowns
							a = list.length
							while ~--a
								list[a].close!
							list.length = 0
							###
						else if item.dropdown and list[list.length - 1] == item
							# CLOSE LAST ITEM
							# re-activate shield
							if @shield
								if (a = item.parent) and a.parent and @shield.item != a
									@shield.attach a, null
								else
									@shield.detach!
							# deactivate dropdown
							item.close!
							--list.length
						# done
					, @cfg.intent
					# }}}
					@onClick = (item, e) ~> # {{{
						# check
						switch (data = item.data).type
						case 'page'
							# page naviagation
							window.location.assign data.url
							@lock!
						case 'ext'
							# open external link
							window.open data.url, 'noopener,noreferrer'
						# done
						return 0
					# }}}
					@resize = w3ui.debounce (e) !~> # {{{
						# check
						if not @items
							return
						# TODO:
						# get container's dimensions
						@rect = a = @rootBox.getBoundingClientRect!
						# check menu mode?
						# ...
						# iterate root items
						for item in @items when item.depth
							# prepare
							b = item.button
							c = item.dropdown
							# determine button dimensions
							b.rect = b.root.getBoundingClientRect!
							# determine initial offsets and available width
							x = b.rect.x - a.x
							y = b.rect.y - a.y + b.rect.height + @cfg.gap.1
							w = a.width - x
							# determine dropdown's natural sizes
							c.resize!
							# determine stretched height (max)
							h = if @cfg.stretch.1
								then c.getMax 'height'
								else 0 # no stretching
							# operate
							item.resize x, y, w, h
						# done
						return true
					, 1000, 10
					# }}}
				Block.prototype =
					init: (s) !-> # {{{
						# configure state
						s.state.route = [s.config.routes[''], -1]
						# initialize root box
						@rootBox.innerHTML = tRootBox
						# assemble
						@items = fAssembly @, s.config.routes, null
						# initialize
						for a in @items
							a.init!
						# create shield
						if @cfg.shield
							@shield = new Shield @
						# create resizer
						@resizer = new ResizeObserver @resize
						@resizer.observe @root
					# }}}
					sync: !-> # {{{
						return true
					# }}}
					lock: !-> # {{{
						@rootBox.classList.remove 'v'
					# }}}
					unlock: !-> # {{{
						if a = @items
							for b in a
								b.lock false
						@rootBox.classList.add 'v'
					# }}}
				# }}}
				return Block
			# }}}
		range:
			'products': # {{{
				construct: !-> # {{{
					@view = w3ui.gridlist {root: @root}
				# }}}
				init: !-> # {{{
					# initialize
					(v = @view).init!
					# configure
					@config.layout = v.layout.slice!
					@state.order   = v.cfg.order.slice!
					@state.range   = v.buffer.range.slice!
				# }}}
				sync: !-> # {{{
					# change rows count
					a = @config.layout
					b = @view.layout
					if a.1 != b.1
						@view.setLayout b.0, a.1
					# change total
					if @view.buffer.total != @config.total
						@view.setTotal @config.total
					# change offset
					a = @state.range
					b = @view.buffer.range
					if a.0 != b.0
						view.setOffset a.0
				# }}}
				check: (level) -> # {{{
					# skip own charge
					if @charged
						--@charged
						return true
					# check foreign update priority and
					# reset in case of query change
					if level
						@offset.0 = @offset.1 = 0
						@clearBuffer!
						# in case of total record count change,
						# set special range offsets (determined by the server)
						if level > 1
							@range.1 = @range.3 = -1
					# continue
					return true
				# }}}
			# }}}
			'rows-selector': do -> # {{{
				template = w3ui.template !-> # {{{
					/*
					<select></select>
					<svg preserveAspectRatio="none" viewBox="0 0 48 48">
						<polygon class="b" points="24,32 34,17 36,16 24,34 "/>
						<polygon class="b" points="24,34 12,16 14,17 24,32 "/>
						<polygon class="b" points="34,17 14,17 12,16 36,16 "/>
						<polygon class="a" points="14,17 34,17 24,32 "/>
					</svg>
					*/
				# }}}
				Block = (root) !-> # {{{
					# base
					@root    = root
					@rootBox = box = root.firstChild
					@config  = JSON.parse box.dataset.cfg
					box.innerHTML = template
					# controls
					@select  = box.querySelector 'select' # holds current value
					@icon    = box.querySelector 'svg'
					# state
					@hovered = false
					@focused = false
					@active  = false
					@locked  = -1
					# handlers
					@hover = (e) !~> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# operate
						if not @hovered and not @locked
							@hovered = true
							@rootBox.classList.add 'hovered'
					# }}}
					@unhover = (e) !~> # {{{
						# fulfil event
						if e
							e.preventDefault!
							e.stopPropagation!
						# operate
						if @hovered
							@hovered = false
							@rootBox.classList.remove 'hovered'
					# }}}
					@focus = (e) !~> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# set focused
						if not @focused and not @locked
							@focused = true
							@rootBox.classList.add 'focused'
					# }}}
					@unfocus = (e) !~> # {{{
						# fulfil event
						if e
							e.preventDefault!
							e.stopPropagation!
						# set focused
						if @focused
							@focused = false
							@rootBox.classList.remove 'focused'
					# }}}
					@input = (e) !~> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# operate
						@submit!
					# }}}
				Block.prototype =
					level: 0
					init: (s) !-> # {{{
						# set config
						#s.config.rows = @config.list[@config.index]
						# create options
						c = @group.config.locale
						for s in @config.list
							a = document.createElement 'option'
							a.text = if s == -1
								then c.label.2
								else if s
									then 'x'+s
									else c.label.0
							@select.add a
						# set current
						@select.selectedIndex = @config.index
						# set event handlers
						@attach!
					# }}}
					sync: !-> # {{{
						# get current value
						a = @config.list[@select.selectedIndex]
						# check changed
						if a != (b = @group.config.rows)
							# update
							a = @config.list.indexOf b
							@select.selectedIndex = a
							# set style
							a = !!b and not @locked
							@rootBox.classList.toggle 'active', a
					# }}}
					lock: !-> # {{{
						@select.disabled = true
					# }}}
					unlock: !-> # {{{
						@select.disabled = false
					# }}}
					submit: !-> # {{{
						# get current value
						a = @config.list[@select.selectedIndex]
						# refresh group
						@group.config.rows = a
						@group.sync @
					# }}}
					attach: !-> # {{{
						@rootBox.addEventListener 'pointerenter', @hover
						@rootBox.addEventListener 'pointerleave', @unhover
						@select.addEventListener 'focusin', @focus
						@select.addEventListener 'focusout', @unfocus
						@select.addEventListener 'input', @input
					# }}}
					detach: !-> # {{{
						@rootBox.removeEventListener 'pointerenter', @hover
						@rootBox.removeEventListener 'pointerleave', @unhover
						@select.removeEventListener 'focusin', @focus
						@select.removeEventListener 'focusout', @unfocus
						@select.removeEventListener 'input', @input
					# }}}
				# }}}
				return Block
			# }}}
			'paginator': do -> # {{{
				Control = (block) !-> # {{{
					# data
					@block     = block
					@lock      = w3ui.delay! # common promise
					@dragbox   = [
						0,0,  # 0/1: first area size and runway
						0,    #   2: middle area size
						0,0,  # 3/4: last area runway and size
						0,0,0 # 5-7: first,last,middle page counts
					]
					@fastCfg   = @fastCfg
					# handlers
					@keyDown = (e) !~> # {{{
						# prepare
						B = @block
						# check requirements
						if B.locked or not B.range.mode or @lock.pending
							return
						# check key-code
						switch e.code
						case <[ArrowLeft ArrowDown]>
							# fast-backward
							a = if (a = B.gotos.btnPN).length
								then a.0
								else null
							@fastGo null, a, false
						case <[ArrowRight ArrowUp]>
							# fast-forward
							a = if (a = B.gotos.btnPN).length
								then a.1
								else null
							@fastGo null, a, true
						default
							return
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
					# }}}
					@keyUp = (e) !~> # {{{
						if @lock.pending == 1
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
					@goto = (e) !~> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# check
						if @block.locked or @lock.pending
							return
						# prepare
						B = @block
						C = B.current
						R = B.range
						# determine goto variant
						a = e.currentTarget.parentNode
						b = a.classList
						if b.contains 'page'
							# absolute page number
							a = R.nPages[R.pages.indexOf a] - 1
							###
						else if b.contains 'FL'
							# absolute
							if b.contains 'F'
								# first
								a = 0
							else
								# last
								a = C.1 - 1
							###
						else if b.contains 'P'
							# relative, previous
							if (a = C.0 - 1) < 0
								a = C.1 - 1
						else
							# relative, next
							if (a = C.0 + 1) >= C.1
								a = 0
						# check
						if a == C.0
							return
						# update
						C.0 = a
						B.submit!
						# done
					# }}}
					@fastGoto = (e) ~>> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# check
						if not @lock.pending and \
							e.isPrimary and not e.button and \
							not @block.locked and @block.range.mode == 1
							###
							# determine direction
							a = e.currentTarget
							b = a == @block.gotos.btnPN.1
							# start
							console.log 'fast.start', b
							@fastGo e, a, b
							###
						else if @lock.pending == 2
							###
							# stop
							console.log 'fast.stop'
							@lock.resolve!
						# done
						return true
					# }}}
					@dragStart = (e) ~>> # {{{
						# fulfil event
						#e.preventDefault!
						e.stopPropagation!
						# prepare
						B = @block
						R = B.range
						# check requirements
						if not e.isPrimary or e.button or typeof e.offsetX != 'number' or \
							B.locked or not R.mode or \
							B.current.1 < 2 or @lock.pending
							###
							return true
						# create drag lock
						@lock = lock = w3ui.promise 3
						# set drag style
						R.focus! # solves cursor refresh issue?
						R.box.classList.add 'active', 'drag'
						# cooldown
						await Promise.race [(w3ui.delay 200), lock]
						# check
						if not lock.pending
							# aborted, remove drag style
							R.box.classList.remove 'active', 'drag'
							return true
						# initialize dragbox
						@initDragbox!
						# save initial page index
						a = B.current.0
						# capture pointer
						if not R.box.hasPointerCapture e.pointerId
							R.box.setPointerCapture e.pointerId
						# to prevent dragging before capturing,
						# change promise value
						lock.pending = 4
						# wait dragging complete
						lock = await lock
						# release capture
						if R.box.hasPointerCapture e.pointerId
							R.box.releasePointerCapture e.pointerId
						# remove drag style
						R.box.classList.remove 'active', 'drag'
						# submit if changed normally
						if lock and a != B.current.0
							B.submit!
						# done
						return true
					# }}}
					@dragStop = (e) !~> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# operate
						if @lock.pending in [3,4]
							@lock.resolve!
					# }}}
					@drag = (e) !~> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# check
						if @block.locked or @lock.pending != 4
							return
						# prepare
						C = @block.current
						D = @dragbox # 0-1-2-3-4 | 5-6-7
						# determine current page index
						if (b = e.offsetX) <= 0
							# out of first
							a = 0
						else if b <= D.0
							# first area
							a = (b*D.5 / D.0) .|. 0
						else if (b -= D.0) <= D.1
							# first runway
							a = D.5
						else if (b -= D.1) <= D.2
							# middle
							# determine relative offset and
							# make value discrete
							b = (b*D.6 / D.2) .|. 0
							# add previous counts
							# to determine exact page index
							a = D.5 + 1 + b
						else if (b -= D.2) <= D.3
							# last runway
							a = D.5 + D.6 + 1
						else if (b -= D.3) <= D.4
							# last area
							a = D.5 + D.6 + 2 + (b*D.7 / D.4) .|. 0
						else
							# out of last
							a = C.1 - 1
						# update current
						if C.0 != a
							C.0 = a
							@block.range.refresh!
					# }}}
					@wheel = (e) ~> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# prepare
						B = @block
						C = B.current
						# check requirements
						if B.locked or not B.range.mode or @lock.pending
							return true
						# determine new page index
						if (i = C.0 + 1*(Math.sign e.deltaY)) >= C.1
							i = 0
						else if i < 0
							i = C.1 - 1
						# update state
						C.0 = i
						B.submit!
						return true
					# }}}
				###
				Control.prototype =
					attach: !-> # {{{
						# prepare
						B = @block
						R = B.range
						# operate
						# keyboard controls
						B.root.addEventListener 'keydown', @keyDown, true
						B.root.addEventListener 'keyup', @keyUp, true
						# mouse controls
						B.root.addEventListener 'click', @setFocus
						B.rootBox.addEventListener 'wheel', @wheel, true
						B.rootBox.addEventListener 'pointerenter', @hover
						B.rootBox.addEventListener 'pointerleave', @unhover
						###
						# gotos
						# first-last
						if a = B.gotos.btnFL
							a.0.addEventListener 'click', @goto
							a.1.addEventListener 'click', @goto
						# prev-next
						if a = B.gotos.btnPN
							a.0.addEventListener 'pointerdown', @fastGoto
							a.0.addEventListener 'pointerup', @fastGoto
							a.1.addEventListener 'pointerdown', @fastGoto
							a.1.addEventListener 'pointerup', @fastGoto
						# range
						for a,b in R.pages
							a.firstChild.addEventListener 'click', @goto
						###
						# drag
						a = R.pages[R.index].firstChild
						a.addEventListener 'pointerdown', @dragStart
						B.range.box.addEventListener 'pointermove', @drag
						B.range.box.addEventListener 'pointerup', @dragStop
					# }}}
					detach: !-> # {{{
						true
					# }}}
					fastGo: (event, btn, step) ->> # {{{
						# prepare
						B = @block
						if (C = B.current) < 2
							return false
						# create new lock
						@lock = lock = w3ui.promise if event
							then 2 # pointer
							else 1 # keyboard
						# determine first index
						step = (step > 0 and 1) or -1
						if (first = C.0 + step) >= C.1
							first = 0
						else if first < 0
							first = C.1 - 1
						# goto first
						C.0 = first
						await @fastUpdate!
						# cooldown
						L = await Promise.race [(w3ui.delay 200), lock]
						# check finished or cancelled
						if not lock.pending
							# when finished normally,
							# set first selected index
							B.submit! if L
							# done
							return true
						# activate style
						B.range.box.classList.add 'active'
						btn.parentNode.classList.add 'active'
						# capture pointer
						if event and not btn.hasPointerCapture event.pointerId
							btn.setPointerCapture event.pointerId
						# determine runway parameters
						a = first
						b = step
						c = @fastCfg.1
						if step > 0
							beg = 0
							end = C.1
						else
							beg = C.1 - 1
							end = -1
						# select page indexes until finished or cancelled
						while lock.pending
							# increment
							if (a = a + b) == end
								# range end reached, restart
								a = beg
								b = step
								c = @fastCfg.1
							# update
							C.0 = a
							await @fastUpdate!
							# determine distance left
							if (d = end - step - step*a) <= @fastCfg.1
								# throttle
								b = step
								d = 1000 / (1 + d)
								L = await Promise.race [(w3ui.delay d), lock]
							else if step*b < @fastCfg.0 and --c == 0
								# accelerate
								b = b + step
								c = @fastCfg.1
						# release capture
						if event and btn.hasPointerCapture event.pointerId
							btn.releasePointerCapture event.pointerId
						# deactivate
						btn.parentNode.classList.remove 'active'
						B.range.box.classList.remove 'active'
						# when finished normally (not cancelled),
						# set last selected index
						if L and C.0 != first
							B.submit!
						# done
						return true
					# }}}
					fastUpdate: -> # {{{
						# prepare
						a = w3ui.promise!
						b = @block
						# start
						requestAnimationFrame !->
							b.range.refresh!
							b.range.focus!
							requestAnimationFrame !->
								a.resolve!
						# done
						return a
					# }}}
					initDragbox: !-> # {{{
						# prepare
						R = @block.range
						S = @block.resizer
						C = @block.current.1
						D = @dragbox
						# determine count of elements
						# in the first and last areas (excluding current)
						a = R.index
						b = R.pages.length - a - 1
						# get page-button sizes
						c = S.currentSz.2 # current
						d = S.currentSz.3 # standard
						# calculate drag areas
						# first
						D.0 = c + a * d     # total space
						D.1 = D.0 / (a + 1) # average size of the button (runway)
						D.0 = D.0 - D.1     # size of the drag area
						# last
						D.4 = c + b * d
						D.3 = D.4 / (b + 1)
						D.4 = D.4 - D.3
						# middle
						D.2 = parseFloat (R.cs.getPropertyValue 'width')
						D.2 = D.2 - D.0 - D.4 # - D.1 - D.3
						# try to reduce first and last jump runways,
						# the runway is a special area at the end of the first, and,
						# at the beginning of the last drag areas..
						# in a dualgap mode (when the middle is big enough),
						# smaller runways make a "jump" to the middle more natural
						if R.mode == 1
							# determine space of a single page in the middle
							c = D.2 / (C - a - b)
							# determine penetration limit (half of the average page) and
							# check it fits one mid-page
							if (d = D.1 / 2) > c
								# reduce runways
								D.1 = c + d
								D.3 = c + D.3 / 2
						# correct middle
						D.2 = D.2 - D.1 - D.3
						# store page counts
						D.5 = a
						D.7 = b
						D.6 = C - a - b - 2 # >= 0, always
						# done
					# }}}
					fastCfg:[
						10,  # pages per second
						15   # pages before slowdown
					]
				# }}}
				Resizer = (block) !-> # {{{
					# create object shape
					@block     = block
					@rootCS    = getComputedStyle block.root
					@rootBoxCS = getComputedStyle block.rootBox
					###
					@pads      = [0,0] # container padding
					@baseSz    = [ # initial
						0, 0, # 0/1: root-x, root-y
						0,    #   2: range-x
						0, 0  # 3/4: current-page-x, page-x
					]
					@currentSz = [ # calculated
						0, 0, # 0/1: root-x, root-y
						0, 0  # 2/3: current-page-x, page-x
					]
					@factor    = 1 # relative dynamic axis size
					###
					@observer  = null # resize observer
					@onChange  = null
					@debounce  = w3ui.delay!
					@bounces   = 0
					@resize    = (e) ~>> # {{{
						# apply debounce algorithm
						if @debounce.pending
							@debounce.resolve (++@bounces == 3)
						if not await (@debounce = w3ui.delay 100)
							return false
						@bounces = 0
						# prepare
						B = @block
						R = @block.range
						# get current container width
						w = if e
							then e.0.contentRect.width # observed
							else B.root.clientWidth - @pads.0 # forced
						# update dynamic axis size
						@currentSz.0 = w
						# determine deviation from the base (obey master)
						e = if w > @baseSz.0
							then 1
							else w / @baseSz.0
						e = @onChange e if @onChange
						# update static axis state (none or reduced size)
						@currentSz.1 = if e == 1
							then 0
							else e * @baseSz.1
						# compare dynamic axis size factors
						if (Math.abs (@factor - e)) > 0.005
							# update button sizes
							@currentSz.2 = e * @baseSz.3
							@currentSz.3 = e * @baseSz.4
							# update styles alone (no master)
							if not @onChange
								b = '--w3-factor'
								if ~a
									B.root.style.setProperty b, e
								else
									B.root.style.removeProperty b
							# update value
							@factor = e
						# check range mode
						return true
						if B.config.range and R.mode == 1 and e == 1
							# fully-sized dualgap
							###
							# the drag problem:
							# when paginator has plenty of space at dynamic axis,
							# the middle area (range) may fit all buttons,
							# especially when the page count is low,
							# buttons are enlarged for visual aesthetics and
							# drag areas must correspond to that,
							# if not, it will make drag "jumps" unnatural,
							# and, because of that,
							# determine optimal drag area sizes
							a = (w - @baseSz.0 + @baseSz.3) / B.current.1
							b = (w - @baseSz.0 + @baseSz.4) / B.current.1
							# compare with current
							if (Math.abs (a - @currentSz.2)) > 0.1
								# update variables
								@currentSz.2 = a
								@currentSz.3 = b
								c = '--page-size'
								if (Math.abs (b - @baseSz.4)) > 0.1
									R.box.style.setProperty c, b+'px'
								else
									R.box.style.removeProperty c
						# done
						return true
					# }}}
				###
				Resizer.prototype =
					init: !-> # {{{
						# prepare
						B = @block
						R = @block.range
						# check block state
						if ~B.locked
							# reset container sizes to initial,
							# remove constructed state
							B.root.classList.remove 'v'
						# determine container paddings
						s    = @rootCS
						a    = @pads
						a.0  = parseInt (s.getPropertyValue 'padding-left')
						a.0 += parseInt (s.getPropertyValue 'padding-right')
						a.1  = parseInt (s.getPropertyValue 'padding-top')
						a.1 += parseInt (s.getPropertyValue 'padding-bottom')
						# determine base sizes
						# containers
						a = @block.rootBox.clientWidth - @pads.0
						b = parseFloat (R.cs.getPropertyValue 'width')
						c = parseFloat (R.cs.getPropertyValue 'max-width')
						@baseSz.0 = a - b + c
						@baseSz.1 = parseFloat (s.getPropertyValue '--sm-ppb')
						@baseSz.2 = c
						# selected page button
						# get node
						a = if ~R.current
							then R.pages[R.current] # probably selected
							else R.pages.0 # standard, not selected
						# check and set selected
						if not (b = (a.classList.contains 'x'))
							a.classList.add 'x'
						# read size
						c = getComputedStyle a
						c = parseFloat (c.getPropertyValue 'min-width')
						@baseSz.3 = @currentSz.2 = c
						# rollback selection
						if not b
							a.classList.remove 'x'
						# standard page button
						# get node style
						a = getComputedStyle if not R.current
							then R.pages.0
							else R.pages.1
						# read size
						b = parseFloat (a.getPropertyValue 'min-width')
						@baseSz.4 = @currentSz.3 = b
						# check block state
						if ~B.locked
							# for proper future resize,
							# restore constructed state
							B.root.classList.add 'v'
						# force first resize
						@resize!
					# }}}
					attach: !-> # {{{
						@detatch! if @observer
						@observer = new ResizeObserver @resize
						@observer.observe @block.root
					# }}}
					detach: !-> # {{{
						if @observer
							@observer.disconnect!
							@observer = null
					# }}}
				# }}}
				PageGoto = (block) !-> # {{{
					@boxFL = a = w3ui.queryChildren block.rootBox, '.goto.FL'
					@boxPN = b = w3ui.queryChildren block.rootBox, '.goto.PN'
					@btnFL = w3ui.getArrayObjectProps a, 'firstChild'
					@btnPN = w3ui.getArrayObjectProps b, 'firstChild'
					@sepFL = w3ui.queryChildren block.rootBox, '.sep'
					# initialize
					# both first-previous/next-last present
					if a.length and b.length
						c = -1
						while ++c < a.length
							a[c].classList.add 'both'
							b[c].classList.add 'both'
				# }}}
				PageRange = (block) !-> # {{{
					# controls
					@block = block
					@box   = box = w3ui.queryChild block.rootBox, '.range'
					@cs    = getComputedStyle box
					@pages = pages = w3ui.queryChildren box, '.page'
					@gaps  = gaps = w3ui.queryChildren box, '.gap'
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
					refresh: !-> # {{{
						# prepare defaults
						v     = @block.current
						pages = @pages.slice!fill 0
						gaps  = [0,0]
						first = -1
						last  = -1
						# determine current state
						if v.1 == 0
							# empty {{{
							# no range/current, gap only
							mode    = 0
							current = -1
							count   = 0
							gaps.0  = 100
							# }}}
						else if v.1 > pages.length
							# dualgap {{{
							mode    = 1
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
						else
							# nogap (pages only) {{{
							mode    = 2
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
						###
						# apply changes
						# range mode
						if mode != @mode
							a = @box.classList
							if not @mode
								a.add 'v'
							if mode == 2
								a.add 'nogap'
							else if not mode
								a.remove 'v'
							if @mode == 2
								a.remove 'nogap'
							@mode = mode
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
							if not @block.locked
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
						# range capacity (page buttons count),
						# this should be the last for proper resize
						if count != @count
							# set variables
							@box.style.setProperty '--count', count
							@count = count
							# re-calculate block size
							@block.resizer.init!
						# done
					# }}}
					focus: !-> # {{{
						# set focus to current page button
						if ~@current
							a = @pages[@current].firstChild
							if a != document.activeElement
								a.focus!
					# }}}
				# }}}
				Block = (root) !-> # {{{
					# base
					@root    = root
					@rootBox = rootBox = root.firstChild
					@config  = JSON.parse rootBox.dataset.cfg
					# controls
					@range   = new PageRange @
					@gotos   = new PageGoto @
					@control = new Control @
					@resizer = new Resizer @
					# state
					@current = [-1,-1] # page index,count
					@locked  = -1
				###
				Block.prototype =
					init: (s) !-> # {{{
						# set control classes
						a = @rootBox.classList
						if @config.range == 2
							a.add 'flexy'
						if not @gotos.sepFL
							a.add 'nosep'
						# set event handlers
						@control.attach!
						@resizer.attach!
					# }}}
					sync: !-> # {{{
						# determine current
						if (a = @group.config).count
							b = (Math.round (@group.data.0 / a.count)) .|. 0
							c = Math.ceil (a.total / a.count)
						else
							b = 0
							c = 0
						# check changed
						if (a = @current).0 == b and a.1 == c
							return true
						# update
						a.0 = b
						a.1 = c
						@range.refresh!
						return true
					# }}}
					check: (level) -> # {{{
						return if @control.lock.pending
							then false
							else true
					# }}}
					lock: (level) !-> # {{{
						# terminate activity (dragging, fast forwarding..)
						if level > 0 and @control.lock.pending
							@control.lock.resolve 0
						# remove selection style if the total is going to change
						if level > 1 and ~(a = @range.current)
							@range.pages[a].classList.remove 'x'
						# done
					# }}}
					unlock: (level) !-> # {{{
						# restore selection style
						if (level == -1 or level > 1) and ~(a = @range.current)
							@range.pages[a].classList.add 'x'
						# done
					# }}}
					submit: !-> # {{{
						# set records offset
						@group.data.0 = @current.0 * @group.config.count
						# refresh
						@range.focus!
						@range.refresh!
						@group.sync @
					# }}}
					focus: !-> # {{{
						# set focus to current
						if not @locked and (a = @range) and ~a.current and \
							(a = a.pages[a.current].firstChild) != document.activeElement
							###
							a.focus!
					# }}}
					level: 1
				# }}}
				return Block
			# }}}
		order:
			'orderer': do -> # {{{
				template = w3ui.template !-> # {{{
					/*
					<svg preserveAspectRatio="none" viewBox="0 0 48 48">
						<g class="a1">
							<polygon class="a" points="12,12 24,0 36,12 33,15 27,9 27,45 21,45 21,9 15,15 "/>
							<polygon class="b" points="13,12 24,1 35,12 33,14 26,7 26,44 22,44 22,7 15,14 "/>
						</g>
						<g class="a2">
							<polygon class="a" points="12,33 24,45 36,33 33,30 27,36 27,12 33,18 36,15 24,3 12,15 15,18 21,12 21,36 15,30 "/>
							<polygon class="b" points="13,33 24,44 35,33 33,31 26,38 26,10 33,17 35,15 24,4 13,15 15,17 22,10 22,38 15,31 "/>
						</g>
					</svg>
					*/
				# }}}
				Control = (block) !-> # {{{
					# create object shape
					# data
					@block   = block
					# bound handlers
					@switchVariant = (e) !~> # {{{
						# fulfil event
						e.preventDefault!
						e.stopPropagation!
						# operate
						B = @block
						D = B.group.data
						if not B.locked and (a = B.current.1) > 0
							# set variant
							D.1 = a = if a == 1
								then 2
								else 1
							# update DOM
							b = B.select.selectedIndex
							b = B.select.options[b]
							b.value = a
							# move focus
							B.select.focus!
							# update state
							B.group.update!
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
						D = B.group.data
						if not B.locked
							# set new index and variant
							a = B.select.selectedIndex
							D.0 = B.keys[a]
							D.1 = +B.select.options[a].value
							# update state
							B.group.charge B
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
				Block = (root) !-> # {{{
					# base
					@root    = root
					@rootBox = box = root.firstChild
					@config  = JSON.parse box.dataset.cfg
					# controls
					@tag     = null
					@variant = null
					# state
					@current = ['',-2] # tag,variant
					@options = null    # {option:[tag,variant]}
					@keys    = null    # option names
					@hovered = false
					@focused = false
					@locked  = -1
					# handlers
					@hover = (o) !~> # {{{
						# check
						if (h = o.hovered) != @hovered and (not h or not @locked)
							# operate
							@hovered = h
							@rootBox.classList.toggle 'hovered', h
					# }}}
					@focus = (o) !~> # {{{
						if (f = o.focused) != @focused
							@focused = f
							@rootBox.classList.toggle 'focused', f
					# }}}
					@tagChange = (i) ~> # {{{
						# get tag name by given index and
						# change group tag and variant
						@group.data.0 = i = @keys[i]
						@group.data.1 = @options[i][1]
						@group.sync!
						# complete
						return true
					# }}}
					@variantChange = (i) ~> # {{{
						# change
						@group.data.1 = i
						@group.charge @
						# complete
						return true
					# }}}
				###
				Block.prototype =
					init: (s) !-> # {{{
						# initialize
						s.state.order    = @config.order if @config.order
						@options   = o = s.config.locale.order
						@keys      = k = s.config.order or (Object.getOwnPropertyNames o)
						@tag       = a = w3ui.blocks.select!
						@variant   = b = w3ui.blocks.checkbox {svg: template}
						a.onHover  = b.onHover = @hover
						a.onFocus  = b.onFocus = @focus
						a.onChange = @tagChange
						b.onChange = @variantChange
						###
						c = []
						i = -1
						while ++i < k.length
							c[i] = o[k[i]][0] # localized name
						i = k.indexOf s.state.order.0
						k = s.state.order.1
						###
						a.init c, i
						b.init k
						# compose self
						o = @rootBox
						o.appendChild b.root
						o.appendChild a.root
					# }}}
					sync: !-> # {{{
						# prepare
						a = @group.data
						b = @current
						# check
						if a.0 == b.0 and a.1 == b.1
							return true
						# set style
						if (c = b.1 + 1) <= 2
							@rootBox.classList.remove (('abc')[c])
						@rootBox.classList.add (('abc')[a.1 + 1])
						# set values
						if a.0 != b.0
							# backup current variant
							@options[b.0][1] = b.1 if b.0 and ~b.1
							# set tag and variant
							b.0 = @keys[@tag.set @keys.indexOf a.0]
							b.1 = @variant.set a.1
						else if a.1 != b.1
							# set variant only
							b.1 = @variant.set a.1
						# done
						return true
					# }}}
					lock: !-> # {{{
						@tag.lock true
						@variant.lock true
					# }}}
					unlock: !-> # {{{
						@tag.lock false
						@variant.lock false
					# }}}
					level: 1
				# }}}
				return Block
			# }}}
		price:
			'price-filter': do -> # {{{
				NumInput = (box) !-> # {{{
					# base
					@box   = box
					@input = box.children.0
					@label = box.children.1
					# state
					@current = ['','',0,0] # default/current/selectionStart/End
					@changed = false
					@hovered = false
					@focused = false
					@locked  = true
					# traps
					@onHover  = null
					@onFocus  = null
					@onSubmit = null
					@onScroll = null
					@onChange = null
					# private
					wheelLock = w3ui.delay!
					eUnsignedInt = /^[0-9]{0,9}$/
					# handlers
					@hover = (e) !~> # {{{
						# prepare
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
					@wheel = (e) ~>> # {{{
						# check
						if @locked
							return false
						# fulfil the event
						e.preventDefault!
						e.stopPropagation!
						# bounce
						wheelLock.cancel! if wheelLock.pending
						if not await (wheelLock := w3ui.delay 17)
							return false
						# callback
						@onScroll @, (e.deltaY < 0)
						return true
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
							e @, true if e = @onFocus
					# }}}
					@unfocus = (e) !~> # {{{
						# operate
						@focused = false
						@box.classList.remove 'focused'
						e @, false if e = @onFocus
					# }}}
					@change = (e) ~> # {{{
						# prepare
						c = @current
						v = @input.value
						w = c.1
						# check
						if not v.length
							# empty,
							# reset to the default
							@set c.0
							@input.select!
							# callback
							v = if @onChange and w != c.0
								then @onChange @, c.0
								else false
							###
						else if not eUnsignedInt.test v
							# invalid,
							# restore previous
							@input.value = c.1
							@input.setSelectionRange c.2, c.3
							v = false
							###
						else
							# valid,
							# update current
							c.1 = v
							c.2 = @input.selectionStart
							c.3 = @input.selectionEnd
							# callback
							v = if @onChange and w != v
								then @onChange @, c.1
								else true
						# cancel ivalid input
						if not v
							e.preventDefault!
							e.stopPropagation!
						# done
						return v
					# }}}
					@key = (e) !~> # {{{
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
							# callback
							@onScroll @, (e.keyCode == 38)
							# }}}
						else
							return
						# fulfil the event
						e.preventDefault!
						e.stopPropagation!
					# }}}
					@onLabel = (e) !~> # {{{
						# prepare
						e.preventDefault!
						e.stopPropagation!
						# check
						e = @current
						if not @locked and @focused and @onSubmit and e.1 != e.0
							# restore default
							@set e.0
							@onSubmit @, true
					# }}}
				###
				NumInput.prototype =
					init: (val, label) !-> # {{{
						# set content
						@label.textContent = label
						@current.0 = '' + (@set val)
						# set event handlers
						a = 'addEventListener'
						@box[a] 'pointerenter', @hover
						@box[a] 'pointerleave', @unhover
						@box[a] 'wheel', @wheel if @onScroll
						@input[a] 'focusin',  @focus
						@input[a] 'focusout', @unfocus
						@input[a] 'input', @change, true
						@input[a] 'keydown', @key, true
						@label[a] 'pointerdown', @onLabel, true if @onLabel
						# done
					# }}}
					set: (v) -> # {{{
						c   = @current
						c.1 = @input.value = '' + v
						c.2 = 0
						c.3 = c.1.length
						return v
					# }}}
					lock: (locked) -> # {{{
						# operate
						if @locked != locked
							@locked = locked
							@input.readOnly = !!locked
							@input.value = if locked
								then ''
								else @current.1
						# done
						return locked
					# }}}
					select: !-> # {{{
						c   = @current
						c.2 = 0
						c.3 = c.1.length
						###
						@input.select!
					# }}}
					focus: !-> # {{{
						@input.focus!
					# }}}
					get: -> # {{{
						return +@current.1
					# }}}
				# }}}
				NumRange = (box) !-> # {{{
					# base
					@box = box
					@num = [
						new NumInput box.children.0
						new NumInput box.children.2
					]
					@svg = box.children.1
					@rst = w3ui.queryChild @svg, '.X'
					# state
					@current = null # [fromMin,toMax]
					@range   = null # [min,max]
					@hovered = false
					@focused = false
					@locked  = true
					# traps
					@onFocus  = null
					@onSubmit = null
					# handlers
					@hover = (e) !~> # {{{
						# fulfil event
						e.preventDefault!
						# operate
						if not @locked and not @hovered
							@hovered = true
							@box.classList.add 'hovered'
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
						# prepare
						e.preventDefault!
						e.stopPropagation!
						# check
						if not @locked
							# set default
							for a,b in @num
								@current[b] = a.set @range[b]
							# callback
							@onSubmit @current if @onSubmit
					# }}}
					focusBounce = w3ui.delay 0
					@numFocus = (v, o) ~>> # {{{
						/***/
						# bounce
						focusBounce.cancel! if focusBounce.pending
						if not (await focusBounce := w3ui.delay 66) or @focused == v
							return false
						# operate
						@focused = v
						# callback
						@onFocus @, v if @onFocus
						# done
						return true
						if v
							# select focused
							o.select!
						else
							# submit unfocused
							if @submit o and @onSubmit
								# callback
								@onSubmit @current
						/***/
					# }}}
					@numSubmit = (o, ctrlKey) !~> # {{{
						# operate
						if @submit o
							# callback
							o.select!
							@onSubmit @current if @onSubmit
						else
							# no change
							if ctrlKey
								o.select!
							else
								# focus the opposite
								o = if @num.indexOf o
									then @num.0
									else @num.1
								o.focus!
						# done
					# }}}
					@numScroll = (o, direction) !~> # {{{
						# prepare
						v = o.get!
						i = @num.indexOf o
						c = @current
						d = @range.1 - @range.0
						# determine step and alignment
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
							# one by one
							e = 0
							a = 1
						# }}}
						# apply step
						if direction
							v += a
						else
							v -= a
						# apply alignment
						v = if e
							then +(((''+v).slice 0, -e) + ('0'.repeat e))
							else v
						# apply limit
						v = c.0 + 1 if i and v <= c.0
						v = c.1 - 1 if not i and v >= c.1
						# update
						@num[i].set v
						# submit and callback
						if @submit o and @onSubmit
							@onSubmit @current
						# done
					# }}}
				###
				NumRange.prototype =
					init: (current, range, caption) !-> # {{{
						@current = current.slice!
						@range   = range
						###
						for a,b in @num
							a.onFocus  = @numFocus
							a.onSubmit = @numSubmit
							a.onScroll = @numScroll
							a.init current[b], caption[b]
						###
						@box.addEventListener 'pointerenter', @hover
						@box.addEventListener 'pointerleave', @unhover
						@rst.addEventListener 'click', @reset if @rst
					# }}}
					set: (v) !-> # {{{
						c = @current
						for a,b in @num
							c[b] = a.set v[b]
					# }}}
					lock: (locked) !-> # {{{
						@locked = locked
						for a in @num
							a.lock locked
					# }}}
					focus: !-> # {{{
						@num.0.focus!
					# }}}
					setFocus: (v, o) !-> # {{{
						true
						/***
						# bounce
						focusBounce.cancel! if focusBounce.pending
						if not (await focusBounce := w3ui.delay 66) or @focused == v
							return false
						# operate
						@focused = v
						# callback
						@onFocus @, v if @onFocus
						# done
						return true
						if v
							# select focused
							o.select!
						else
							# submit unfocused
							if @submit o and @onSubmit
								# callback
								@onSubmit @current
						/***/
					# }}}
					submit: (o) -> # {{{
						# prepare
						i = @num.indexOf o
						v = o.get!
						r = @range
						c = @current
						# check
						if v == c[i]
							return false
						# operate
						if i
							if v > r.1
								# correct upper
								if c.1 == (@num.1.set r.1)
									return false
								# update
								c.1 = r.1
								return true
							else if v == c.0
								# restore
								@num.1.set c.1
								return false
							else if v <= r.0
								# correct lower
								if c.1 == (@num.1.set c.0 + 1)
									return false
								# update
								c.1 = c.0 + 1
								return true
							else if v < c.0
								# swap
								c.1 = @num.1.set c.0
								c.0 = @num.0.set v
								return true
							# update
							c.1 = v
						else
							if v < r.0
								# correct lower
								if c.0 == (@num.0.set r.0)
									return false
								# update
								c.0 = r.0
								return true
							else if v == c.1
								# restore
								@num.0.set c.0
								return true
							else if v >= r.1
								# correct upper
								if c.1 == (@num.0.set c.1 - 1)
									return false
								# update
								c.0 = c.1 - 1
								return true
							else if v > c.1
								# swap
								c.0 = @num.0.set c.1
								c.1 = @num.1.set v
								return true
							# update
							c.0 = v
						# done
						return true
					# }}}
				# }}}
				Block = (root) !-> # {{{
					# base
					@root    = root
					@rootBox = box = root.firstChild
					@config  = JSON.parse box.dataset.cfg
					# controls
					@section = null
					@range   = null
					# state
					@current = [-1,-1] # none
					@prev    = null
					@focused = false
					@locked  = -1
					# handlers
					@sectionSwitch = (o, v) ~> # {{{
						# prepare
						d = @group.data
						c = @current
						# check
						if v
							if p = @prev
								# enable
								d.0 = p.0
								d.1 = p.1
								c.0 = c.1 = -1
								@prev = null
								@group.charge @
						else
							if ~c.0 or ~c.1
								# disable
								d.0 = d.1 = -1
								@prev = c.slice!
								@group.charge @
						# done
						return true
					# }}}
					@rangeSubmit = (v) !~> # {{{
						# set filter values
						c = @group.data
						d = @group.config.price
						c.0 = (v.0 == d.0 and -1) or v.0
						c.1 = (v.1 == d.1 and -1) or v.1
						# complete
						@group.charge @
					# }}}
					focusBounce = w3ui.delay!
					focusLast   = null
					@onFocus = (o, v) ~>> # {{{
						# bounce range only
						if o == @range
							focusBounce.cancel! if focusBounce.pending
							if not (await focusBounce := w3ui.delay 66)
								focusLast := o
								return false
						# aggregator guard
						if @focused == v
							# fast focusing
							focusLast := o
							return false
						else if not v and focusLast != o
							# slow unfocusing
							return false
						# operate
						@focused = v
						@root.classList.toggle 'f', v
						# done
						focusLast := o
						return true
					# }}}
				###
				Block.prototype =
					init: (s) !-> # {{{
						# initialize
						# group state
						s.state.price = @current.slice!
						# section
						a = @section = w3ui.section @root
						b = s.config.locale
						a.onChange = @sectionSwitch if @config.sectionSwitch
						a.onFocus  = @onFocus
						a.init s.config.locale.title.1
						# range
						a = @range = new NumRange a.item.section.firstChild
						b = [
							s.config.locale.label.3
							s.config.locale.label.4
						]
						a.onSubmit = @rangeSubmit
						a.onFocus  = @onFocus
						a.init s.config.price, s.config.price, b
					# }}}
					sync: !-> # {{{
						# prepare
						a = @group.data # source
						b = @current    # destination
						# check
						if a.0 == b.0 and a.1 == b.1
							return true
						# operate
						# set active style
						if b.0 == -1 and b.1 == -1
							@rootBox.classList.add 'active'
							@section.rootBox.classList.add 'active'
						else if a.0 == -1 and a.1 == -1
							@rootBox.classList.remove 'active'
							@section.rootBox.classList.remove 'active'
						# set value
						b.0 = a.0
						b.1 = a.1
						# set inputs
						c = @group.config.price
						@range.set [
							(~a.0 and a.0) or c.0
							(~b.1 and b.1) or c.1
						]
						return true
					# }}}
					lock: (level) !-> # {{{
						@range.lock true
						@section.lock true
					# }}}
					unlock: (level) !-> # {{{
						@section.lock false
						@range.lock false
					# }}}
				# }}}
				return Block
			# }}}
		category:
			'category-filter': do -> # {{{
				Checks = !-> # {{{
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
				# }}}
				setItem = (item, v) -> # {{{
					# check
					if (e = item.extra.current) == v
						return false
					# operate
					item.node.classList.remove 'x'+(e + 1)
					item.node.classList.add 'x'+(v + 1)
					item.extra.set v
					# done
					return true
				# }}}
				setParents = (item, v) -> # {{{
					# check
					if not item.parent or not item.extra
						# complete recursion
						return []
					if ~v
						# normal value (on or off)
						# check parent siblings for homogenity
						for a in item.children when v != a.extra.current
							# change to intermediate
							v = -1
							break
					# change and get changed
					a = if setItem item, v
						then [item]
						else []
					# recurse and aggregate
					return (setParents item.parent, v) ++ a
				# }}}
				setChildren = (items, v) -> # {{{
					# create change list
					list = []
					# iterate and set
					for a in items when setItem a, v
						# collect changed
						list[*] = a
						# recurse (assume state homogenity)
						if a.children
							list.push ...(setChildren a.children, v)
					# done
					return list
				# }}}
				sortAsc = (a, b) -> # {{{
					return if a < b
						then -1
						else if a == b
							then 0
							else 1
				# }}}
				Block = (root, index) !-> # {{{
					# base
					@group   = 'category'
					@charge  = null
					@root    = root
					@rootBox = box = root.firstChild
					@index   = index
					# controls
					@section = null
					# state
					@hovered = false
					@focused = false
					@locked  = -1
					# handlers
					@event = (check, v) ~> # {{{
						# create change list
						item = check.cfg.master
						list = [item]
						# set self
						setItem item, v
						# set parents
						if a = item.parent
							list.push ...(setParents a, v)
						# set children
						if a = item.children
							list.push ...(setChildren a, v)
						# update filter data
						a = @group.data[@index]
						if v
							# add
							for item in list when ~item.extra.current
								a[*] = item.config.id
							# sort result
							a.sort sortAsc
						else
							# remove
							for item in list when ~item.extra.current
								a.splice (a.indexOf item.config.id), 1
						# submit group
						@group.charge @
						# done
						return false
					# }}}
				###
				Block.prototype =
					init: (s) !-> # {{{
						# create group data entry
						s.state.category[@index] = []
						# create a section
						@section = sect = w3ui.section @root
						# add extention (exclude root)
						for a in sect.list when a.parent
							# construct
							a.extra = b = w3ui.blocks.checkbox {
								master: a
								intermediate: 1 # set (positive escape)
							}
							b.onChange = @event
							# add into section's title (natural focus navigation)
							a.title.box.insertBefore b.root, a.title.h3
							# initialize (not checked by default)
							setItem a, 0
							b.init 0
						# done
						sect.init s.config.locale.title.0
					# }}}
					sync: !-> # {{{
						return true
						# it's assumed that categories doesn't intersect
						# in the attached UI root, so there may be
						# only one originator and the refresh is
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
							return true
						# determine current filter
						a = @checks.getCheckedIds!
						b = @group.data[@index]
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
							@group.update!
						# done
						return true
					# }}}
					lock: (level) !-> # {{{
						@section.lock true
					# }}}
					unlock: (level) !-> # {{{
						@section.lock false
					# }}}
					level: 2
				# }}}
				return Block
			# }}}
}
