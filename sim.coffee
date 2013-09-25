#autocompile
GE = {}
class GE.Sim

	Const =
		width: 600
		squares: 15
	Const.height = Const.width
	Const.squareLen = Const.width / Const.squares
	constructor: ($canvas) ->
		@canvas = $canvas[0]
		@ctx = @canvas.getContext '2d'
		@setSizes()
		@setEvents()
		@buildGrid()
		@start = {x:0, y:0}
		@goal = {x:10, y:10}
		@drawAll()
		@enableButtons()

	Astar: ->
		@closedSet = {}
		@openSet = new BinaryHeap( (node) ->
			return node.fScore
		)
		@came_from = []
		@start.gScore = 1
		@start.fScore = @start.gScore + @heuristic_cost(@start, @goal)
		@addToOpenSet(@start)
		@disableButtons()

	AstarLoop: ->
		if(@openSet.size() >= 1)
			current = @openSet.pop()
			#if(@timerId)
			@drawAll()
			@drawCell current.x*Const.squareLen, current.y*Const.squareLen, '#0F0'
			if current.x is @goal.x and current.y is @goal.y
				@drawPath(current)
				console.log "win"
				clearInterval @timerId
				@enableButtons()
				return false
			@addToClosedSet(current)
			@checkNeighbors(current)
			@drawFandG()
			return true
		else
			console.log "failure"
			clearInterval @timerId
			return false
		

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
			else if setCell.fScore >= cell.fScore
				return false
		return false


	heuristic_cost: (from, to) ->
		dx = Math.abs(from.x - to.x)
		dy = Math.abs(from.y - to.y)
		#return 10*(dx+dy)
		return Math.sqrt(dx * dx + dy * dy)*10

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
			@drawCell currentCell.x*Const.squareLen, currentCell.y*Const.squareLen, '#0F0'
			currentCell = currentCell.dad
		return

	drawGrid: ->
		for i in [0...Const.squares]
			for j in [0...Const.squares]
				@drawCell i*Const.squareLen, j*Const.squareLen, @gToColor(@grid[i][j])
		return

	gToColor: (g)->
		str = Math.floor(g * 255 / 1000).toString(16)
		return '#' + str + str + str

	drawCell: (x, y, color) ->
		@ctx.fillStyle = color
		@ctx.fillRect(x, y, Const.squareLen, Const.squareLen)
		#@ctx.strokeRect(x, y, Const.squareLen, Const.squareLen)
		return

	drawAll: ->
		@ctx.strokeStyle = 'white'
		@drawGrid()
		@drawCell(@start.x*Const.squareLen, @start.y*Const.squareLen, '#22F')
		@drawCell(@goal.x*Const.squareLen, @goal.y*Const.squareLen,'#F00')
		return

	drawFandG: ->
		@ctx.fillStyle= 'white'
		for openCell in @openSet.content
			@ctx.fillText(openCell.fScore.toFixed(2), openCell.x*Const.squareLen + 10, (openCell.y+0.3)*Const.squareLen)
			@ctx.fillText(openCell.gScore.toFixed(2), openCell.x*Const.squareLen + 10, (openCell.y+0.7)*Const.squareLen)
		return

	setSizes: ->
		@canvas.width = Math.min $(window).width() - 40, Const.width
		@canvas.height = Math.min $(window).width() - 40, Const.height
		Const.squareLen = @canvas.width / Const.squares
		return

	disableButtons: ->
		$('button').attr('disabled', 'disabled')
		return
	enableButtons: ->
		$('button').removeAttr('disabled')
		return
	setEvents: ->
		@diagonals = true
		$('#diagonal').prop('checked', @diagonals)
		@keyMode = 0
		$(@canvas).bind 'mousedown', (e) =>
			i = Math.floor((e.pageX - @canvas.offsetLeft)/Const.squareLen)
			j = Math.floor((e.pageY - @canvas.offsetTop)/Const.squareLen)
			if @keyMode is 1
				@start.x = i
				@start.y = j
			else if @keyMode is 2
				@goal.x = i
				@goal.y = j
			else if @grid[i][j] < 800
				@grid[i][j] += 400
			@drawAll()
			return

		$(document).bind 'keydown', (e) =>
			if e.keyCode is 17
				@keyMode = 1
			else if e.keyCode is 16
				@keyMode = 2
			else if e.keyCode is 32
				@AstarLoop()
			return
		$(document).bind 'keyup', =>
			@keyMode = 0

		$('#start').bind 'click', =>
			@Astar()
			#@timerId = setInterval =>
			#	@AstarLoop()
			#	return
			#, 300
			return
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
