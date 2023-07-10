//
//  NSAttributedStringToJSON.swift
//  
//
//  Created by Joseph Levy on 7/7/23.
//

import Foundation
import SwiftUI
//let attributedString: NSAttributedString! // Input -> NSAttributedString
let RUN_ATTRIBUTES_ARRAY: NSMutableArray = []
public func convertNSAttributedStringToJSON(_ attributedString: NSAttributedString) -> Data {
    attributedString.enumerateAttributes(in: .init(location: 0, length: attributedString.length), options: [], using: { attributedDictionary, range, stop in // Retrieve all of attributed string's attributes
        let runAttributes: NSMutableDictionary = NSMutableDictionary()
        
        // Convert each attribute's value to a JSON formattable type
        for attribute in attributedDictionary {
            if (attribute.key == .font) {
                let values: NSDictionary = [
                    "name": (attribute.value as! UIFont).fontName,
                    "size": (attribute.value as! UIFont).pointSize
                ]
                
                runAttributes.setValue(values, forKey: "font") // Apply the value with its key to a mutable dictionary
            }
        }
        
        // Add the previously accumulated values to a mutable array along with the corresponding range
        RUN_ATTRIBUTES_ARRAY.add([
            "range": [range.lowerBound, range.upperBound],
            "attributes": runAttributes
        ] as [String : Any])
    })
    
    // Create a dictionary with the attributes and the text value
    let dictionary: NSDictionary = [
        "string": attributedString.string,
        "runs": RUN_ATTRIBUTES_ARRAY
    ]
    
    // Convert the dictionary to JSON
    do {    // capture potential throw below
        let jsonData: Data = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
        print(jsonData) // Output -> JSON
        return jsonData
    } catch {
        print("Error converting dictionary to JSON")
    }
    return Data()
}

private func convertAttributesFromJSONToDictionary(_ attributes: Any) -> [NSAttributedString.Key: Any]? {
    if let attrValue: [String: [String: Any]] = (attributes as? [String: [String: Any]]) {
        /*
         attrValue = [
         "font" : {
         "name" : "Helvetica",
         "size" : 12
         },
         "color" : [255,0,0]
         ]
         */
        var attrDict: [NSAttributedString.Key: Any] = [:]
        
        for (key, value) in attrValue { // Loop through each attribute
            if (key == "font") {
                // Retrieve all attribute values
                var name: String = "Helvetica"
                var size: CGFloat = 12
                
                for (fontKey, fontValue) in value {
                    if (fontKey == "name") {
                        name = (fontValue as! String)
                    } else if (fontKey == "size") {
                        size = (fontValue as! CGFloat)
                    }
                }
                
                if let font: UIFont = UIFont(name: name, size: size) {
                    // Add retrieved values to a dictionary
                    attrDict.updateValue(font, forKey: .font)
                } else {
                    print("Unable to implement font attribute")
                }
            }
        }
        
        return attrDict // Return filled dictionary
    }
    
    return nil
}

public func convertJSONToAttributedString() {
    var dictionary: [String: Any]! // Input -> JSON
    
    // Create attributed string with text string
    guard let string: String = (dictionary["string"] as? String) else {
        print("Incorrect json structure {string}")
        return
    }
    
    let attrString: NSMutableAttributedString = NSMutableAttributedString(string: string)
    
    if let runsDict: [[String: Any]] = (dictionary["runs"] as? [[String: Any]]) { // Check for 'runs' key in JSON data
        /*
         runsDict = [
         {
         "attributes" : {Any},
         "range" : [Int]
         }, {
         "attributes" : {Any},
         "range" : [Int]
         }
         ]
         */
        for run in runsDict { // Loop through each attributes and range section
            var attributes: [NSAttributedString.Key: Any] = [:]
            var range: NSRange?
            
            for (key, value) in run {
                // Retrieve all attributes and the range
                if (key == "attributes") {
                    if let attrDict: [NSAttributedString.Key: Any] = convertAttributesFromJSONToDictionary(value) {
                        attributes = attrDict
                    }
                } else if (key == "range") {
                    if let rangeValue: [Int] = (value as? [Int]) {
                        range = NSRange(location: rangeValue[0], length: (rangeValue[1] - rangeValue[0]))
                    }
                }
                
                // Add retrieved attributes and range to the attributed string
                if ((key == "attributes" || key == "range") && range != nil) {
                    attrString.addAttributes(attributes, range: range!)
                }
            }
        }
    } else {
        print("Incorrect json structure {runs}")
    }
    
    print(attrString) // Output -> NSAttributedString
}

//struct AttributedString {
//    let attributedString: NSAttributedString
//    init(attributedString: NSAttributedString) { self.attributedString = attributedString }
//    init(string str: String, attributes attrs: [NSAttributedString.Key: Any]? = nil) { attributedString = .init(string: str, attributes: attrs) }
//}

//Archiving / Encoding

extension NSAttributedString {
    func data() throws -> Data { try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false) }
}
//extension AttributedString: Encodable {
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encode(attributedString.data())
//    }
//}
//Unarchiving / Decoding

extension Data {
    func topLevelObject() throws -> Any? { try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(self) }
    func unarchive<T>() throws -> T? { try topLevelObject() as? T }
    func attributedString() throws -> NSAttributedString? { try unarchive() }
}
extension AttributedString  {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let attributedString = try container.decode(Data.self).attributedString() else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Corrupted Data")
        }
        self = attributedString.attributedString
    }
}
