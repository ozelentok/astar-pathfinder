#autocompile
GE = {}
class GE.Sim

	Const =
		width: 600
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

	Astar: ->
		@closedSet = {}
		@openSet = new BinaryHeap((node) ->
			return node.fScore
		)
		@start.gScore = @grid[@start.x][@start.y]
		@start.fScore = @start.gScore + @heuristic_cost(@start, @goal)
		@addToOpenSet(@start)
		@disableButtons()
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

	checkNeighbors: (current) ->
		for neighbor in @neighborsOf(current)
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

	setEvents: ->
		@enableButtons()
		@diagonals = true
		$('#diagonal').prop('checked', @diagonals)
		$(@canvas).bind 'mousedown', (e) =>
			i = Math.floor((e.pageX - @canvas.offsetLeft)/Const.squareLen)
			j = Math.floor((e.pageY - @canvas.offsetTop)/Const.squareLen)
			if e.which is 1
				@start.x = i
				@start.y = j
			else if e.which is 3
				@goal.x = i
				@goal.y = j
			else
				@grid[i][j] += 200
				if @grid[i][j] > 1000
					@grid[i][j] = 1000
			@drawAll()
			return false
		$(@canvas).bind 'contextmenu', ->
			return false

		$('#instantSolve').bind 'click', =>
			@Astar()
			while @AstarLoop() then
			return
		$('#diagonal').bind 'click', (ev) =>
			@diagonals = ev.currentTarget.checked
			return true
		$(window).resize =>
			@setSizes()
			@drawAll()
			return
		return

germSim = new GE.Sim($('#simview'))
