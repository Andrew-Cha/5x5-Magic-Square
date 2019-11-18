//
//  main.swift
//  7x7 Grid
//
//  Created by Andrew on 11/14/19.
//  Copyright © 2019 Andrew. All rights reserved.
//

import Cocoa

struct BoardState {
	var matrix: Matrix<Cell>
	var lastValidValue: Int
}

struct Cell {
	let direction: Direction
	var endPoint: Point
	var position: Point
	var value: Int
}

struct Matrix<Element> {
	let width, height: Int
	private(set) var elements: [Element?]
	
	init(width: Int, height: Int) {
		self.init(
			width: width, height: height,
			elements: Array(repeating: nil, count: width * height)
		)
	}
	
	private init(width: Int, height: Int, elements: [Element?]) {
		self.width = width
		self.height = height
		self.elements = elements
	}
	
	subscript(position: Point) -> Element? {
		get { elements[position.x + width * position.y] }
		set { elements[position.x + width * position.y] = newValue }
	}
	
	func element(at position: Point) -> Element? {
		guard case 0..<width = position.x, case 0..<height = position.y else { return nil }
		return elements[position.x + width * position.y]
	}
}

struct Point {
	var x, y: Int
	
	static func += (point: inout Point, offset: Vector) {
		point.x += offset.x
		point.y += offset.y
	}
	
	static func + (point: Point, offset: Vector) -> Point {
		Point(
			x: point.x + offset.x,
			y: point.y + offset.y
		)
	}
	
	static func -= (point: inout Point, offset: Vector) {
		point.x -= offset.x
		point.y -= offset.y
	}
	
	static func - (point: Point, offset: Vector) -> Point {
		Point(
			x: point.x - offset.x,
			y: point.y - offset.y
		)
	}
	
	static func == (lhs: Point, rhs: Point) -> Bool {
		if lhs.x == rhs.x && lhs.y == rhs.y {
			return true
		} else {
			return false
		}
	}
}

struct Vector {
	var x, y: Int
	
	static func += (lhs: inout Vector, rhs: Vector) {
		lhs.x += rhs.x
		lhs.y += rhs.y
	}
	
	static func + (lhs: Vector, rhs: Vector) -> Vector {
		Vector(
			x: lhs.x + rhs.x,
			y: lhs.y + rhs.y
		)
	}
}

enum Direction: Int, CaseIterable {
	case upRight
	case up
	case upLeft
	case left
	case downLeft
	case down
	case downRight
	case right
	
	var offset: Vector {
		switch self {
		case .upRight:
			return Vector(x:  1, y: -1)
		case .up:
			return Vector(x:  0, y: -1)
		case .upLeft:
			return Vector(x: -1, y: -1)
		case .left:
			return Vector(x: -1, y:  0)
		case .downLeft:
			return Vector(x: -1, y:  1)
		case .down:
			return Vector(x:  0, y:  1)
		case .downRight:
			return Vector(x:  1, y:  1)
		case .right:
			return Vector(x:  1, y:  0)
		}
	}
}

class Board {
	let boardHeight = 7
	let boardWidth = 7
	let maxValue = 25
	var matrix: Matrix<Cell>
	var historyLog: [BoardState] = []
	
	init(data: [Cell]) {
		matrix = Matrix(width: boardHeight, height: boardWidth)
		for cell in data {
			matrix[cell.position] = cell
		}
		
		solveBoard(atNumber: 2)
	}
	
	func findBoardState(at lastValidValue: Int) -> BoardState? {
		for boardState in historyLog {
			if boardState.lastValidValue == lastValidValue {
				return boardState
			}
		}
		
		return nil
	}
	
	func findCellAt(_ point: Point) -> Cell? {
		return matrix.element(at: point)
	}
	
	func findCellWithValue(value: Int) -> Cell? {
		for cell in matrix.elements {
			if let cell = cell {
				if cell.value == value {
					return cell
				}
			}
		}
		
		return nil
	}
	
	func isBoardSolved(board: Matrix<Cell>) -> Bool {
		for cell in board.elements {
			if let cell = cell {
				if cell.position.x == 0 || cell.position.x == boardHeight - 1 || cell.position.y == 0 || cell.position.y == boardHeight - 1 {
					return false
				}
			}
		}
		
		return true
	}
	
	func isDistanceValid(from lhs: Point, to rhs: Point) -> Bool {
		let distance = max(abs(lhs.x - rhs.x), abs(lhs.y - rhs.y))
		return distance == 1
	}
	
	func printData() {
		var string = ""
		for heightIndex in 0..<boardHeight {
			var rowDataString = ""
			for widthIndex in 0..<boardWidth {
				let point = Point(x: widthIndex, y: heightIndex)
				guard let cell = findCellAt(point) else {
					rowDataString += " X "
					continue
				}
				
				if cell.value < 10 {
					rowDataString +=  " \(cell.value) "
				} else {
					rowDataString +=  "\(cell.value) "
				}
			}
			
			string += rowDataString + "\n"
		}
		
		string += "- - - - - - -"
		print(string)
	}
	
	func recordBoardState(board: Matrix<Cell>, lastValidValue: Int) {
		var isFound = false
		if historyLog.count > 0 {
			for index in 0...historyLog.count - 1 {
				if historyLog[index].lastValidValue == lastValidValue {
					historyLog[index].matrix = board
					isFound = true
				}
			}
		}
		
		if !isFound {
			historyLog.append(BoardState(matrix: board, lastValidValue: lastValidValue))
		}
	}
	
	func solveBoard(atNumber startingNumber: Int) {
		if startingNumber == 1 {
			print("No permutation found that would solve the board.")
			return
		}
		
		guard let cell = findCellWithValue(value: startingNumber) else {
			print("Failed to find a sequence of numbers that is valid. At (\(startingNumber))")
			return
		}
		guard let leftNeighbor = findCellWithValue(value: startingNumber - 1) else {
			print("Failed to find a sequence of numbers that is valid.")
			return
		}
		var didMoveCell = false
		let direction = cell.direction
		let endPoint = cell.endPoint
		var offset = direction.offset
		while true {
			//Fail condition
			let possiblePosition = Point(x: cell.position.x + offset.x, y: cell.position.y + offset.y)
			if possiblePosition == endPoint {
				guard let lastBoardState = findBoardState(at: startingNumber - 1) else {
					print("Error in grabbing the board state from the history log. At \(startingNumber)")
					return
				}
				matrix = lastBoardState.matrix
				
				break
			}
			
			//Pass condition
			let cellAtNewPoint = findCellAt(possiblePosition)
			let isValid = isDistanceValid(from: possiblePosition, to: leftNeighbor.position)
			if isValid && cellAtNewPoint == nil {
				didMoveCell = true
				matrix[cell.position]?.position = possiblePosition
				matrix[possiblePosition] = matrix[cell.position]
				matrix[cell.position] = nil
				recordBoardState(board: matrix, lastValidValue: startingNumber)
				
				break
			}
			
			//General condition, we move the cell one in its direction
			offset += direction.offset
		}
		
		if startingNumber == maxValue {
			if isBoardSolved(board: matrix) {
				printData()
				print("The board is solved.")
			}
		} else if didMoveCell {
			return solveBoard(atNumber: startingNumber + 1)
		} else {
			return solveBoard(atNumber: startingNumber - 1)
		}
	}
}

let input = [
	Cell(direction: Direction.downRight, endPoint: Point(x:  6, y: 6), position: Point(x: 0, y: 0), value: 20),
	Cell(direction: Direction.down, endPoint: Point(x: 1, y: 6), position: Point(x: 1, y: 0), value: 25),
	Cell(direction: Direction.down, endPoint: Point(x: 2, y: 6), position: Point(x: 2, y: 0), value: 3),
	Cell(direction: Direction.down, endPoint: Point(x: 3, y: 6), position: Point(x: 3, y: 0), value: 22),
	Cell(direction: Direction.down, endPoint: Point(x: 4, y: 6), position: Point(x: 4, y: 0), value: 5),
	Cell(direction: Direction.down, endPoint: Point(x: 5, y: 6), position: Point(x: 5, y: 0), value: 6),
	Cell(direction: Direction.downLeft, endPoint: Point(x: 0, y:  6), position: Point(x: 6, y: 0), value: 16),
	Cell(direction: Direction.right, endPoint: Point(x: 6, y: 1),position: Point(x: 0, y: 1), value: 8),
	Cell(direction: Direction.left, endPoint: Point(x: 0, y: 1), position: Point(x: 6, y: 1), value: 14),
	Cell(direction: Direction.right, endPoint: Point(x: 6, y: 2), position: Point(x: 0, y: 2), value: 12),
	Cell(direction: Direction.left, endPoint: Point(x: 0, y: 2), position: Point(x: 6, y: 2), value: 9),
	Cell(direction: Direction.right, endPoint: Point(x: 6, y: 3), position: Point(x: 0, y: 3), value: 11),
	Cell(direction: Direction.up, endPoint: Point(x: 2, y: 0), position: Point(x: 2, y: 3), value: 1),
	Cell(direction: Direction.left, endPoint: Point(x: 0, y: 3), position: Point(x: 6, y: 3), value: 4),
	Cell(direction: Direction.right, endPoint: Point(x: 6, y: 4), position: Point(x: 0, y: 4), value: 19),
	Cell(direction: Direction.left, endPoint: Point(x: 0, y: 4), position: Point(x: 6, y: 4), value: 23),
	Cell(direction: Direction.right, endPoint: Point(x: 6, y: 5), position: Point(x: 0, y: 5), value: 21),
	Cell(direction: Direction.left, endPoint: Point(x: 0, y: 5), position: Point(x: 6, y: 5), value: 24),
	Cell(direction: Direction.upRight, endPoint: Point(x: 6, y: 0), position: Point(x: 0, y: 6), value: 7),
	Cell(direction: Direction.up, endPoint: Point(x: 1, y: 0), position: Point(x: 1, y: 6), value: 2),
	Cell(direction: Direction.up, endPoint: Point(x: 2, y: 0), position: Point(x: 2, y: 6), value: 10),
	Cell(direction: Direction.up, endPoint: Point(x: 3, y: 0), position: Point(x: 3, y: 6), value: 15),
	Cell(direction: Direction.up, endPoint: Point(x: 4, y: 0), position: Point(x: 4, y: 6), value: 18),
	Cell(direction: Direction.up, endPoint: Point(x: 5, y: 0), position: Point(x: 5, y: 6), value: 17),
	Cell(direction: Direction.upLeft, endPoint: Point(x: 0, y: 0), position: Point(x: 6, y: 6), value: 13)
]
let board = Board(data: input)

