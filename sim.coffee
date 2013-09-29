#autocompile
AS = {}
class AS.Pathfinder
	Const =
		width: 700
		squares: 100
	Const.height = Const.width
	Const.squareLen = Const.width / Const.squares
	constructor: ($canvas) ->
		@canvas = $canvas[0]
		@ctx = @canvas.getContext '2d'
		@setSizes()
		@setEvents()
		@initData()
		@drawAll()

	initData: ->
		@buildGrid()
		@start = x:0, y:0
		@goal = x:Const.squares - 1, y:Const.squares - 1
		return

	Astar: ->
		@closedSet = {}
		@openSet = new BinaryHeap((node) ->
			return node.fScore
		)
		@start.gScore = @grid[@start.x][@start.y]
		@start.fScore = @start.gScore + @heuristic_cost(@start, @goal)
		@addToOpenSet(@start)
		return

	AstarLoop: ->
		if(@openSet.size() >= 1)
			current = @openSet.pop()
			if @hasReachedGoal(current)
				return false
			@addToClosedSet(current)
			@checkNeighbors(current)
			return true
		else
			console.log "failure"
			return false

	hasReachedGoal: (current) ->
		if current.x is @goal.x and current.y is @goal.y
			@drawAll()
			@drawPath(current)
			@enableButtons()
			console.log "win"
			return true
		return false

	checkNeighbors: (current) ->
		for neighbor in @neighborsOf(current)
			if neighbor.gScore is 1001
				@addToClosedSet(neighbor)
				continue
			if @isInClosedSet(neighbor)
				continue
			if not @isInOpenSet(neighbor)
				neighbor.gScore += current.gScore
				@addToOpenSet(neighbor)
			else
				tentativeGScore = current.gScore + @grid[neighbor.x][neighbor.y] # dist_between
				if tentativeGScore < neighbor.gScore
					neighbor.dad = current
					neighbor.gScore = tentativeGScore
					neighbor.fScore = neighbor.gScore + @heuristic_cost(neighbor, @goal)
		return

	addToOpenSet: (cell) ->
		cell.fScore = cell.gScore + @heuristic_cost(cell, @goal)
		@openSet.push(cell)
		return

	addToClosedSet: (cell) ->
		key = cell.x + '|' + cell.y
		@closedSet[key] = true
		return

	isInClosedSet: (cell) ->
		key = cell.x + '|' + cell.y
		return key of @closedSet

	isInOpenSet: (cell) ->
		for setCell in @openSet.content
			if setCell.x is cell.x and setCell.y is cell.y
				return true
		return false

	heuristic_cost: (from, to) ->
		dx = Math.abs(from.x - to.x)
		dy = Math.abs(from.y - to.y)
		#return 10*(dx+dy)
		return 10 * Math.sqrt(dx * dx + dy * dy)

	neighborsOf: (cell) ->
		x = cell.x
		y = cell.y
		neighbors = []
		left = cell.x > 0
		right = cell.x < Const.squares - 1
		top = cell.y > 0
		bottom = cell.y < Const.squares - 1
		if(left)
			neighbors.push({x: x - 1, y: y, gScore:@grid[x-1][y], dad:cell})
		if(right)
			neighbors.push({x: x + 1, y: y, gScore:@grid[x+1][y], dad:cell})
		if(top)
			neighbors.push({x: x, y: y - 1, gScore:@grid[x][y-1], dad:cell})
		if(bottom)
			neighbors.push({x: x, y: y + 1, gScore:@grid[x][y+1], dad:cell})
		if(@diagonals)
			if(left && top)
					neighbors.push({x: x - 1, y: y - 1, gScore:@grid[x-1][y-1], dad:cell})
			if(left && bottom)
					neighbors.push({x: x - 1, y: y + 1, gScore:@grid[x-1][y+1], dad:cell})
			if(right && top)
					neighbors.push({x: x + 1, y: y - 1, gScore:@grid[x+1][y-1], dad:cell})
			if(right && bottom)
					neighbors.push({x: x + 1, y: y + 1, gScore:@grid[x+1][y+1], dad:cell})
		return neighbors

	buildGrid: ->
		@grid = []
		for i in [1..Const.squares]
			@grid.push (10 for j in [1..Const.squares])
		@divideMaze(0, 0, Const.squares, Const.squares, 0, 0)
		return

	decideOrientation: (width, height) ->
		if width < height
			return 0
		if height < width
			return 1
		return Math.floor(Math.random()*2)

	divideMaze: (x, y, width, height, orientaion) ->
		if width < 4 or height < 6
			return
		isHorizontal = (orientaion == 0)
		wx = x + (if isHorizontal then 0 else Math.floor(Math.random()*(width-2)))
		wy = y + (if isHorizontal then Math.floor(Math.random()*(height-2)) else 0)
		dx = if isHorizontal then 1 else 0
		dy = if isHorizontal then 0 else 1
		len = if isHorizontal then width else height
		val = Math.floor(Math.random()*1000)
		for i in [0...len]
			@grid[wx][wy] = val
			wx += dx
			wy += dy
		nx = x
		ny = y
		if isHorizontal
			w = width
			h = wy-y+1
		else
			w = wx-x+1
			h = height
		@divideMaze(nx, ny, w, h, @decideOrientation(w, h))
		if isHorizontal
			nx = x
			ny = wy+1
			w = width
			h = y + height-wy-1
		else
			nx = wx+1
			ny = y
			w = x + width-wx-1
			h = height
		@divideMaze(nx, ny, w, h, @decideOrientation(w, h))
		return

	drawPath: (currentCell) ->
		currentCell = currentCell.dad
		while currentCell.dad
			@drawCell currentCell.x, currentCell.y, '#0F0'
			currentCell = currentCell.dad
		return

	drawGrid: ->
		for i in [0...Const.squares]
			for j in [0...Const.squares]
				@drawCell i, j, @gToColor(@grid[i][j])
		return

	gToColor: (g)->
		str = Math.floor(g * 255 / 1000).toString(16)
		return '#' + str + str + str

	disableButtons: ->
		$('button').attr('disabled', 'disabled')
		return

	enableButtons: ->
		$('button').removeAttr('disabled')
		return
	drawCell: (x, y, color) ->
		@ctx.fillStyle = color
		@ctx.fillRect(x * Const.squareLen, y*Const.squareLen, Const.squareLen, Const.squareLen)
		return

	drawAll: ->
		@drawGrid()
		@drawCell(@start.x, @start.y, '#22F')
		@drawCell(@goal.x, @goal.y,'#F00')
		return

	setSizes: ->
		@canvas.width = Math.min $(window).width() - 40, Const.width
		@canvas.height = Math.min $(window).width() - 40, Const.height
		Const.squareLen = @canvas.width / Const.squares
		return

	changeStart: (x, y) ->
		@start.x = x
		@start.y = y
		return

	changeGoal: (x, y) ->
		@goal.x = x
		@goal.y = y
		return

	increaseCellCost: (x, y) ->
		@grid[x][y] += 200
		if @grid[x][y] > 1000
			@grid[x][y] = 1000
		return

	setEvents: ->
		modStatus =
			none: 0
			ctrl: 1
			shift: 2
		keyCodes =
			ctrl: 17
			shift: 16
		@keyMode = modStatus.none
		@enableButtons()
		@diagonals = true
		$('#diagonal').prop('checked', @diagonals)
		$(@canvas).bind 'mousedown', (e) =>
			i = Math.floor((e.pageX - @canvas.offsetLeft)/Const.squareLen)
			j = Math.floor((e.pageY - @canvas.offsetTop)/Const.squareLen)
			if e.which is 1
				switch @keyMode
					when modStatus.none
						@changeStart(i, j)
					when modStatus.ctrl
						@changeGoal(i, j)
					when modStatus.shift
						@increaseCellCost(i, j)
			else if e.which is 2
				@increaseCellCost(i, j)
			else
				@changeGoal(i, j)
			@drawAll()
			return false
		$(@canvas).bind 'contextmenu', ->
			return false

		$(window).bind 'keydown', (e) =>
			if e.which is keyCodes.ctrl
				@keyMode = modStatus.ctrl
			else if e.which is keyCodes.shift
				@keyMode = modStatus.shift
			return
		$(window).bind 'keyup', =>
			@keyMode = modStatus.none
			return


		$('#instantSolve').bind 'click', =>
			@disableButtons()
			@Astar()
			while @AstarLoop() then
			@enableButtons()
			return
		$('#diagonal').bind 'click', (ev) =>
			@diagonals = ev.currentTarget.checked
			return true
		$(window).resize =>
			@setSizes()
			@drawAll()
			return
		return

astarPathfinder = new AS.Pathfinder($('#simview'))
