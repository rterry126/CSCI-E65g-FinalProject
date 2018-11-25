//
//  2DOperations.swift
//  Solution6
//
//  Created by BaseZen on 10/13/18.
//  Copyright © 2018 BaseZen. All rights reserved.
//

//import Foundation

/* Either a location on the grid, or the extent of the entire grid */
// Robert - I've already declared this in shared.swift
//typealias GridCoord = (row: Int, column: Int)

/* A constraint on the possible extents of a grid */
// Robert - Already declared in shared.swift
//typealias GridLimits = (lower: GridCoord, upper: GridCoord)

// Defining the "WITHIN" operator
// Robert - Already declared in shared.swift
//infix operator <=>: ComparisonPrecedence

// Robert - Moved to shared.swift to keep organized
/* func <=>(index: Int, arraySize: Int) -> Bool {
    return index >= 0 && index < arraySize
}

func <=>(size: GridCoord, sizeLimits: GridLimits) -> Bool {
    return size.row >= sizeLimits.lower.row && size.row <= sizeLimits.upper.row &&
        size.column >= sizeLimits.lower.column && size.column <= sizeLimits.upper.column
}
 */

// Robert - Already declared in shared.swift
//func <=>(point: GridCoord, bounds: GridCoord) -> Bool {
//    return point.row >= 0 && point.row < bounds.row
//        && point.column >= 0 && point.column < bounds.column
//}


