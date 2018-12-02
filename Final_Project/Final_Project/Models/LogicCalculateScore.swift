//
//  LogicCalculateScore.swift
//  test2
//
//  Created by Robert Terry on 11/15/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//

// LOOK at using flatmap to just map into a long 1-D and then breaking up into segments of the row size and
// checking those...


import Foundation

class CalculateScore {

        
        
        let gameBoard = [["Empty","Player One","Player One","Player One","Empty"],
                         ["Empty","Player Two","Player One","Player One","Empty"],
                         ["Player One","Empty","Player Two","Empty","Player One"],
                         ["Player Two","Player Two","Player Two","Player One","Player One"],
                         ["Player Two","Player Two","Player Two","Player Two","Player One"]]
    
        
    static func gameTotalBruteForce(array: [[GridState]]) -> (playerOne: Int, playerTwo: Int) {
        
        
        var p1 = 0
        var p2 = 0
            
            
            // I don't see where flapMap is advantageous, as you still need to advance to the next
            // virtual row, so a double loop is still needed, but this is more confusing..
            //            print(array.flatMap { $0 })
            //
            //            let rowLength = array[0].count
            
            //            let mask1IndexRow = 0
            //            let mask2IndexRow
            //
            //
            //            var mask = (array[mask1IndexRow][mask1IndexCol], array[mask2IndexRow][mask2IndexCol]) == (array[mask2IndexRow][mask2IndexCol], array[mask3IndexRow][mask3IndexCol])
            
            // 1) do lateral, check consective squares in a row
            for row in array { // this advances the rows. It should go to the last row
                print(row)
                // have to use indexes; since the 'matrix' doesn't have empty spaces, row.count is
                // the number of columns
                for columnIndex in 0 ..< row.count - 2 {
                    
                    print(row[columnIndex], row[columnIndex+1])
                    let firstSquare = (row[columnIndex], row[columnIndex+1])
                    let secondSquare = (row[columnIndex+1], row[columnIndex+2])
                    
                    let mask = firstSquare == secondSquare
                    
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
                print("\n")
                print("Player 1 score \(p1)")
                print("Player 2 score \(p2)")
                print("\n")
                
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
                print("\n")
                print("Player 1 score \(p1)")
                print("Player 2 score \(p2)")
                print("\n")
            }
            
            // 3) Attempt forward diagonal
            
            for columnIndex in 0 ..< array[0].count - 2 {
                
                for rowIndex in stride(from: array.count - 3, through: 0, by: -1){
                    
                    print("column index \(columnIndex)")
                    print("row index \(rowIndex)")
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
        return (playerOne: p1, playerTwo: p2)
        }
        
//        gameTotalBruteForce(array: gameBoard)
//
//        print("p1 \(p1)")
//        print("p2 \(p2)")
//
//        // Check our logic, kinda...
//        assert(p1 == 3)
//        assert(p2 == 4)


}
