//
//  ModelCalculateScore.swift

//
//  Created by Robert Terry on 12/2/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

// Source - array find and replace - https://developer.apple.com/documentation/swift/array

// 
import Foundation

class CalculateScore {
    
    static func gameTotalBruteForce(passedInArray: [[GridState]]) -> (playerOne: Int, playerTwo: Int) {
        
        // 0) Change the power squares, if present, to regular squares. Keeps the scoring logic easier below
        
        var array = passedInArray
        
        for row in 0 ..< array.count {
            if let i = array[row].firstIndex(of: .playerOnePower) {
                array[row][i] = .playerOne
            }
            if let j = array[row].firstIndex(of: .playerTwoPower) {
                array[row][j] = .playerTwo
            }
        }
        
        
        
        var p1 = 0
        var p2 = 0
        
        // 1) do lateral, check consective squares in a row
        for row in array { // this advances the rows. It should go to the last row
            // have to use indexes; since the 'matrix' doesn't have empty spaces, row.count is
            // the number of columns
            for columnIndex in 0 ..< row.count - 2 {
                
                let firstSquare = (row[columnIndex], row[columnIndex+1])
                let secondSquare = (row[columnIndex+1], row[columnIndex+2])
                
                let mask = firstSquare == secondSquare // First tuple (A,B) == (B,C) second tuple
                
                if mask { // So if we have 3 consecutive squares
                    switch row[columnIndex] {
                        
                    case .playerOne:
                        p1 += 1
                        
                    case .playerTwo:
                        p2 += 1
                    default:
                        _ = 0 // We need a default, which would be empty squares.
                        
                    }
                }
                
                
            }
        }
        
        print("starting vertical summing....")
        // 2) do vertical, check consective squares in a column
        // Have to use a little different approach, since we cannot pull out a column like we can a row
        
        for columnIndex in 0 ..< array[0].count { // this advances the columns. It should go to the last column
            // have to use indexes; since the 'matrix' doesn't have empty spaces, row.count is
            // the number of columns
            for rowIndex in 0 ..< array.count - 2 {
                
                print(array[rowIndex][columnIndex], array[rowIndex+1][columnIndex])
                let firstSquare = (array[rowIndex][columnIndex], array[rowIndex+1][columnIndex])
                let secondSquare = (array[rowIndex+1][columnIndex], array[rowIndex+2][columnIndex])
                
                let mask = firstSquare == secondSquare
                
                if mask { // So if we have 3 consecutive squares
                    switch array[rowIndex][columnIndex] {
                        
                    case .playerOne:
                        p1 += 1
                        
                    case .playerTwo:
                        p2 += 1
                    default:
                        _ = 0 // We need a default, which would be empty squares.
                        
                        
                    }
                }
            }
        }
        
        // 3) Attempt forward diagonal
        
        for columnIndex in 0 ..< array[0].count - 2 {
            
            for rowIndex in stride(from: array.count - 3, through: 0, by: -1){
                
                let firstSquare = (array[rowIndex][columnIndex], array[rowIndex+1][columnIndex+1])
                let secondSquare = (array[rowIndex+1][columnIndex+1], array[rowIndex+2][columnIndex+2])
                
                let mask = firstSquare == secondSquare
                
                if mask { // So if we have 3 consecutive squares
                    switch array[rowIndex][columnIndex] {
                        
                    case .playerOne:
                        p1 += 1
                        
                    case .playerTwo:
                        p2 += 1
                    default:
                        _ = 0 // We need a default, which would be empty squares.
                        
                    }
                }
            }
        }
        
        // 4) Backward diagonal
        
        for columnIndex in stride(from: array[0].count - 1, through: 2, by: -1)  {
            
            for rowIndex in stride(from: array.count - 3, through: 0, by: -1){
                
                let firstSquare = (array[rowIndex][columnIndex], array[rowIndex+1][columnIndex-1])
                let secondSquare = (array[rowIndex+1][columnIndex-1], array[rowIndex+2][columnIndex-2])
                
                let mask = firstSquare == secondSquare
                
                if mask { // So if we have 3 consecutive squares
                    switch array[rowIndex][columnIndex] {
                        
                    case .playerOne:
                        p1 += 1
                        
                    case .playerTwo:
                        p2 += 1
                    default:
                        _ = 0 // We need a default, which would be empty squares.
                        
                    }
                }
            }
        }
        
        return (playerOne: p1, playerTwo: p2)
    }
    
    //        gameTotalBruteForce(array: gameBoard)
   
    //        // Check our logic, kinda...
    //        assert(p1 == 3)
    //        assert(p2 == 4)
    
    
}
