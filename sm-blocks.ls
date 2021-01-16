"use strict"
SM = do ->
	# base
	# helpers {{{
	###
	# TODO
	# - unified focus handlers
	# - section => treeview
	# - new slave: selector (simple dropdown)
	# - category count display (extra)
	# - static paginator max-width auto-calc
	###
	BRAND = 'sm-blocks'
	###
	consoleError = (msg) !-> # {{{
		a = '%c'+BRAND+': %c'+msg
		console.log a, 'font-weight:bold;color:slateblue', 'color:orange'
	# }}}
	consoleInfo = (msg) !-> # {{{
		a = '%c'+BRAND+': %c'+msg
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
			if not arguments.length
				data = p.pending
			p.pending = 0
			r data
		# done
		return p
	# }}}
	newDelay = (ms = 0, id = -1) -> # {{{
		# create custom promise
		p = newPromise id
		r = p.resolve
		# start timer
		t = setTimeout !->
			r p.pending
		, ms
		# replace resolver
		p.resolve = (flag) !->
			clearTimeout t
			r if arguments.length
				then flag
				else p.pending
		# create cancellator
		p.cancel = (flag) !->
			clearTimeout t
			r if arguments.length
				then flag
				else 0
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
	goFetch = httpFetch.create {
		baseUrl: '/?rest_route=/'+BRAND+'/kiss'
		mounted: true
		notNull: true
		method: 'POST'
	}
	soFetch = httpFetch.create {
		baseUrl: '/?rest_route=/'+BRAND+'/kiss'
		mounted: true
		notNull: true
		method: 'POST'
		timeout: 0
		parseResponse: 'stream'
	}
	# }}}
	w3ui = # {{{
		template: (f) -> # HTML-in-JS {{{
			# get function's text and locate the comment
			f = f.toString!
			a = (f.indexOf '/*') + 2
			b = (f.lastIndexOf '*/') - 1
			# tidy up html content and complete
			f = (f.substring a, b).trim!replace />\s+</g, '><'
			return f
		# }}}
		event: # {{{
			# primitive
			hover: (B) -> (e) !-> # {{{
				# pprepare
				e.preventDefault!
				# check
				if not B.locked and not B.pending and not B.hovered
					# operate
					B.hovered = true
					B.root.classList.add 'h'
					# callback
					B.onHover true, B if B.onHover
			# }}}
			unhover: (B) -> (e) !-> # {{{
				# prepare
				e.preventDefault!
				# check
				if B.hovered
					# operate
					B.hovered = false
					B.root.classList.remove 'h'
					# callback
					B.onHover false, B if B.onHover
			# }}}
			focus: (B) -> (e) !-> # {{{
				# check
				if B.locked
					# ignore
					e.preventDefault!
					#e.stopImmediatePropagation! # focusin bubbles
				else
					# operate
					B.focused = true
					B.root.classList.add 'f'
					# callback
					B.onFocus true, B if B.onFocus
			# }}}
			unfocus: (B) -> (e) !-> # blur {{{
				# prepare
				e.preventDefault!
				# check
				if B.focused
					# operate
					B.focused = false
					B.root.classList.remove 'f'
					# callback
					B.onFocus false, B if B.onFocus
			# }}}
			# aggregators
			slaveFocusInOut: (block, node) -> # {{{
				return [
					(e) !~>
						# focusin handler
						# check
						if block.locked
							# prevent
							e.preventDefault!
							e.stopPropagation!
						else
							# operate
							block.focused = true
							node.classList.add 'f'
							# callback
							if block.onFocus
								block.onFocus true, block
						###
					(e) !~>
						# focusout handler
						# operate
						block.focused = false
						node.classList.remove 'f'
						# callback
						e @, false if e = @onFocus
						###
				]
			# }}}
			slaveFocusAggregator: (block) -> # {{{
				bounce = newDelay!
				return (v, o) ->>
					# bounce
					bounce.cancel! if bounce.pending
					if o and not (await bounce := newDelay 64)
						return false
					# check
					if (w = block.focused) == v
						return false
					# callback
					if o and block.onFocus and not (await block.onFocus v, o)
						return false
					# operate
					if o and block.setFocus
						block.setFocus v
					else
						block.focused = v
						block.root.classList.remove 'f'+w if w
						block.root.classList.add 'f'+v
					# done
					return true
			# }}}
		# }}}
		dom: # {{{
			append: (box, item) -> # {{{
				if not (box instanceof Element)
					if not (box = box.root)
						return null
				if item instanceof Array
					for a in item
						if a instanceof Element
							box.appendChild a
						else if a.root
							box.appendChild a.root
				else if item instanceof Element
					box.appendChild item
				else if item.root
					box.appendChild item.root
				###
				return item
			# }}}
		# }}}
		button: do -> # {{{
			Block = (root, o) !-> # {{{
				# base
				@root    = root
				# state
				@hovered = false
				@focused = false
				@pending = null
				@locked  = true
				# traps
				@onHover = o.onHover or null
				@onFocus = o.onFocus or null
				@onClick = o.onClick or null
				@onPress = o.onPress or null
				# handlers (attach)
				a = 'addEventListener'
				e = w3ui.event
				root[a] 'pointerenter', e.hover @
				root[a] 'pointerleave', e.unhover @
				root[a] 'focus', e.focus @
				root[a] 'blur', e.unfocus @
				root[a] 'click', (e) !~>> # {{{
					# prepare
					e.preventDefault!
					e.stopPropagation!
					# check
					if not @locked and not @pending and @onClick
						# callback
						if (e = @onClick @) instanceof Promise
							# lock
							@pending = e
							@root.classList.add 'w'
							# wait complete
							await e
							# unlock
							@pending = null
							@root.classList.remove 'w'
				# }}}
			Block.prototype =
				lock: (flag = true) !-> # {{{
					# check
					if @locked != flag
						# operate
						@root.classList.toggle 'v', !(@locked = flag)
						if flag or ~@current or ~@cfg.intermediate
							@root.disabled = flag
				# }}}
			# }}}
			return (o = {}) -> # {{{
				# construct
				a = document.createElement 'button'
				a.type      = 'button'
				a.disabled  = true
				a.className = 'w3-button'+((o.name and ' '+o.name) or '')
				if o.hint
					a.setAttribute 'title', o.hint
				if o.label
					b = document.createElement 'label'
					b.textContent = o.label
					a.appendChild b
				else if o.html
					a.innerHTML = o.html
				# complete
				return new Block a, o
			# }}}
		# }}}
	<<<<
		menu: do -> # {{{
			template = w3ui.template !-> # {{{
				/*
				<div class="item">
					<label></label><hr>
					<div class="dropdown"></div>
				</button>
				*/
			# }}}
			Item = (block, node, parent) !-> # {{{
				# base
				@block  = block
				@node   = node
				@parent = parent
				# controls
				# ...
				# state
				# ...
				# handlers
				# ...
			Item.prototype =
				init: !-> # {{{
				# }}}
			# }}}
			Block = (root, o) !-> # {{{
				# base
				@root = root
				@cfg  = o
				# state
				# ...
				# traps
				# ...
				# handlers
				# ...
			Block.prototype =
				init: !-> # {{{
					# ...
				# }}}
				lock: (locked) !-> # {{{
					true
				# }}}
			# }}}
			return (root, o) ->
				true
		# }}}
		checkbox: do -> # {{{
			template = w3ui.template !-> # {{{
				/*
				<button type="button" class="sm-checkbox" disabled>
				<svg preserveAspectRatio="none" viewBox="0 0 48 48">
					<circle class="a" cx="24" cy="24" r="12"/>
					<path class="b" d="M24 6a18 18 0 110 36 18 18 0 010-36zm0 6a12 12 0 110 24 12 12 0 010-24z"/>
					<path class="c" d="M24 4a20 20 0 110 40 20 20 0 010-40zm0 2a18 18 0 110 36 18 18 0 010-36z"/>
					<path class="d" d="M48 27v-6H0v6z"/>
					<path class="e" d="M27 48V0h-6v48z"/>
				</svg>
				</button>
				*/
			# }}}
			Block = (root, cfg) !-> # {{{
				# base
				@root = root
				@cfg  = cfg
				# state
				@current  = -2 # -2=initial -1=intermediate, 0=off, 1=on
				@hovered  = false
				@focused  = false
				@locked   = true
				# traps
				@onHover  = null
				@onFocus  = null
				@onChange = null
				# handlers
				@hover = (e) !~>> # {{{
					# pprepare
					e.preventDefault!
					# check
					if not @locked
						# operate
						if not @onHover or (await @onHover @, true)
							@setHovered true
				# }}}
				@unhover = (e) !~>> # {{{
					# prepare
					e.preventDefault!
					# operate
					if not @onHover or (await @onHover @, false)
						@setHovered false
				# }}}
				@focus = (e) !~>> # {{{
					# check
					if @locked
						# try to prevent
						e.preventDefault!
						e.stopPropagation!
					else
						# operate
						if not @onFocus or (await @onFocus @, true)
							@setFocused true
				# }}}
				@unfocus = (e) !~>> # {{{
					# prepare
					e.preventDefault!
					# operate
					if not @onFocus or (await @onFocus @, false)
						@setFocused false
				# }}}
				@click = (e) !~> # {{{
					# prepare
					e.preventDefault!
					e.stopPropagation!
					# check
					if not @locked and (~@current or ~@cfg.intermediate)
						# operate
						@event!
				# }}}
				@event = !~>> # {{{
					# determine new current
					c = if ~(c = @current)
						then 1 - c # switch 0<=>1
						else @cfg.intermediate # escape
					# should be focused
					@root.focus! if not @focused
					# operate
					if not @onChange or (await @onChange @, c)
						@set c
					# done
				# }}}
			Block.prototype =
				init: (v = -1) !-> # {{{
					# set current state
					@set v
					@root.classList.add 'i' if ~@cfg.intermediate
					# set traps
					if a = @cfg.master
						@onHover = a.onHover if not @onHover
						@onFocus = a.onFocus if not @onFocus
					# set events
					a = @root
					b = 'addEventListener'
					a[b] 'pointerenter', @hover
					a[b] 'pointerleave', @unhover
					a[b] 'focusin', @focus
					a[b] 'focusout', @unfocus
					a[b] 'click', @click
					# done
				# }}}
				lock: (flag = true) !-> # {{{
					if @locked != flag
						@root.classList.toggle 'v', !(@locked = flag)
						if flag or ~@current or ~@cfg.intermediate
							@root.disabled = flag
				# }}}
				set: (v) -> # {{{
					# check
					if @current == v
						return v
					# set style
					if (i = @current + 1) >= 0
						@root.classList.remove 'x'+i
					@root.classList.add 'x'+(v + 1)
					# complete
					return @current = v
				# }}}
				setHovered: (v) -> # {{{
					# check
					if @hovered == v
						return false
					# operate
					@hovered = v
					@root.classList.toggle 'h'
					return true
				# }}}
				setFocused: (v) -> # {{{
					# check
					if @focused == v
						return false
					# operate
					@focused = v
					@root.classList.toggle 'f'
					return true
				# }}}
			# }}}
			return (o = {}) ->
				# prepare
				o.intermediate = if o.intermediate
					then o.intermediate
					else -1 # disabled
				# construct
				a = document.createElement 'template'
				a.innerHTML = template
				a = a.content.firstChild # button
				a.innerHTML = o.svg if o.svg
				# create a block
				return new Block a, o
		# }}}
		select: do -> # {{{
			template = w3ui.template !-> # {{{
				/*
				<svg preserveAspectRatio="none" shape-rendering="geometricPrecision" viewBox="0 0 48 48">
					<polygon class="b" points="24,32 34,17 36,16 24,34 "/>
					<polygon class="b" points="24,34 12,16 14,17 24,32 "/>
					<polygon class="b" points="34,17 14,17 12,16 36,16 "/>
					<polygon class="a" points="14,17 34,17 24,32 "/>
				</svg>
				*/
			# }}}
			Block = (root, select) !-> # {{{
				# base
				@root     = root
				@select   = select
				# state
				@current  = -1
				@hovered  = false
				@focused  = false
				@locked   = true
				# traps
				@onHover  = null
				@onFocus  = null
				@onChange = null
				# handlers
				@hover = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if not @locked and not @hovered
						@hovered = true
						@root.classList.add 'h'
						e @ if e = @onHover
				# }}}
				@unhover = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if @hovered
						@hovered = false
						@root.classList.remove 'h'
						e @ if e = @onHover
				# }}}
				@focus = (e) !~> # {{{
					if @locked
						# try to prevent
						e.preventDefault!
						e.stopPropagation!
					else if not @focused
						# opearate
						@focused = true
						@root.classList.add 'f'
						e @ if e = @onFocus
				# }}}
				@unfocus = (e) !~> # {{{
					# fulfil event
					e.preventDefault!
					# operate
					if @focused
						@focused = false
						@root.classList.remove 'f'
						e @ if e = @onFocus
				# }}}
				@input = (e) !~> # {{{
					# prepare
					e.preventDefault!
					# check
					if @locked or \
					   ((e = @onChange) and not (e @select.selectedIndex))
						###
						# change is not allowed
						@select.selectedIndex = @current
					else
						# update current
						@current = @select.selectedIndex
				# }}}
			Block.prototype =
				init: (list = null, index = -1) !-> # {{{
					# set options
					if list
						# create options
						for a in list
							b = document.createElement 'option'
							b.textContent = a
							@select.appendChild b
						# set current
						@current = @select.selectedIndex = index
					else
						# reset and clear options
						@current = @select.selectedIndex = -1
						@select.innerHTML = ''
					# set events
					a = @root
					b = if list
						then 'addEventListener'
						else 'removeEventListener'
					###
					a[b] 'pointerenter', @hover
					a[b] 'pointerleave', @unhover
					a[b] 'focusin', @focus
					a[b] 'focusout', @unfocus
					a[b] 'input', @input
				# }}}
				lock: (locked) !-> # {{{
					if @locked != locked
						@root.classList.toggle 'v', !(@locked = locked)
						@select.disabled = locked
				# }}}
				set: (i) -> # {{{
					@current = @select.selectedIndex = i if i != @current
					return i
				# }}}
				get: -> # {{{
					return @current
				# }}}
			# }}}
			return (o = {}) ->
				# create a container
				a = document.createElement 'div'
				a.className = BRAND+'-select'
				a.innerHTML = if o.hasOwnProperty 'svg'
					then o.svg
					else template
				# create a select
				b = document.createElement 'select'
				a.appendChild b
				# create block
				return new Block a, b
		# }}}
		section: do -> # {{{
			Title = (node) !-> # {{{
				@root  = node
				@box   = node = node.firstChild
				@h3    = node.children.0
				@arrow = node.children.1
				@label = @h3.firstChild
			# }}}
			Item = (block, node, parent) !-> # {{{
				# base
				@block  = block
				@node   = node
				@parent = parent
				@config = cfg = JSON.parse node.dataset.cfg
				# controls
				@title    = new Title (querySelectorChild node, '.title')
				@extra    = null # title extension
				@section  = sect = querySelectorChild node, '.section'
				@children = c = querySelectorChildren sect, '.item'
				# construct recursively
				if c
					for a,b in c
						c[b] = new Item block, a, @
				# state
				@hovered = 0 # 1=arrow 2=extra
				@focused = 0
				@opened  = false
				@locked  = true
				# handlers
				hoverBounce = newDelay!
				focusBounce = newDelay!
				@onHover = (e, hovered) ~>> # {{{
					# bounce
					hoverBounce.cancel! if hoverBounce.pending
					if await hoverBounce := newDelay 66
						# determine hover variant
						a = @title.arrow
						x = @extra
						hovered = if not hovered
							then 0
							else if not x or e == a
								then 1 # arrow
								else 2 # extra
						# check
						if hovered != (h = @hovered)
							# operate
							# update value
							@hovered = hovered
							# set children
							if hovered == 1
								x.setHovered false if h
								a.classList.add 'h'
							else if hovered == 2
								x.setHovered true
								a.classList.remove 'h' if h
							else if h == 2
								x.setHovered false
							else
								a.classList.remove 'h'
							# set self
							a = @node.classList
							a.remove 'h'+h if h
							a.add 'h'+hovered if hovered
							# callback
							if (not hovered or not h) and @block.onHover
								@block.onHover @, hovered
					# done
					return false
				# }}}
				@onFocus = (e, focused) ~>> # {{{
					# bounce
					focusBounce.cancel! if focusBounce.pending
					if await focusBounce := newDelay 66
						# determine focus variant
						a = @title.arrow
						x = @extra
						focused = if not focused
							then 0
							else if not x or e == a
								then 1 # arrow
								else 2 # extra
						# check
						if focused != (f = @focused)
							# operate
							@focused = focused
							@node.classList.toggle 'f', !!focused
							# callback
							if @block.onFocus
								@block.onFocus @, focused
					# done
					return true
				# }}}
				@focus = (e) !~> # {{{
					# prepare
					e.preventDefault!
					# operate
					if not @locked
						(e = @title.arrow).classList.add 'f'
						@onFocus e, true
				# }}}
				@unfocus = (e) !~> # {{{
					# prepare
					e.preventDefault!
					# operate
					(e = @title.arrow).classList.remove 'f'
					@onFocus e, false
				# }}}
				@keydown = (e) ~> # {{{
					# check
					if @locked
						return false
					# check
					switch e.keyCode
					case 38,75 # Up,k
						# focus up
						# find arrow above current item
						if e = @searchArrow true
							e.title.arrow.focus!
						###
					case 40,74 # Down,j
						# find arrow below current item
						if e = @searchArrow false
							e.title.arrow.focus!
						###
					case 37,72,39,76 # Left,h,Right,l
						# switch section
						@onSwitch! if @section
						console.log 'open/close section?'
						###
					default
						return false
					# handled
					e.preventDefault!
					e.stopPropagation!
					return true
				# }}}
			Item.prototype =
				init: !-> # {{{
					# configure
					@opened = @config.opened
					@title.label.textContent = a if a = @config.name
					# attach title
					b = 'addEventListener'
					a = @title.h3
					a[b] 'pointerenter', @hover a
					a[b] 'pointerleave', @unhover a
					a[b] 'click', @click a
					a = @title.arrow
					a[b] 'pointerenter', @hover a
					a[b] 'pointerleave', @unhover a
					a[b] 'click', @click a
					a[b] 'focusin', @focus
					a[b] 'focusout', @unfocus
					a[b] 'keydown', @keydown
					# set styles
					a = 'e'+((@extra and '1') or '0')
					b = 'o'+((@opened and '1') or '0')
					@node.classList.add a, b
					@title.arrow.classList.add 'v' if @config.arrow
					@extra.root.classList.add 'extra' if @extra
					# recurse to children
					if a = @children
						for b in a
							b.init!
				# }}}
				lock: (flag) -> # {{{
					# check
					if @locked != flag
						# operate
						@locked = flag
						@node.classList.toggle 'v', !flag
						if a = @title
							a.arrow.disabled = flag
						if a = @extra
							a.lock flag
					# recurse to children
					if a = @children
						for b in a
							b.lock flag
					# done
					return flag
				# }}}
				hover: (o) -> (e) !~> # {{{
					# prepare
					e.preventDefault!
					# operate
					if not @locked
						@onHover o, true
				# }}}
				unhover: (o) -> (e) !~> # {{{
					# prepare
					e.preventDefault!
					# operate
					@onHover o, false
				# }}}
				click: (o) -> (e) !~>> # {{{
					# prepare
					e.preventDefault!
					# check
					if not @locked
						# operate
						if @extra and o == @title.h3
							# trigger extra
							@extra.event!
						else if @section
							# switch value
							e = !@opened
							if not @block.onChange or (await @block.onChange @, e)
								@set e
							# should be focused
							@title.arrow.focus! if not @focused
				# }}}
				set: (v) -> # {{{
					# check
					if @opened == v
						return false
					# operate
					@opened = v
					v = (v and 1) or 0
					@node.classList.remove 'o'+(1 - v)
					@node.classList.add 'o'+v
					# done
					return true
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
			Block = (root) !-> # {{{
				# base
				@root    = root
				@rootBox = box = root.firstChild
				# controls
				@lines   = querySelectorChildren box, 'svg'
				@item    = root  = new Item @, box, null
				@sect    = sect  = {}     # with section (parents)
				@items   = items = {}     # all
				@list    = list  = [root] # all ordered
				# assemble items tree in rendered order
				a = -1
				while ++a < list.length
					if (b = list[a]).children
						sect[b.config.id] = b
						list.push ...b.children
					items[b.config.id] = b
				# state
				@hovered  = false
				@focused  = false
				@locked   = true
				# traps
				@onHover  = null
				@onFocus  = null
				@onChange = null
			###
			Block.prototype =
				init: (title) !-> # {{{
					# set title
					if not @item.config.name and title
						@item.title.label.textContent = title
					# initialize
					@item.init!
				# }}}
				lock: (flag = true) !-> # {{{
					if @locked != flag
						@locked = @item.lock flag
				# }}}
			# }}}
				/***
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
				/***/
			return (o) ->
				return new Block o
		# }}}
	# }}}
	S = # slaves
		productCard: do -> # {{{
			init  = newPromise!
			sizes = null # dimensions of the card elements
			template = w3ui.template !-> # {{{
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
						<div class="actions"></div>
					</div>
				</div>
				*/
			# }}}
			section = # {{{
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
					TCartIcon = w3ui.template !-> # {{{
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
						@buttons = btn = w3ui.dom.append box, [
							w3ui.button {
								name: 'add'
								html: TCartIcon
								hint: cfg.locale.hint.0
								onClick: @addToCart!
							}
							w3ui.button {
								name: 'open'
								label: cfg.locale.label.1
								onClick: @openDetails!
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
						addToCart: -> ~>> # {{{
							# TODO: miniCart block
							# update cart data
							a = @block.master.group.config.cart
							b = @block.data
							if c = a[b.id]
								c.count += 1
							else
								a[b.id] = {count: 1}
							# refresh view
							@set b
							# send request
							c = await goFetch {
									action: 'a_CartAdd'
									params: [@block.data.id, 1]
							}
							# check
							if c instanceof Error
								# restore previous view
								a[b.id].count -= 1
								@set b
								return false
							# notify woo mini-cart
							a = jQuery document.body
							a.trigger 'added_to_cart', c
							# done
							return true
						# }}}
						openDetails: -> ~>> # {{{
							# TODO: productDetails block
							# naviagate the link
							window.location.assign @block.data.link
							await newDelay 20000
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
			Items = (block) !-> # {{{
				cfg = block.master.group.config
				for a of section
					@[a] = new section[a] block, cfg
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
	M = # masters
		'products': do -> # {{{
			Resizer = (block) !-> # {{{
				# create object shape
				@block    = block
				@style    = getComputedStyle block.rootBox
				###
				@pads     = [0,0,0] # container padding [left+right,top+bottom,bottom]
				@gaps     = [0,0]   # column,row
				@sizes    = [0,0,0] # item's width,height,dot-height
				@layout   = [0,0]   # current columns,rows
				@factor   = 1       # current size factor
				@ready    = newPromise! # current state promise
				@i_opt    = {       # intersection options
					root: null        # window
					rootMargin: '0px' # no margin
					threshold: [0,0,1]# middle will be determined
				}
				@s_opt    = [
					-1 # previous scroll position, -1=foot start, -2=foot end
					{behavior: 'smooth', top: 0} # foot end
					{behavior: 'auto', top: 0} # foot start
				]
				###
				@onChange = null    # master resizer callback
				@observer = null    # [resize,intersect]
				@intense  = newDelay! # scroll throttler
				@dot      = newPromise! # intersect promise
				@debounce = newDelay!
				@bounces  = 0       # for more gradual control
				@resize = (e) ~>> # {{{
					# check mode
					if e
						# observed,
						# apply debounce algorithm
						if @debounce.pending
							@debounce.cancel (++@bounces == 3)
						if not await (@debounce = newDelay 100)
							return false
						@bounces = 0
						# get width of the grid
						w = e.0.contentRect.width
					else
						# forced,
						# determine width of the grid
						w = @block.root.clientWidth - @pads.0
					# assuming no size factor applied,
					# determine column count and space they take
					[a,b] = @getCols w, 1
					# calculate size factor
					e = c = if b > w
						then w / b # reduced
						else 1     # normal
					# check master control
					if @onChange
						# callback master
						if (e = @onChange e) < c
							# in case a smaller factor given,
							# re-calculate columns
							[a,b] = @getCols w, e
					else if (Math.abs (@factor - e)) > 0.005
						# update
						@factor = e
						# set inline style
						b = '--sm-size-factor'
						c = @block.root.style
						if e == 1
							c.removeProperty b
						else
							c.setProperty b, e
					# update layout
					if (c = @layout).0 != a
						@block.root.style.setProperty '--columns', (c.0 = a)
						c.1 and @block.setCount (a * c.1)
					# done
					return true
				# }}}
				@intersect = (e) ~>> # {{{
					# fixed rows
					# {{{
					a = @block.config.layout
					if (c = @block.rows) or (c = a.1) == a.3
						# update
						if (a = @layout).1 != c
							@block.root.style.setProperty '--rows', (a.1 = c)
							a.0 and @block.setCount (a.0 * c)
						# done
						return true
					# }}}
					# dynamic rows
					# check locked
					if @dot.pending or not e
						console.log 'intersect skip'
						return true
					# prepare
					e = e.0.intersectionRatio
					o = @layout
					c = o.1
					b = a.3
					a = a.1
					# get scrollable container (aka viewport)
					if not (w = v = @i_opt.root)
						w = window
						v = document.documentElement
					# get viewport, row and dot heights
					h = v.clientHeight
					y = (@gaps.1 + @sizes.1) * @factor
					z = (@sizes.2 * @factor)
					# determine scroll parking point (dot offset),
					# which must be smaller than threshold trigger
					x = z * (1 - @i_opt.threshold.1 - 0.01) .|. 0
					# handle finite scroll
					# {{{
					if b
						# ...
						return true
					# }}}
					# handle infinite scroll
					# {{{
					# fill the viewport (extend scroll height)
					b = v.scrollHeight
					if e and b < h + z
						# determine exact minimum
						e  = Math.ceil ((b - c*y - z) / y)
						c += e
						b += y*e
						# update
						@block.root.style.setProperty '--rows', (o.1 = c)
						if o.0 and @block.setCount (o.0 * c) and @ready.pending
							@ready.resolve!
						# adjust scroll position
						@s_opt.0 = v.scrollTop
						@s_opt.1.top = b - h - x
						@s_opt.2.top = b - h - z
						# wait repositions (should be cancelled)
						await (@dot = newPromise -1)
						@observer.1.disconnect!
						@observer.1.observe @block.dot
						# done
						return true
					# adjust the viewport
					while e
						# determine scroll options and
						# set scroll (after increment)
						@s_opt.1.top = b - h - x
						@s_opt.2.top = b - h - z
						if e > 0
							w.scrollTo @s_opt.1
						else if @s_opt.0 == -2
							w.scrollTo @s_opt.2
						# determine decrement's trigger point
						i = @s_opt.1.top - y - @pads.2
						# wait triggered
						if not (e = await (@dot = newPromise i))
							break
						# check
						if e == 1
							# increment,
							# TODO: uncontrolled?
							c += 1
							b += y
						else
							# decrement,
							# determine intensity value
							i = 1 + (i - v.scrollTop) / y
							e = -(i .|. 0)
							console.log 'decrement', e
							# apply intensity
							c += e
							b += y*e
							# apply limits
							while c < a or b < h + z
								c += 1
								b += y
								i -= 1
								e  = 0 # sneaky escape (after update)
							# check exhausted
							if c == o.1
								console.log 'decrement exhausted'
								break
							# check last decrement
							if e and b - y < h + z and b - z > h + v.scrollTop
								e = 0
							# apply scroll adjustment (dot start)
							if (i - (i .|. 0))*y < (z - x + 1)
								if e
									console.log 'scroll alignment'
									@s_opt.0 = -2
								else
									console.log 'scroll alignment last'
									w.scrollTo @s_opt.2
						# update
						@block.root.style.setProperty '--rows', (o.1 = c)
						if o.0 and @block.setCount (o.0 * c) and @ready.pending
							@ready.resolve!
						# continue..
					# }}}
					# done
					return true
				# }}}
				@scroll = (e) ~>> # {{{
					# check intersection locked (upper limit determined)
					if not (a = @dot.pending)
						console.log 'scroll skip'
						return true
					# increase intensity
					if @intense.pending
						@intense.pending += 1
						return false
					# skip first scroll (programmatic)
					c = @s_opt.2.top
					d = @s_opt.1.top
					if (b = @s_opt.0) < 0
						console.log 'first scroll skip'
						@s_opt.0 = if ~b
							then c
							else d
						return false
					# get scrollable container (aka viewport)
					e = @i_opt.root or document.documentElement
					i = if e.scrollTop > b
						then 60  # increase
						else 100 # decrease
					# throttle (lock and accumulate)
					while (await (@intense = newDelay i, 1)) > 1
						true
					# get current position
					e = e.scrollTop
					# check changed
					if (Math.abs (e - b)) < 0.2
						console.log 'small scroll skip'
						return true
					# save position
					@s_opt.0 = e
					# reposition?
					console.log 'reposition?', e, b, c, d
					if b > c + 1 and e < b and e > c - 1
						# exit (dot start)
						@s_opt.0 = -2
						a = window if not (a = @i_opt.root)
						a.scrollTo @s_opt.2
						console.log 'exit', @s_opt.2.top
						return true
					if b < d - 1 and e > b and e > c
						# enter (dot trigger)
						@s_opt.0 = -1
						a = window if not (a = @i_opt.root)
						a.scrollTo @s_opt.1
						console.log 'enter', @s_opt.1.top
						return true
					# increment?
					if e > d
						# reset and resolve positive
						console.log 'increment'
						@s_opt.0 = -1
						@dot.resolve 1
						return true
					# cancellation?
					if a < 0
						# negative upper limit means decrement is not possible
						# reset and cancel scroll observations
						console.log 'cancelled'
						@s_opt.0 = -1
						@dot.resolve 0
						return true
					# decrement?
					if e < a
						# resolve negative
						@dot.resolve -1
					# done
					return true
				# }}}
			###
			Resizer.prototype =
				attach: !-> # {{{
					# prepare
					# determine container paddings
					s    = getComputedStyle @block.root
					a    = @pads
					a.0  = parseInt (s.getPropertyValue 'padding-left')
					a.0 += parseInt (s.getPropertyValue 'padding-right')
					a.1  = parseInt (s.getPropertyValue 'padding-top')
					a.2  = parseInt (s.getPropertyValue 'padding-bottom')
					a.1 += a.2
					# determine gaps
					s   = @style
					a   = @gaps
					a.0 = parseInt (s.getPropertyValue '--column-gap')
					a.1 = parseInt (s.getPropertyValue '--row-gap')
					# determine item size
					a   = @sizes
					a.0 = parseInt (s.getPropertyValue '--item-width')
					a.1 = parseInt (s.getPropertyValue '--item-height')
					a.2 = a.1 + @gaps.1
					# determine dot intersection threshold
					a = parseFloat (s.getPropertyValue '--foot-size')
					@i_opt.threshold.1 = a / 100
					# initialize
					# set default layout
					a = @block.config.layout
					@layout.0 = a.0 # max
					@layout.1 = a.1 # min
					# create observers
					@observer = a = [
						new ResizeObserver @resize
						new IntersectionObserver @intersect, @i_opt
					]
					a.0.observe @block.root
					a.1.observe @block.dot
					# set scroll handler
					a = @i_opt.root or window
					a.addEventListener 'scroll', @scroll
					# dot must be resolved
					@dot.resolve 0
				# }}}
				getCols: (w, e) -> # {{{
					# parameters: available (w)idth, siz(e) factor
					# prepare
					C = @block.config.layout
					a = e * @sizes.0
					b = e * @gaps.0
					# check
					if (c = C.0) == C.2 or not C.2
						# fixed,
						# calculate horizontal size with gaps
						d = c*a + (c - 1)*b
					else
						# dynamic,
						# decrement until minimum reached
						while (d = c*a + (c - 1)*b) > w and c > C.2
							--c
					# done
					return [c,d]
				# }}}
				refresh: ->> # {{{
					# update layout
					await @resize! # columns
					await @intersect! # rows
					# done
					return true
				# }}}
				detach: !-> # {{{
					# remove observers
					if o = @observer
						@observer = null
						o.0.disconnect!
						o.1.disconnect!
					# reset
					@ready = newPromise!
				# }}}
			# }}}
			refresher = (block) !-> # {{{
				e = jQuery document.body
				e.on 'removed_from_cart', (e, frags) !->
					# prepare
					frags = frags['div.widget_shopping_cart_content']
					cart  = block.group.config.cart
					items = block.items
					# iterate
					for a,b of cart when b.count
						# search item in the fragments
						if (frags.indexOf 'data-product_id="'+a+'"') == -1
							# zap
							b.count = 0
							# search product in view
							e = -1
							while ++e < block.count
								if items[e].data.id == a
									items[e].refresh!
				###
			# }}}
			Block = (root) !-> # {{{
				# base
				@group   = 'range'
				@root    = root
				@rootBox = box = root.firstChild
				@config  = cfg = JSON.parse box.dataset.cfg
				# controls
				@dot     = querySelectorChild root, 'hr'
				@items   = [] # product cards
				@resizer = new Resizer @
				# state
				@range   = [
					0,   # primary offset (first record index)
					0,0, # forward range: offset,count
					0,0  # backward range
				]
				@rows    = -1 # fixed number of rows, 0=auto, -1=init
				@count   = 0  # items displayed
				@page    = 0  # approximated max number of items in the viewport
				@bufA    = [] # forward buffer
				@bufB    = [] # backward buffer
				@offset  = [  # buffer offset state
					0, # primary range offset (for update check)
					0, # current buffer offset (center point)
					0  # buffer validity flag (for load)
				]
				@charged = 0
				@locked  = -1
			###
			Block.prototype =
				level: 1
				init: (s, c) -> # {{{
					# set state and config
					c.order = a if a = @config.options
					s.order = a if a = @config.order
					s.range = @range
					c.rows  = (o = @config.layout).1 # refresh guarantee
					c.count = o.0 * o.1 # minimal
					# activate resizer
					@resizer.attach!
					# TODO: activate refresher (refactor)
					refresher @
					# approximate maximal viewport capacity (page buffer)
					s = window.screen
					s = if (a = s.availWidth) > (b = s.availHeight)
						then a
						else b
					s = Math.ceil (s / @resizer.sizes.1)
					@page = 5 * o.0 * s # x5 zoom factor (x4=25% considered max)
					# create items (page)
					a = @page + 1
					b = @items
					while --a
						b[*] = @group.f.productCard @
					# set initial range and items count
					@setRange 0
					@setCount c.count
					# done
					return true
				# }}}
				refresh: ->> # {{{
					# check rows
					if @rows != (a = @group.config.rows)
						# set dot display
						if @rows and not a
							@dot.classList.add 'v'
						else if not @rows and a
							@dot.classList.remove 'v'
						# update value and refresh layout
						@rows = a
						await @resizer.refresh!
					# check offset
					if (a = @range.0) != @offset.0
						# update primary value
						@offset.0 = a
						# update buffer
						if @setBuffer!
							@offset.1 = a # update buffer offset
							@offset.2 = 0 # invalidate buffer
							@charged++
							@group.submit @
					else
						# confirm buffer validity
						@offset.2 = 1
					# done
					return true
				# }}}
				notify: (level) -> # {{{
					# skip own charge
					if @charged
						--@charged
						return 0
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
					return 0
				# }}}
				setRange: (o, gaps) !-> # {{{
					# prepare
					a = @range
					c = @page
					n = @group.config.total
					# operate
					if not ~n
						# the total is not determined,
						# backend will determine proper range,
						# set special offset
						a.0 = o
						a.1 = a.3 = -1
						a.2 = a.4 = c
						###
					else if gaps
						# buffer replenishment required,
						# shift offsets to fill the gaps
						a.0 = o
						if (b = @bufA.length) < c
							if (a.1 = o + b) >= n
								a.1 = a.1 - n
							a.2 = c - b
						else
							a.1 = a.2 = 0
						if (b = @bufB.length) < c
							if (a.3 = o - 1 - b) < 0
								a.3 = a.3 + n
							a.4 = c - b
						else
							a.3 = a.4 = 0
						###
					else
						# default range (n > c + c)
						a.0 = a.1 = o
						a.2 = a.4 = c
						a.3 = if o
							then o - 1
							else n - 1
						###
				# }}}
				setCount: (count) -> # {{{
					# prepare
					a = @items
					c = @count
					n = @group.config.total
					# check
					if c == count
						# no change
						return false
						###
					else if c < count
						# rise, rise
						# create items first
						while a.length < count
							a[*] = @group.f.productCard @
						# determine initial shift size and direction
						o = @offset
						c = c - 1
						if (d = o.0 - o.1) >= 0
							d = d - n if d > @page
						else
							d = d + n if d < -@page
						# operate
						while ++c < count
							# TODO: fix
							# determine item's location in the buffer
							i = c + d
							if d >= 0
								# forward buffer
								b = @bufA[i]
							else if i >= 0
								# last page is not aligned with the total and
								# wrap around option may prescribe to display
								# records from the first page, blanks otherwise
								b = if @config.wrapAround
									then @bufA[i]
									else null
							else
								# backward buffer
								i = -i - 1
								b = @bufB[i]
							# set content (may be empty)
							a[c].set b
							a[c].root.classList.add 'v'
						###
					else
						# reduce display count
						while c > count
							a[--c].root.classList.remove 'v'
						###
					# check group configuration
					if (@count = c) != @group.config.count
						# refresh other blocks
						@group.config.count = c
						@group.refresh @
					# done
					return true
				# }}}
				setBuffer: -> # {{{
					# prepare
					A = @bufA
					B = @bufB
					R = @range
					a = A.length
					b = B.length
					c = @group.config.total
					d = @page
					o = @offset.0
					O = @offset.1
					# determine offset deviation
					if (i = o - O) > 0 and c - i < i
						i = i - c # swap to backward
					else if i < 0 and c + i < -i
						i = c + i # swap to forward
					# check out of range
					if (Math.abs i) > d + d - 1
						@clearBuffer!
						return 2
					# determine steady limit
					d = d .>>>. 1
					# check steady
					if i == 0 or (i > 0 and d - i > 0)
						# forward {{{
						# update items
						j = -1
						while ++j < @count
							if i < a
								@items[j].set A[i++]
							else
								@items[j].set!
						# }}}
						return 0
					if i < 0 and d + i >= 0
						# backward {{{
						# update items
						j = -1
						k = -i - 1
						while ++j < @count
							if k >= 0 and b - k > 0
								@items[j].set B[k]
							else if k < 0 and a + k > 0
								# option: the count of displayed items may not align
								# with the total count, so, the last page may show
								# records from forward buffer
								if @config.wrapAround
									@items[j].set A[-k - 1]
								else
									@items[j].set!
							else
								@items[j].set!
							--k
						# }}}
						return 0
					# check partial penetration
					if i > 0 and a - i > 0
						# forward {{{
						# [v|v|v|v]
						#   [v|v|v|x]
						# avoid creation of sparse array
						j = b
						while j < i
							B[j++] = null
						# rotate buffer forward
						j = i
						k = 0
						while k < b and j < @page
							B[j++] = B[k++]
						B.length = j
						j = i - 1
						k = 0
						while ~j
							B[j--] = A[k++]
						#j = -1
						#k = i
						while k < a
							A[++j] = A[k++]
						A.length = k = j + 1
						# update items (last to first)
						j = @count
						while j
							if --j < k
								@items[j].set A[j]
							else
								@items[j].set!
						# update range
						@setRange o, true
						# }}}
						return 1
					if i < 0 and b + i > 0
						# backward {{{
						#   [v|v|v|v]
						# [x|v|v|v]
						# avoid creation of sparse array
						i = -i
						j = a
						while j < i
							A[j++] = null
						# rotate buffer backward
						j = i
						k = 0
						while k < a and j < @page
							A[j++] = A[k++]
						A.length = j
						j = i - 1
						k = 0
						while ~j
							A[j--] = B[k++]
						#j = -1
						#k = i
						while k < b
							B[++j] = B[k++]
						B.length = j + 1
						# update items display (first to last)
						j = -1
						k = A.length
						while ++j < @count
							if j < k
								@items[j].set A[j]
							else
								@items[j].set!
						# update range
						@setRange o, true
						# }}}
						return -1
					# buffer penetrated (wasn't filled enough)
					@clearBuffer!
					return -2
				# }}}
				clearBuffer: !-> # {{{
					# set new range
					@setRange @offset.0
					# clear records
					@bufA.length = @bufB.length = 0
					# clear items
					i = @count
					while i
						@items[--i].set!
					# done
				# }}}
				load: (i, record) -> # {{{
					# check range and buffer are valid
					if not (o = @offset).2
						return false
					# determine where to store this record
					if i < @range.2
						# store forward
						i = @bufA.length
						@bufA[i] = record
						# determine display offset
						i = if (o = o.0 - o.1) >= 0
							then i - o
							else i - @group.config.total - o
						# update item if it's displayed
						if i >= 0 and i < @count
							@items[i].set record
					else
						# store backward
						i = @bufB.length
						@bufB[i] = record
						# determine display offset
						i = if (o = o.1 - o.0) > 0
							then i - o
							else i - @group.config.total - o
						# update item if it's displayed
						if i < 0 and i + @count >= 0
							@items[-i - 1].set record
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
					@lock = lock = newPromise 3
					# set drag style
					R.focus! # solves cursor refresh issue?
					R.box.classList.add 'active', 'drag'
					# cooldown
					await Promise.race [(newDelay 200), lock]
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
					@lock = lock = newPromise if event
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
					L = await Promise.race [(newDelay 200), lock]
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
							L = await Promise.race [(newDelay d), lock]
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
					a = newPromise!
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
							b = '--sm-size-factor'
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
					@baseSz.1 = parseFloat (s.getPropertyValue '--sm-size-height')
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
				@group   = 'range'
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
				level: 1
				init: -> # {{{
					# set control classes
					a = @rootBox.classList
					if @config.range == 2
						a.add 'flexy'
					if not @gotos.sepFL
						a.add 'nosep'
					# set event handlers
					@control.attach!
					@resizer.attach!
					return true
				# }}}
				refresh: -> # {{{
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
					@group.refresh @
				# }}}
				notify: (level) -> # {{{
					return if @control.lock.pending
						then 1
						else 0
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
		'rows-selector': do -> # {{{
			template = w3ui.template !-> # {{{
				/*
				<select></select>
				<svg preserveAspectRatio="none" shape-rendering="geometricPrecision" viewBox="0 0 48 48">
					<polygon class="b" points="24,32 34,17 36,16 24,34 "/>
					<polygon class="b" points="24,34 12,16 14,17 24,32 "/>
					<polygon class="b" points="34,17 14,17 12,16 36,16 "/>
					<polygon class="a" points="14,17 34,17 24,32 "/>
				</svg>
				*/
			# }}}
			Block = (root) !-> # {{{
				# base
				@group   = 'range'
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
				init: (s, c) -> # {{{
					# set config
					c.rows = @config.list[@config.index]
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
					# done
					return true
				# }}}
				refresh: -> # {{{
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
					# done
					return true
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
					@group.refresh @
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
		'orderer': do -> # {{{
			template = w3ui.template !-> # {{{
				/*
				<svg preserveAspectRatio="none" shape-rendering="geometricPrecision" viewBox="0 0 48 48">
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
						B.group.submit B
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
				@group   = 'order'
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
					@group.submit!
					# complete
					return true
				# }}}
				@variantChange = (i) ~> # {{{
					# change
					@group.data.1 = i
					@group.submit!
					# complete
					return true
				# }}}
			###
			Block.prototype =
				level: 1
				init: (s, c) ->> # {{{
					# initialize
					s.order    = @config.order if @config.order
					@options   = o = c.locale.order
					@keys      = k = c.order or (Object.getOwnPropertyNames o)
					@tag       = a = w3ui.select!
					@variant   = b = w3ui.checkbox {svg: template}
					a.onHover  = b.onHover = @hover
					a.onFocus  = b.onFocus = @focus
					a.onChange = @tagChange
					b.onChange = @variantChange
					###
					c = []
					i = -1
					while ++i < k.length
						c[i] = o[k[i]][0] # localized name
					i = k.indexOf s.order.0
					k = s.order.1
					###
					a.init c, i
					b.init k
					# compose self
					o = @rootBox
					o.appendChild b.root
					o.appendChild a.root
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
				refresh: -> # {{{
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
			# }}}
			return Block
		# }}}
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
				wheelLock = newDelay!
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
					if not await (wheelLock := newDelay 17)
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
				@rst = querySelectorChild @svg, '.X'
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
				focusBounce = newDelay 0
				@numFocus = (v, o) ~>> # {{{
					/***/
					# bounce
					focusBounce.cancel! if focusBounce.pending
					if not (await focusBounce := newDelay 66) or @focused == v
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
					if not (await focusBounce := newDelay 66) or @focused == v
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
				@group   = 'price'
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
							@group.submit!
					else
						if ~c.0 or ~c.1
							# disable
							d.0 = d.1 = -1
							@prev = c.slice!
							@group.submit!
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
					@group.submit!
				# }}}
				focusBounce = newDelay 0
				focusLast   = null
				@onFocus = (o, v) ~>> # {{{
					# bounce range only
					if o == @range
						focusBounce.cancel! if focusBounce.pending
						if not (await focusBounce := newDelay 66)
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
				level: 2
				init: (s, c) ->> # {{{
					# initialize
					# group state
					s.price = @current.slice!
					# section
					a = @section = w3ui.section @root
					b = c.locale
					a.onChange = @sectionSwitch if @config.sectionSwitch
					a.onFocus  = @onFocus
					a.init c.locale.title.1
					# range
					a = @range = new NumRange a.item.section.firstChild
					b = [
						c.locale.label.3
						c.locale.label.4
					]
					a.onSubmit = @rangeSubmit
					a.onFocus  = @onFocus
					a.init c.price, c.price, b
					# done
					return true
				# }}}
				refresh: -> # {{{
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
					@group.submit @
					# done
					return false
				# }}}
			###
			Block.prototype =
				level: 2
				init: (s, c) ->> # {{{
					# create group data entry
					s.category[@index] = []
					# create a section
					@section = s = w3ui.section @root
					# add extention (exclude root)
					for a in s.list when a.parent
						# construct
						a.extra = b = w3ui.checkbox {
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
					s.init c.locale.title.0
					return true
				# }}}
				lock: (level) !-> # {{{
					@section.lock true
				# }}}
				unlock: (level) !-> # {{{
					@section.lock false
				# }}}
				refresh: (list) -> # {{{
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
			# }}}
			return Block
		# }}}
		'menu': do -> # {{{
			Block = (root) !-> # {{{
				# base
				@group   = 'route'
				@root    = root
				@rootBox = box = root.firstChild
				@cfg     = null
				# controls
				# ...
				# state
				@hovered = false
				@focused = false
				@locked  = -1
				# handlers
				# ...
			###
			Block.prototype =
				level: 3
				init: (s, c) ->> # {{{
					# ...
					debugger
					return true
				# }}}
				lock: (level) !-> # {{{
					true
				# }}}
				unlock: (level) !-> # {{{
					true
				# }}}
				refresh: -> # {{{
					return true
				# }}}
			# }}}
			return Block
		# }}}
	# supervisor
	return do -> # {{{
		Config = !-> # {{{
			@locale   = null  # interface labels, titles, etc
			@routes   = null  # {navigation}
			@order    = null  # order tags to use for ordering
			@currency = null  # [symbol,decimal_sep,thousand_sep,decimal_cnt]
			@cart     = null  # shopping cart
			@price    = null  # price range [min,max]
			@total    = 0     # ..records in the result
			@count    = 0     # ..of items displayed
			@rows     = 0     # rows in the grid (0=auto, -1=infinite)
		# }}}
		State = !-> # {{{
			@lang     = ''    # two-byte language code
			@route    = 0     # navigation id
			@range    = null  # [offset,limit,o1,o2,o3,o4]
			@order    = null  # [tag,variant]
			@category = []    # [id-1..N],[..],..
			@price    = null  # [min,max]
		# }}}
		Loader = (s) !-> # {{{
			@super  = s     # s-supervisor
			@lock   = null  # loader promise
			@dirty  = -1    # resolved-in-process: 0=clean, -1=soft, 1=hard
			@level  = -1    # update priority
			@fetch  = null  # fetcher promise
		Loader.prototype =
			init: ->> # {{{
				# prepare
				T = window.performance.now!
				S = @super
				# configure request (low -> high)
				for a in S.blocks when a.configure
					a.configure S.state
				# request configuration
				if (c = await goFetch S.state) instanceof Error
					consoleError c.message
					return false
				# store
				for a of c when S.config.hasOwnProperty a
					S.config[a] = c[a]
				# initialize (ordered)
				a = []
				for c in (b = Object.getOwnPropertyNames S.groups)
					a[*] = S.groups[c].init!
				# wait completed and
				# check the results
				for a,c in (await Promise.all a) when not a
					consoleError 'failed to initialize '+S.groups[c].name
					return false
				# refresh (ordered)
				for a in b
					await S.groups[a].refresh!
				# set constructed class
				for a in S.blocks when a.locked == -1
					a.root.classList.add 'v'
					a.locked = 1
				# done
				T = (window.performance.now! - T) .|. 0
				consoleInfo 'initialized in '+T+'ms'
				return true
			# }}}
			finit: !-> # {{{
				# interrupt
				@lock.resolve! if @lock
				@fetch.cancel! if @fetch
				# reset
				@dirty = @level = -1
				@lock  = @fetch = null
			# }}}
			charge: (group) !-> # {{{
				# rise priority
				@level = group.level if @level < group.level
				# check
				if @lock.pending
					# charge clean,
					# start or restart routine
					@lock.resolve (@lock.pending == 1)
				else
					# charge dirty,
					# set flag and terminate fetcher
					@dirty = 1
					@fetch.cancel! if @fetch
				# done
			# }}}
			run: ->>
				# initiate {{{
				# create new lock
				# dirty flag is a guard against excessive queries,
				# resulted by fast, multiple user actions (charges),
				# which are throttled by reasonable delay,
				# except the soft/programmatic restarts made by routine itself,
				# otherwise a lock is clean - instant charge by the user.
				@lock = if @dirty
					then newDelay (~@dirty and 400)
					else newPromise 1
				# wait for the charge
				if not (await @lock)
					return true
				# reset dirty
				@dirty = 0
				# get superviser and priority
				s = @super
				c = @level
				# }}}
				# syncronize {{{
				# this step is skipped first time (after init)
				if ~c
					# query may or may not be executed,
					# but any block should be notified that something is changed
					# iteration order goes from higher levels to lower and
					# allows to restart the process by any master through the callback
					a = s.blocks.length
					while a
						# get instance
						b = s.blocks[--a]
						# operate
						if b.notify and (@dirty = b.notify c)
							return true
					# restart query-less charge
					if not c
						return true
					# lock lower priority blocks (if they are not locked already)
					for b in s.blocks when b.level < c and not b.locked
						# set common property here (block doesn't have to)
						b.locked = 1
						# execute specialized async callback (if present) and
						# collect returned promise
						b.lock c if b.lock
						# clear availability class from the common content container
						b.rootBox.classList.remove 'v'
				# }}}
				# startup {{{
				# send the request
				f = await (@fetch = soFetch s.state)
				@fetch = null
				# check the result
				if f instanceof Error
					# cancelled
					if f.id == 4
						return true
					# fatal
					consoleError f.message
					return false
				# read total records count
				if (s.config.total = a = await f.readInt!) == null
					consoleError 'fetch stream failed'
					f.cancel!
					return false
				# }}}
				# desynchronize {{{
				# refresh worker blocks individually
				a = []
				for b in s.blocks when b.level > 0
					a[*] = b.refresh c
				# wait complete
				await Promise.all a
				# unlock blocks
				for b in s.blocks when b.locked
					# update value and callback
					b.locked = 0
					b.unlock c if b.unlock
					# restore availability class
					b.rootBox.classList.add 'v'
				# reset priority
				@level = 0
				# }}}
				# load {{{
				# check (allow uncomplete configurations)
				if s.receiver
					a = 0
					while not @dirty and b = await f.readJSON!
						# check
						if b instanceof Error
							consoleError 'fetch stream failed, '+b.message
							return false
						# load
						if @dirty or not s.receiver.load a++, b
							break
				# terminate explicitly if cancelled or didn't started
				f.cancel! if b
				# }}}
				return true
		# }}}
		Group = (sup, name, blocks) !-> # {{{
			# {{{
			@super   = sup
			@f       = sup.slaves # factory
			@name    = name
			@blocks  = blocks
			@config  = sup.config
			@data    = null # state[name]
			@level   = 0
			# order blocks by priority level (ascending)
			blocks.sort (a, b) ->
				return if a.level < b.level
					then -1
					else if a.level == b.level
						then 0
						else 1
			# }}}
		Group.prototype =
			init: ->> # {{{
				# initialize blocks, state and config
				s = @super
				a = []
				for b in @blocks
					b.group = @
					a[*] = b.init s.state, s.config
				# set data shortcut (should setle early)
				@data = s.state[@name]
				# wait completed and
				# check the results
				for a in (await Promise.all a) when not a
					return false
				# done
				return true
			# }}}
			refresh: (block) ->> # {{{
				# refresh group blocks (exclude argument)
				for a in @blocks
					if a != block and not (await a.refresh!)
						return false
				# done
				return true
			# }}}
			submit: (block) !-> # {{{
				# set priority
				@level = if block
					then block.level     # exact
					else @blocks.0.level # group minimal
				# refresh group early
				@refresh block
				# unleash the loader
				@super.loader.charge @
			# }}}
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
						c = '--sm-size-factor'
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
		SuperVisor = (m, s) !->
			# {{{
			# prepare masters and slaves
			m = if m
				then {} <<< M <<< m
				else M
			s = if s
				then {} <<< S <<< s
				else S
			# create object shape
			# base
			@masters  = m     # constructors
			@slaves   = s     # factories
			@root     = null  # attachment point
			@blocks   = null  # master blocks
			@groups   = null  # name:group
			@receiver = null
			# data
			@counter  = 0     # user actions
			@config   = null
			@state    = null
			# controllers
			@loader   = null
			@resizer  = null
			###
			s = (m != M and 'custom ') or ''
			consoleInfo 'new '+s+'supervisor'
			# }}}
		SuperVisor.prototype =
			attach: (root) ->> # {{{
				# check
				if not root
					return false
				else if @state
					# detach first
					if not (await @detach!)
						return false
					# continue
					consoleInfo 're-attaching..'
				else
					consoleInfo 'attaching..'
				# prepare
				@root     = root
				@blocks   = B = []
				@receiver = null
				@counter  = 0
				@config   = new Config!
				@state    = new State!
				@loader   = new Loader @
				# create master blocks
				G = {}
				for b,a of @masters
					# get and iterate DOM nodes
					for b,c in [...(root.querySelectorAll '.'+BRAND+'.'+b)]
						# construct
						B[*] = a = new a b,c
						# set receiver
						@receiver = a if a.load
						# set group
						if b = G[a.group]
							b[*] = a
						else
							G[a.group] = [a]
				# check
				if not B.length
					consoleError 'nothing to attach'
					return false
				# sort by priority level (ascending)
				B.sort (a, b) ->
					return if a.level < b.level
						then -1
						else if a.level == b.level
							then 0
							else 1
				# create groups (use state order)
				@groups = c = {}
				for a in (Object.getOwnPropertyNames @state) when G[a]
					c[a] = new Group @, a, G[a]
				# create resizer
				@resizer = newResizer '.'+BRAND+'-resizer', B
				# initialize
				if not (await @loader.init!)
					await @detach!
					consoleError 'attachment failed'
					return false
				# enter the dragon
				consoleInfo 'supervisor attached'
				while await @loader.run!
					++@counter
				# complete
				consoleInfo 'supervisor detached, '+@counter+' actions'
				return true
			# }}}
			detach: ->> # {{{
				# cleanup
				# ...
				# done
				return true
			# }}}
		return (m, s) -> new SuperVisor m, s
	# }}}
###
