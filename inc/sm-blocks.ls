"use strict"
smBlocks = do ->
	# base
	# helpers {{{
	###
	# TODO
	# - refactor master blocks (conform supervisor)
	# - determine optimal height for paginator/orderer (CSS)
	# - category count display (extra)
	# - static paginator max-width auto-calc
	# - grid's goto next page + scroll up (?)
	# - unify "sm-blocks" selector prefix
	###
	consoleError = (msg) !-> # {{{
		a = '%csm-blocks: %c'+msg
		console.log a, 'font-weight:bold;color:slateblue', 'color:orange'
	# }}}
	consoleInfo = (msg) !-> # {{{
		a = '%csm-blocks: %c'+msg
		console.log a, 'font-weight:bold;color:slateblue', 'color:aquamarine'
	# }}}
	newPromise = (id = -1) -> # {{{
		# create promise
		r = null
		p = new Promise (resolve) !->
			r := resolve
		# create resolver
		p.pending = id
		p.resolve = (data) !->
			p.pending = 0
			r data
		# create spinner
		p.spin = (data) ->
			# resolve current
			p.resolve data
			# create another
			a = newPromise!
			# replace current with another
			p.resolve = a.resolve
			p.spin    = a.spin
			return a
		# done
		return p
	# }}}
	newDelay = (ms = 0) -> # {{{
		# create custom promise
		p = newPromise!
		r = p.resolve
		# start timer
		t = setTimeout !->
			r true
		, ms
		# replace resolver
		p.resolve = (flag = true) !->
			clearTimeout t
			r flag
		# create cancellator
		p.cancel = (flag = false) !->
			clearTimeout t
			r flag
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
	parseTemplate = (f) -> # {{{
		# get function's text and locate the comment
		f = f.toString!
		a = (f.indexOf '/*') + 2
		b = (f.lastIndexOf '*/') - 1
		# tidy up html content and complete
		f = (f.substring a, b).trim!replace />\s+</g, '><'
		return f
		###
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
	S = # slaves
		section: do -> # {{{
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
				@rootBox  = box = root.firstChild
				# controls
				@rootItem = root = new Item @, box, null
				@lines    = querySelectorChildren box, 'svg'
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
				init: (title) ->> # {{{
					# set default title
					if title and not (a = @rootItem.title.firstChild).textContent
						a.textContent = title
					# attach events and complete
					@rootItem.attach!
					@root.classList.add 'v'
					return true
				# }}}
				lock: (level) !-> # {{{
					###
					switch level
					case 1
						if not @locked
							@rootItem.setClass 'v', false
					default
						if @locked
							@rootItem.setClass 'v', true
					# set
					###
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
			return (node, state) ->
				return new Block node, state
		# }}}
		productCard: do -> # {{{
			init  = newPromise!
			sizes = null # dimensions of card elements
			template = !-> # {{{
				/*
				<div>
					<div class="section a">
						<div class="image">
							<img alt="product">
							<svg preserveAspectRatio="none" fill-rule="evenodd" clip-rule="evenodd" shape-rendering="geometricPrecision" viewBox="0 0 270.92 270.92">
								<path fill-rule="nonzero" d="M135.46 245.27c-28.39 0-54.21-10.93-73.72-28.67L216.6 61.74c17.74 19.51 28.67 45.33 28.67 73.72 0 60.55-49.26 109.81-109.81 109.81zm0-219.62c29.24 0 55.78 11.56 75.47 30.25L55.91 210.93c-18.7-19.7-30.25-46.23-30.25-75.47 0-60.55 49.26-109.81 109.8-109.81zm84.55 27.76c-.12-.16-.18-.35-.33-.5-.1-.09-.22-.12-.32-.2-21.4-21.7-51.09-35.19-83.9-35.19-65.03 0-117.94 52.91-117.94 117.94 0 32.81 13.5 62.52 35.2 83.91.08.09.11.22.2.31.14.14.33.2.49.32 21.24 20.63 50.17 33.4 82.05 33.4 65.03 0 117.94-52.91 117.94-117.94 0-31.88-12.77-60.8-33.39-82.05z"/>
							</svg>
						</div>
					</div>
					<div class="section b">
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
					<div class="section c">
						<div class="actions sm-buttons">
							<button type="button" class="open"></button>
							<button type="button" class="add-to-cart">
								<svg preserveAspectRatio="none" viewBox="0 0 446.843 446.843">
									<path d="M444.09 93.103a14.343 14.343 0 00-11.584-5.888H109.92c-.625 0-1.249.038-1.85.119l-13.276-38.27a14.352 14.352 0 00-8.3-8.646L19.586 14.134c-7.374-2.887-15.695.735-18.591 8.1-2.891 7.369.73 15.695 8.1 18.591l60.768 23.872 74.381 214.399c-3.283 1.144-6.065 3.663-7.332 7.187l-21.506 59.739a11.928 11.928 0 001.468 10.916 11.95 11.95 0 009.773 5.078h11.044c-6.844 7.616-11.044 17.646-11.044 28.675 0 23.718 19.298 43.012 43.012 43.012s43.012-19.294 43.012-43.012c0-11.029-4.2-21.059-11.044-28.675h93.776c-6.847 7.616-11.048 17.646-11.048 28.675 0 23.718 19.294 43.012 43.013 43.012 23.718 0 43.012-19.294 43.012-43.012 0-11.029-4.2-21.059-11.043-28.675h13.433c6.599 0 11.947-5.349 11.947-11.948s-5.349-11.947-11.947-11.947H143.647l13.319-36.996c1.72.724 3.578 1.152 5.523 1.152h210.278a14.33 14.33 0 0013.65-9.959l59.739-186.387a14.33 14.33 0 00-2.066-12.828zM169.659 409.807c-10.543 0-19.116-8.573-19.116-19.116s8.573-19.117 19.116-19.117 19.116 8.574 19.116 19.117-8.573 19.116-19.116 19.116zm157.708 0c-10.543 0-19.117-8.573-19.117-19.116s8.574-19.117 19.117-19.117c10.542 0 19.116 8.574 19.116 19.117s-8.574 19.116-19.116 19.116zm75.153-261.658h-73.161V115.89h83.499l-10.338 32.259zm-21.067 65.712h-52.094v-37.038h63.967l-11.873 37.038zm-146.882 0v-37.038h66.113v37.038h-66.113zm66.113 28.677v31.064h-66.113v-31.064h66.113zm-161.569-65.715h66.784v37.038h-53.933l-12.851-37.038zm95.456-28.674V115.89h66.113v32.259h-66.113zm-28.673-32.259v32.259h-76.734l-11.191-32.259h87.925zm-43.982 126.648h43.982v31.064h-33.206l-10.776-31.064zm167.443 31.065v-31.064h42.909l-9.955 31.064h-32.954z"/>
								</svg>
							</button>
						</div>
					</div>
				</div>
				*/
			# }}}
			Items = (block) !-> # {{{
				# {{{
				# create object shape
				@image   = new @image block
				@title   = new @title block
				@price   = new @price block
				@actions = new @actions block
				# initialize
				do ~>>
					# wait variables initialized
					await init
					# check container's aspect ratio,
					# assuming that image item takes all,
					# first section's space (gaps doesn't break ration), and
					# determine optimal display variant (class)
					if sizes.0 < 1
						# vertical is smaller than horizontal,
						# stretch image by [h]eight and
						# unleash automatic browser's width calculation
						@image.box.classList.add 'h'
					else
						# vertical is bigger than horizontal,
						# stretch image by [w]idth and
						# unleash automatic browser's height calculation
						@image.box.classList.add 'w'
					# now, loaded image (if any) may show up
					@image.ready.resolve!
				# }}}
			Items.prototype =
				### a
				image: do -> # {{{
					Item = (block) !->
						@block  = block
						@box    = box = block.rootBox.querySelector '.image'
						@image  = box.firstChild
						@ready  = newPromise!
						@loaded = false
						@load   = ~>> # {{{
							# check image successfully loaded and valid
							if @image.complete and \
							   @image.naturalWidth >= 1 and \
							   @image.naturalHeight >= 1
								###
								await @ready
								@box.classList.add 'v'
								@loaded = true
							# done
							return true
						# }}}
					###
					Item.prototype =
						set: (data) -> # {{{
							# check
							if not data.image
								return true
							# set handler
							@image.addEventListener 'load', @load
							# set image attributes
							for a,b of data.image
								@image[a] = b
							# done
							return true
						# }}}
						clear: !-> # {{{
							@image.removeEventListener 'load', @load
							if @loaded
								@box.classList.remove 'v'
								@image.className = ''
								@image.src = ''
								@loaded = false
						# }}}
					###
					return Item
				# }}}
				### b
				title: do -> # {{{
					Item = (block) !->
						@block = block
						@box   = box = block.rootBox.querySelector '.title'
						@title = box.firstChild
					###
					eBreakMarkers = /\s+([\\\|/.]){1}\s+/
					Item.prototype =
						set: (data) -> # {{{
							# check
							if not (data = data.title)
								return true
							# break title into lines
							data = data.replace eBreakMarkers, "\n"
							# TODO: check it fits the container height and
							# TODO: cut string if required
							# set
							@title.firstChild.textContent = data
							# done
							return true
						# }}}
						clear: !-> # {{{
							@title.firstChild.textContent = ''
						# }}}
					###
					return Item
				# }}}
				price: do -> # {{{
					Item = (block) !->
						@block    = block
						@box      = box = block.rootBox.querySelector '.price'
						@currency = querySelectorChild box, '.currency'
						@boxes    = box = [
							querySelectorChild box, '.value.a' # current
							querySelectorChild box, '.value.b' # regular
						]
						@values   = [
							box.0.children.0 # integer
							box.0.children.1 # fraction
							box.1.children.0
							box.1.children.1
						]
						@money    = [0,0] # integers (no fraction)
					###
					eBreakThousands = /\B(?=(\d{3})+(?!\d))/
					eNotNumber = /[^0-9]/
					Item.prototype =
						set: (data) -> # {{{
							# check
							if not (data = data.price)
								return true
							# get global config
							if not (cfg = @block.master.cfg.currency)
								return false
							# split numbers [regular,current] into integer and fraction
							b = data.0.split eNotNumber, 2
							a = data.1.split eNotNumber, 2
							# truncate fraction point
							a.1 = if a.1
								then (a.1.substring 0, cfg.3).padEnd cfg.3, '0'
								else '0'.repeat cfg.3
							b.1 = if b.1
								then (b.1.substring 0, cfg.3).padEnd cfg.3, '0'
								else '0'.repeat cfg.3
							# determine money values
							c = @money
							d = +('1' + ('0'.repeat cfg.3))
							c.0 = d*(+(a.0)) + (+a.1)
							c.1 = d*(+(b.0)) + (+b.1)
							# separate integer thousands
							if cfg.2
								a.0 = a.0.replace eBreakThousands, cfg.2
								b.0 = b.0.replace eBreakThousands, cfg.2
							# set values
							@currency.firstChild.textContent = cfg.0
							c = @values
							c.0.firstChild.textContent = a.0
							c.1.firstChild.textContent = cfg.1
							c.1.lastChild.textContent  = a.1
							c.2.firstChild.textContent = b.0
							c.3.firstChild.textContent = cfg.1
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
							d = if cfg.4
								then 'right'
								else 'left'
							@box.classList.add d
							# done
							@box.classList.add 'v'
							return true
						# }}}
						clear: !-> # {{{
							@box.className = 'price'
						# }}}
					###
					return Item
				# }}}
				### c
				actions: do -> # {{{
					Item = (block) !->
						@block   = block
						@box     = box = block.rootBox.querySelector '.actions'
						@buttons = b = [
							box.querySelector '.add-to-cart'
							box.querySelector '.open'
						]
						# initialize
						a = block.master.cfg.locale.product.0
						b.1.textContent = a
					###
					Item.prototype =
						set: (data) -> # {{{
							/***
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
							/***/
							# done
							return true
						# }}}
						clear: !-> # {{{
							true
							/***
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
							/***/
						# }}}
						addToCart: (id) ->> # {{{
							# fetch
							a = await soFetch {
									func: 'cart'
									op: 'set'
									id: id
							}
							# check
							if a instanceof Error
								return false
							# TODO: optional, back-compat, remove it
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
			Block = (master) !-> # {{{
				# construct
				# create root
				R = document.createElement 'div'
				R.className = 'product'
				R.innerHTML = template
				# create placeholder (reuse master)
				R.appendChild (master.root.children.1.cloneNode true)
				# create object shape
				@master  = master
				@root    = R
				@rootBox = R.firstChild
				@id      = -1
				@items   = new Items @
			###
			Block.prototype =
				set: (record) -> # {{{
					# set own
					@id = record.id
					# set items
					a = @items
					for b of a
						if not a[b].set record
							return false
					# done
					@root.classList.add 'ready'
					return true
				# }}}
				clear: !-> # {{{
					# clear items
					a = @items
					for b of a
						a[b].clear!
					# done
					@root.classList.remove 'ready'
				# }}}
			# }}}
			return (m) ->
				# initialize first
				if init.pending
					template := parseTemplate template
				# create
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
					# determine default item size
					a = m.master.resizer.sizes
					b = a.1 - s.5 - s.6
					a = a.0 - s.3 - s.4
					# convert relative heights to absolute and
					# determine aspect ratios
					s.0 = (b * s.0 / 100) / a
					s.1 = (b * s.1 / 100) / a
					s.2 = (b * s.2 / 100) / a
					# keep default size of the item
					s.3 = a
					s.4 = b
					# complete
					s.length = 5
					init.resolve!
				# done
				return m
		# }}}
	M = # masters
		'products': do -> # {{{
			Resizer = (block) !-> # {{{
				# create object shape
				@block    = block
				@style    = getComputedStyle block.rootBox
				###
				@pads     = [0,0]   # container padding
				@layout   = [0,0,0] # current column-count,row-count,max-item-count
				@gaps     = [0,0]   # column,row
				@sizes    = [0,0,0] # item's width,height,aspect-ratio
				@factor   = 1       # current size factor
				###
				@observer = null    # resize observer
				@onChange = null    # resize controller callback
				@debounce = newDelay!
				@bounces  = 0
				@resize   = (e) ~>> # {{{
					# apply debounce algorithm
					if @debounce.pending
						@debounce.cancel (++@bounces == 3)
					if not await (@debounce = newDelay 100)
						return false
					@bounces = 0
					# get current width of the grid
					w = if e
						then e.0.contentRect.width
						else @block.root.clientWidth - @pads.0
					# assuming no size factor applied,
					# determine current layout
					[a,b,c,d] = @calculateLayout w, 1
					# determine size factor
					e = if d > w
						then w / d # overflow
						else 1     # normal
					# callback master
					if @onChange
						d = e
						if (e = @onChange e) < d
							[a,b,c] = @calculateLayout w, e
					# update layout
					if @layout.0 != a
						@layout.0 = a
						@block.rootBox.style.setProperty '--columns', a
					if @layout.1 != b
						@layout.1 = b
						@block.rootBox.style.setProperty '--rows', b
					if (a = @layout.2) != c
						# store
						@layout.2 = c
						# get current items
						d = @block.items
						b = d.length
						# check
						if c > a
							# show more items
							b = c if c < b
							--a
							while ++a < b
								d[a].root.classList.add 'v'
						else
							# show less items
							a = b if a > b
							while --a >= c
								d[a].root.classList.remove 'v'
					# update size factor
					if not @onChange and (Math.abs (@factor - e)) > 0.005
						a = @block.root.style
						b = '--sm-blocks-factor'
						if (@factor = e) == 1
							a.removeProperty b
						else
							a.setProperty b, e
					# done
					return true
				# }}}
			###
			Resizer.prototype =
				init: !-> # {{{
					# prepare
					# determine initial layout (max-max)
					a = @block.config.layout
					@layout.0 = a.0
					@layout.1 = a.1
					# determine container padding
					s    = getComputedStyle @block.root
					a    = @pads
					a.0  = parseInt (s.getPropertyValue 'padding-left')
					a.0 += parseInt (s.getPropertyValue 'padding-right')
					a.1  = parseInt (s.getPropertyValue 'padding-top')
					a.1 += parseInt (s.getPropertyValue 'padding-bottom')
					# determine gaps
					s   = @style
					a   = @gaps
					a.0 = parseInt (s.getPropertyValue '--column-gap')
					a.1 = parseInt (s.getPropertyValue '--row-gap')
					# determine item size
					a   = @sizes
					a.0 = parseInt (s.getPropertyValue '--item-width')
					a.1 = parseInt (s.getPropertyValue '--item-height')
					a.2 = a.1 / a.0
					# done
				# }}}
				attach: !-> # {{{
					@detach! if @observer
					@init!
					@observer = new ResizeObserver @resize
					@observer.observe @block.root
				# }}}
				detach: !-> # {{{
					if @observer
						@observer.disconnect!
						@observer = null
				# }}}
				calculateLayout: (w, e) -> # {{{
					# prepare
					C = @block.config.layout
					# determine current layout
					# columns
					a = C.2
					b = e * @sizes.0
					c = e * @gaps.0
					# check dynamic
					if a and a < C.0
						# determine optimal
						while (d = a*b + (a - 1)*c) <= w and a < C.0
							++a
						# check overflow
						if d > w and a > C.2
							# decrease and re-calculate
							--a
							d = a*b + (a - 1)*c
						# rows
						# check dynamic
						if not (b = C.3)
							# determine optimal
							c = C.0 * C.1
							b = (c / a) .|. 0
							# fit all items
							++b if a*b < c
					else
						# fixed columns/rows
						a = C.0
						b = C.1
						d = a*b + (a - 1)*c
					# determine max items count
					c = a * b
					# done
					return [a,b,c,d]
				# }}}
			# }}}
			Block = (state, root) !-> # {{{
				# base
				@state   = state
				@root    = root
				@rootBox = box = root.firstChild
				@config  = JSON.parse box.dataset.cfg
				@cfg     = null # global
				# controls
				@items   = []
				@resizer = new Resizer @
				# state
				@loaded  = 0
				@locked  = -1
			###
			Block.prototype =
				group: 'products'
				level: 3
				configure: (o) !-> # {{{
					a = @config.layout
					o.limit = a.0 * a.1
					o.order = @config.orderTag
				# }}}
				init: (cfg) -> # {{{
					# set global config
					@cfg = cfg
					# set grid parameters
					a = @config.layout
					b = @rootBox.style
					b.setProperty '--columns', a.0
					b.setProperty '--rows', a.1
					# activate resizer
					@resizer.attach!
					# create items
					a = a.0 * a.1
					b = -1
					c = @items
					while ++b < a
						c[*] = @state.f.productCard @
					# done
					return true
				# }}}
				lock: (level) ->> # {{{
					###
					c0 = @root.classList
					c1 = @rootBox.classList
					###
					if @locked != level
						if ~level
							if level
								# lock
								if ~@locked
									c1.remove 'v'
								else
									c0.add 'v'
							else
								# unlock
								c1.add 'v'
						else
							# initial lock
							c1.remove 'v' if @locked
							c0.remove 'v'
					###
					@locked = level
					return true
				# }}}
				notify: (level) -> # {{{
					# check
					if level > 0
						# query parameters changed
						@lock 1 # loading in progress
					# done
					return true
				# }}}
				refresh: !-> # {{{
					true
				# }}}
				load: (record, index) -> # {{{
					# prepare
					I = @items
					# check overlap
					if (a = @loaded) > index
						# clear items in reverse order
						while --a >= index
							I[a].clear!
					# set product card
					if not I[index].set record
						return false
					# done
					@loaded = index + 1
					return true
				# }}}
			# }}}
			return Block
		# }}}
		'category-filter': do -> # {{{
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
				@section = S = state.f.section root
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
					cfg = cfg.locale.category.0
					if not (await @section.init cfg)
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
		'price-filter': do -> # {{{
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
				@section = S = state.f.section root.parentNode.parentNode.parentNode
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
					# initialize
					if not (await @section.init cfg.locale.price.title)
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
					c0 = @root.classList
					c1 = @rootBox.classList
					###
					if level != @locked
						if ~level
							if level
								# lock
								if not ~@locked
									c1.add 'v'
									c0.add 'v'
								@inputs.lock 1
								@section.lock 1
							else
								# unlock
								@section.lock 0
								@inputs.lock 0
						else
							# initial lock
							c1.remove 'v'
							c0.remove 'v'
							@section.lock -1
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
		'paginator': do -> # {{{
			Control = (block) !-> # {{{
				# data
				@block     = block
				@lock      = newDelay! # common promise
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
					console.log 'page.click'
					B = @block
					S = B.state
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
							a = S.data.1 - 1
						###
					else if b.contains 'P'
						# relative, previous
						if (a = S.data.0 - 1) < 0
							a = S.data.1 - 1
					else
						# relative, next
						if (a = S.data.0 + 1) >= S.data.1
							a = 0
					# check
					if a == S.data.0
						return
					# update
					S.data.0 = a
					S.change!
					# done
					B.refresh!
					R.focus!
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
					e.preventDefault!
					e.stopPropagation!
					# prepare
					B = @block
					# check requirements
					if not e.isPrimary or e.button or typeof e.offsetX != 'number' or \
					   B.locked or not B.range.mode or \
					   B.state.data.1 == 1 or @lock.pending
						###
						return true
					# create drag lock
					@lock = lock = newPromise 3
					# cooldown
					await Promise.race [(newDelay 200), lock]
					# prevent collisions
					if not lock.pending
						return true
					# initialize dragbox
					@initDragbox!
					# save current page index
					a = B.state.data.0
					# capture pointer
					(R = B.range).focus!
					R.box.classList.add 'active', 'drag'
					if not R.box.hasPointerCapture e.pointerId
						R.box.setPointerCapture e.pointerId
					# to prevent dragging before capture,
					# change promise value
					lock.pending = 4
					# wait dragging complete
					await lock
					# release capture
					if R.box.hasPointerCapture e.pointerId
						R.box.releasePointerCapture e.pointerId
					R.box.classList.remove 'active', 'drag'
					# check changed
					if not @block.locked and a != B.state.data.0
						# update global state
						B.state.change!
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
					D = @dragbox # 0-1-2-3-4 | 5-6-7
					S = @block.state.data
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
						a = S.1 - 1
					# update local state
					if S.0 != a
						S.0 = a
						@block.refresh!
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
					if (S = B.state).data.1 == 1
						return false
					# create new lock
					@lock = lock = newPromise if event
						then 2 # pointer
						else 1 # keyboard
					# determine first index
					step = (step > 0 and 1) or -1
					if (first = S.data.0 + step) >= S.data.1
						first = 0
					else if first < 0
						first = S.data.1 - 1
					# goto first
					S.data.0 = first
					await @fastUpdate!
					# cooldown
					await Promise.race [(newDelay 200), lock]
					# prevent collisions
					if not lock.pending
						S.change!
						return true
					# activate style
					B.range.box.classList.add 'active'
					btn.parentNode.classList.add 'active'
					# capture pointer
					if event and not btn.hasPointerCapture event.pointerId
						btn.setPointerCapture event.pointerId
					# start
					a = first
					b = step
					c = @fastCfg.1
					if step > 0
						beg = 0
						end = S.data.1
					else
						beg = S.data.1 - 1
						end = -1
					while lock.pending
						# increment
						if (a = a + b) == end
							# range end reached, restart
							a = beg
							b = step
							c = @fastCfg.1
						# update
						S.data.0 = a
						await @fastUpdate!
						# determine distance left
						if (d = end - step - step*a) <= @fastCfg.1
							# throttle
							b = step
							d = 1000 / (1 + d)
							await Promise.race [(newDelay d), lock]
						else if step*b < @fastCfg.0 and --c == 0
							# accelerate
							b = b + step
							c = @fastCfg.1
					# complete
					# release capture
					if event and btn.hasPointerCapture event.pointerId
						btn.releasePointerCapture event.pointerId
					# deactivate style
					btn.parentNode.classList.remove 'active'
					B.range.box.classList.remove 'active'
					# update global state
					if S.data.0 != first
						S.change!
					# done
					return true
				# }}}
				fastUpdate: -> # {{{
					# prepare
					a = newPromise!
					b = @block
					# start
					requestAnimationFrame !->
						b.refresh!
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
					D = @dragbox
					X = @block.state.data.1
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
						c = D.2 / (X - a - b)
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
					D.6 = X - a - b - 2 # >= 0, always
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
				@debounce  = newDelay!
				@bounces   = 0
				@resize    = (e) ~>> # {{{
					# apply debounce algorithm
					if @debounce.pending
						@debounce.cancel (++@bounces == 3)
					if not await (@debounce = newDelay 100)
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
							b = '--sm-blocks-factor'
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
						debugger
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
					@baseSz.1 = parseFloat (s.getPropertyValue '--sm-blocks-height')
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
				@boxFL = a = querySelectorChildren block.rootBox, '.goto.FL'
				@boxPN = b = querySelectorChildren block.rootBox, '.goto.PN'
				@btnFL = queryFirstChildren a
				@btnPN = queryFirstChildren b
				@sepFL = querySelectorChildren block.rootBox, '.sep'
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
				@resizer = new Resizer @
				# state
				@locked  = -1
				@current = [-1,-1] # page index, count
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
					@resizer.attach!
					return true
				# }}}
				lock: (level) ->> # {{{
					###
					current = @locked
					@locked = level
					c0 = @root.classList
					c1 = @rootBox.classList
					###
					if level != current
						if ~level
							if level
								# lock
								if ~current
									# wait activity terminated
									if (a = @control.lock).pending
										await a.spin!
									# remove styles
									c1.remove 'v'
									if ~(a = @range.current)
										@range.pages[a].classList.remove 'x'
								else
									c0.add 'v'
							else
								# unlock
								c1.add 'v'
								if ~(a = @range.current)
									@range.pages[a].classList.add 'x'
						else
							# initial lock
							c1.remove 'v' if not current
							c0.remove 'v'
					###
					return true
				# }}}
				notify: (level) -> # {{{
					@refresh!
					return not @control.lock.pending
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
				focus: !-> # {{{
					# set focus to current
					if not @locked and (a = @range) and ~a.current and \
						(a = a.pages[a.current].firstChild) != document.activeElement
						###
						a.focus!
				# }}}
			# }}}
			return Block
		# }}}
		'orderer': do -> # {{{
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
					c0 = @root.classList
					c1 = @rootBox.classList
					###
					if level != @locked
						if ~level
							if level
								# lock
								if ~@locked
									c1.remove 'v'
								else
									c0.add 'v'
							else
								# unlock
								c1.add 'v'
						else
							# initial lock
							c1.remove 'v' if not @locked
							c0.remove 'v'
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
		'view-modifier': do -> # {{{
			Control = (block) !-> # {{{
				@block = block
			###
			Control.prototype = {
				attach: !-> # {{{
					true
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
				@rootBox = box = root.firstChild
				debugger
				@config  = JSON.parse box.dataset.cfg
				# controls
				# ...
				# state
				@locked  = -1
				@current = -1
			###
			Block.prototype =
				group: 'view'
				level: 2
				init: (cfg) -> # {{{
					return true
				# }}}
				lock: (level) ->> # {{{
					###
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
			# }}}
			return Block
		# }}}
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
		Loader = (s) !->
			# {{{
			@super = s     # s-supervisor
			@dirty = -1    # resolved-in-process flag
			@level = -1    # current priority (highest for the first)
			@lock  = null  # current load promise
			@fetch = null  # request promise
			@state = null
			@data  = null
			# }}}
		Loader.prototype =
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
					consoleError cfg.message
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
				a = []
				for b in B
					a[*] = if b.init
						then b.init cfg
						else true
				# wait for completion and iterate results
				for a,b in (await Promise.all a)
					# check
					if not a
						consoleError 'failed to initialize '+B[b].group+' block'
						return false
					# lock constructed
					B[b].lock 1
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
				@dirty = -1
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
					@lock  = p = newDelay (~@dirty and 400)
					@dirty = 0
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
					console.log 'group ', @name, 'resolved clean', p.pending, 'loader dirty', loader.dirty
					if p.pending
						# clean
						p.pending = false
						r true
					else if not loader.dirty
						# dirty
						loader.dirty = 1
						loader.fetch.cancel! if loader.fetch
					# done
					return true
			# }}}
			cycle: ->> # {{{
				# wait for updates
				if not (await @charge!)
					return true
				# lock (lower -> higher)
				console.log 'loader charged'
				B = @super.blocks
				a = []
				b = -1
				while ++b < B.length
					# only lower than current
					if B[b].level < @level
						console.log 'locking '+b.group
						a[*] = B[b].lock 1
				# notify (higher -> lower)
				while ~--b
					# higher or current only
					if B[b].level >= @level and not B[b].notify @level
						@dirty = 2 # delay restart
				# wait locked
				await Promise.all a if a.length
				# check
				if @dirty
					return true
				# start fetcher
				R = await (@fetch = oFetch @data)
				@fetch = null
				# check
				if R instanceof Error
					# cancelled?
					if R.id == 4
						return true
					# fatal failure!
					consoleError R.message
					return false
				# read metadata
				if (a = await R.readInt!) == null
					consoleError 'fetch stream failed'
					R.cancel!
					return false
				# update state
				# total records and page count
				@state.total  = a
				@state.page.1 = Math.ceil (a / @data.limit)
				# unlock and refresh blocks
				a = -1
				while ++a < B.length
					if (b = B[a]).locked
						b.lock 0
					b.refresh @level
				# reset groups
				B = @super.groups
				a = -1
				while ++a < B.length
					if (b = B[a]).state.pending
						b.state.pending = false
				# reset priority
				@level = 0
				###
				# load records
				if (B = @super.holders).length
					# determine count
					a = @data.limit
					if (b = @data.offset + a - @state.total) > 0
						a = a - b
					# iterate
					b = -1
					while ++b < a and not @dirty
						# read
						if (c = await R.readJSON!) == null
							consoleError 'fetch stream failed'
							R.cancel!
							return false
						# load
						d = -1
						while ++d < B.length
							if not B[d].load c, b
								consoleError 'failed to load '+B[d].group
								return false
					# satisfy chrome (2020-04) as it dumps error
					await R.read!
				# complete
				R.cancel!
				return true
			# }}}
		###
		return (s) -> new Loader s
	# }}}
	newResizer = do -> # {{{
		ResizeSlave = (master, node) !->
			@parent   = master
			@node     = node
			@blocks   = null
			@factor   = 1
			@emitter  = null
			@handler  = null
		###
		ResizeMaster = (selector, blocks) !->
			# {{{
			@slaves = s = []
			# initialize
			# locate slave nodes
			n = [...(document.querySelectorAll selector)]
			# iterate
			for a in n
				# create a slave
				s[*] = b = new ResizeSlave @, a
				# set blocks
				b.blocks = c = []
				for d in blocks
					# lookup block parents
					e = d.root
					while e and e != a and (n.indexOf e) == -1
						e = e.parentNode
					# add
					c[*] = d if e == a
				# set handlers
				b.handler = e = @handler b
				for d in c when d.resizer
					d.resizer.onChange = e
			# }}}
		ResizeMaster.prototype =
			handler: (s) -> (e) -> # {{{
				# check
				if s.factor > e or s.emitter == @block
					# lower factor or higher self,
					# update state and styles
					s.factor = e
					c = '--sm-blocks-factor'
					if e == 1
						s.node.style.removeProperty c
						s.emitter = null
					else
						s.node.style.setProperty c, e
						s.emitter = @block
				else
					# higher another, use minimal
					e = s.factor
				# done
				return e
			# }}}
		###
		return (selector, blocks) ->
			return new ResizeMaster selector, blocks
	# }}}
	newGroup   = do -> # {{{
		State = (slaves) !-> # {{{
			# create object shape
			@f       = slaves
			@config  = null
			@data    = null
			@pending = false
			@change  = null
		# }}}
		Group = (blocks, state) !-> # {{{
			# create object shape
			@blocks  = blocks
			@name    = blocks.0.group
			@level   = blocks.0.level
			@resolve = null
			@state   = state
			# create state resolver
			state.change = (data) !~>
				console.log 'state.change'
				state.data = data if arguments.length
				state.pending = true
				@resolve!
		# }}}
		return (Master, slaves, nodes) ->
			# prepare
			s = new State slaves
			i = -1
			while ++i < nodes.length
				nodes[i] = new Master s, nodes[i], i
			# create
			return new Group nodes, s
	# }}}
	SUPERVISOR = (m, s) !-> # {{{
		# prepare masters and slaves
		m = if m
			then {} <<< M <<< m
			else M
		s = if s
			then {} <<< S <<< s
			else S
		# create object shape
		@masters = m
		@slaves  = s
		@root    = null # attachment point
		@resizer = null
		@loader  = null
		@counter = 0    # user actions
		@groups  = []   # block groups
		@blocks  = []   # all blocks
		@holders = []   # receiver blocks
		# done
		s = (m != M and 'custom ') or ''
		consoleInfo 'new '+s+'supervisor'
	###
	SUPERVISOR.prototype =
		attach: (root, base = '.sm-blocks') ->> # {{{
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
			# prepare
			groups = @groups
			blocks = @blocks
			# create managed groups
			for a,b of @masters
				if (a = [...(root.querySelectorAll base+'.'+a)]).length
					groups[*] = newGroup b, @slaves, a
			# check
			if not groups.length
				return false
			# collect blocks
			for a in groups
				blocks.push ...a.blocks
			# collect receivers
			b = @holders
			for a in blocks when a.load
				b[*] = a
			# sort blocks and groups by priority level (ascending)
			a = (a, b) ->
				return if a.level < b.level
					then -1
					else if a.level == b.level
						then 0
						else 1
			groups.sort a
			blocks.sort a
			# create controllers
			@root    = root
			@loader  = loader = newLoader @
			@resizer = newResizer '.sm-blocks-resizer', blocks
			@counter = 0
			# start
			if not (await loader.init!)
				await @detach!
				consoleError 'attachment failed'
				return false
			# enter the dragon
			consoleInfo 'supervisor attached'
			while await loader.cycle!
				++@counter
			# complete
			consoleInfo 'supervisor detached, '+@counter+' actions'
			return true
		# }}}
		detach: ->> # {{{
			# cleanup
			@root = @resizer = @loader = null
			@groups.length = @blocks.length = @holders.length = 0
			# done
			return true
		# }}}
	# }}}
	# factory
	return (m, s) -> new SUPERVISOR m, s
###
# index/launcher (DELETE) {{{
#smBlocks = smBlocks [/***/]
smBlocks = smBlocks!
smBlocks.attach document
# }}}
