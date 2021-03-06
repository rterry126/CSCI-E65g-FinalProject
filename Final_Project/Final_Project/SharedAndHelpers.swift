////  Shared.swift
////  Final_Project-rterry126
////
////  Created by Robert Terry on 10/11/18.
////  Copyright © 2018 Robert Terry. All rights reserved.
////

import Foundation
import UIKit

// Sources - enumeration of tuples - https://stackoverflow.com/questions/26387275/enum-of-tuples-in-swift
//Source - continued -https://medium.com/@johnsundell/conditional-conformances-in-swift-f6601d40aabb
// Source - RawRepresentable apple-reference-documentation://hsct8jXImn
// Source - Enumeration and user defaults - https://medium.com/swift-programming/swift-userdefaults-protocol-4cae08abbf92
// Source - use of getHue - https://www.hackingwithswift.com/example-code/uicolor/how-to-read-the-red-green-blue-and-alpha-color-components-from-a-uicolor
// Source - Time format - https://teamtreehouse.com/community/swift-countdown-timer-of-60-seconds
// Source - Resize image - https://stackoverflow.com/questions/31966885/resize-uiimage-to-200x200pt-px




//MARK: - Enumeration for user Prefs persistence
// enum for storing game preferences (persistence). All code for persisting takes place in model, aside
// from the definition here

// Sources cited above for enum of typealias raw data
// Note - initially bulit enumeration for RGBColor typealias. However that was too difficult to store
// so I switched storage to [Double]. However enumeration of [Double] still requires same code below
// to  make 'Colors' RawRepresentable.

let hsbPlayerOneDefault = [1.0, 1.0, 1.0, 1.0]
let hsbPlayerTwoDefault = [0.27222, 1.0, 1.0, 1.0]

// For saving UserDefaults, i.e. preferences
enum PrefKeys: CaseIterable {
    enum Players : String, CaseIterable {
        case playerOne = "Player One" // Providing a raw value, I don't want 'playerOne' as the display
        case playerTwo = "Player Two"
    }
    
    enum BoardSize: Int, CaseIterable {
        case rows = 6
        case columns = 7
    }
    enum MiscPrefs: String, CaseIterable {
        case gameName = "Final Project - Robert"
        case myNameIs = "Robert"
    }
    enum GameTime: Int, CaseIterable {
        case moveTime = 5
    }
   
    
    enum Colors: RawRepresentable, CaseIterable {
        case playerOneColor
        case playerTwoColor
        
        var rawValue: [Double] {
            switch self {
            case .playerOneColor: return hsbPlayerOneDefault // Default colors  ~ Red(HSB & Alpha)
            case .playerTwoColor: return hsbPlayerTwoDefault  // ~ Green
            }
        }
        
        init?(rawValue: [Double])  {
            switch rawValue {
            case hsbPlayerOneDefault: self = .playerOneColor
            case hsbPlayerTwoDefault: self = .playerTwoColor
            default: return nil
            }
        }
    }
}

// Below enums are 'Codable' so that we can save the model state
enum GridState: String, CaseIterable, Codable {
    
    case empty = "Empty"
    case playerOne = "Player One"
    case playerTwo = "Player Two"
    case playerOnePower = "Player One Power"
    case playerTwoPower = "Player Two Power"
}


//MARK: - Type aliases

typealias HSBColor = (hue: Double, saturation: Double, brightness: Double, alpha: Double)
typealias GridCoord = (row: Int, column: Int)
typealias GridLimits = (lower: GridCoord, upper: GridCoord)
typealias observerArray = [(name: NSNotification.Name, selector: Selector)]


//MARK: - User Defined Operators/Functions
infix operator <=>: ComparisonPrecedence

func <=>(point: GridCoord, bounds: GridCoord) -> Bool {
    return point.row >= 0 && point.row < bounds.row
        && point.column < bounds.column
}


func <=>(index: Int, arraySize: Int) -> Bool {
    return index >= 0 && index < arraySize
}

func <=>(size: GridCoord, sizeLimits: GridLimits) -> Bool {
    return size.row >= sizeLimits.lower.row && size.row <= sizeLimits.upper.row &&
        size.column >= sizeLimits.lower.column && size.column <= sizeLimits.upper.column
}



//MARK: - Helper Functions
// Helper function to convert from HSB value stored in model (model doesn't know of UIColor) to
// UIColor. Just keeps the view code cleaner.
func hsbToUIColor(color: HSBColor, alpha: CGFloat = 1.0) -> UIColor {
    
    return UIColor.init(hue: CGFloat(color.hue),
                        saturation: CGFloat(color.saturation),
                        brightness: CGFloat(color.brightness),
                        alpha: alpha)
}

// Source cited. Convert back to HSB to store color. Model doesn't 'know' UIColor
func uiColorToHSB(color: UIColor) -> HSBColor {
    
    // So the way I understand it, we're using pointers and just modifying the arguments passed into the
    // function. I suppose this is easier as we are 'returning' 4 values. Variables below are just
    // 'placeholder' variables to be modified and their value used later.
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0
    
    // Call the method on the color we want to convert
    color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    
    return (hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), alpha: Double(alpha))
    
}

// Couple of helper functions. Very difficult to store a tuple in UserDefaults.standard, however
// can easily store an array of Doubles. I prefer having the color as HSBColor (typealias) because one
// can determine easily what it represents. So I don't want to change that model to array of Doubles
func tupleToArray(_ hsbTuple: HSBColor) -> [Double] {
    return [hsbTuple.hue, hsbTuple.saturation, hsbTuple.brightness, hsbTuple.alpha]
}

func arrayToTuple(_ hsbArray: [Double]) -> HSBColor {
    // Ostensibly since we converted and stored the data the array should have 4 values. However if
    // it doesn't we could either hava a fatal error, throw (which makes code in model more complex, or
    // just return a default value. If the array is nil, then that should already be previously handled
    // by the retrieving from storage function
    if hsbArray.count != 4 {
        return (hue: 1.0, saturation: 0.0, brightness: 1.0, alpha: 1.0)
    }
    else {
        return (hue: hsbArray[0], saturation: hsbArray[1], brightness: hsbArray[2], alpha: hsbArray[3])
    }
    
}

func timeFormatted(_ totalSeconds: Int) -> String {
    let seconds: Int = totalSeconds % 60
    return String(format: " :%02d", seconds)
    
}

// Resize image of game board to thumbnail size
func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
    
    let newHeight = newWidth // Make it square. Current thumbnail looks strange
    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
    
}

// Quick hard coded extension to give my labels a border. Just cleans up the code above
extension UILabel {
    func border(_ width: CGFloat = 0.5, _ color: CGColor = UIColor.black.cgColor) {
        self.layer.borderWidth = width
        self.layer.borderColor = color
    }
}

func restoreModel(_ modelGameLogic: inout GameLogicModelProtocol) -> Bool {
    
    var success = false
    do {
        let restoredObject = try Persistence.restore()
        guard let mdo = restoredObject as? GameLogicModelProtocol else {
            print("Got the wrong type: \(type(of: restoredObject)), giving up on restoring")
            success = false
            return success
        }
        // Let's try setting a reference to our restored state
        modelGameLogic = mdo

        print("Success: in restoring game state")
        success = true
        print(modelGameLogic.gameBoard)
        return success
    }
    catch let e {
        print("Restore failed: \(e).")

        // So evidently if it fails here to restore saved model it uses the default init()
        // defined in the model. Code below isn't needed (saved as a reminder as to flow of init)

//            var modelGameLogic: GameLogicModelProtocol =
//               GameLogicModel(numOfRows: numOfGridRows, numOfColumns: numOfGridColumns)
    }
    
    print("Printing whether or not model to restore found from restoreModel func")
    print(success)
    return success
}



