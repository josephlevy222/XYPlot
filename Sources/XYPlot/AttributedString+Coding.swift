//
//  AttributedString+Coding.swift
//  XYPlot-Demo
//
//  Created by Joseph Levy on 1/5/24.
//

import Foundation
import RichTextEditor
func decodeToAttributedString(_ data: Data?) -> AttributedString {
	guard let data else { return AttributedString("")}
	if let output = data.attributedString {
		return output
	} else {
		print("Here is the data"); print(data)
		return AttributedString("Could not decode to AttributedString").setFont(to: .title)
	}
}

extension Data {
	var attributedString : AttributedString? {
		let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
			.documentType: NSAttributedString.DocumentType.rtfd,
			.characterEncoding: String.Encoding.utf8
		]
		let aString = try? NSAttributedString(data: self,
											  options: options,
											  documentAttributes: nil)
		return aString?.attributedString
	}
}

extension AttributedString {
	var data : Data? {
		let options: [NSAttributedString.DocumentAttributeKey: Any] = [
			.documentType: NSAttributedString.DocumentType.rtfd,
			.characterEncoding: String.Encoding.utf8
		]
		let range = NSRange(location: 0, length: characters.count)
		
		return try? nsAttributedString.data(from: range, documentAttributes: options)
	}

	var convertToNSFonts : AttributedString { convertToUIAttributes().attributedString }
}

extension String {
	func markdownToAttributed() -> AttributedString {
		do {
			return try AttributedString(styledMarkdown: self)
		} catch {
			return AttributedString("Error parsing markdown \(error)")
		}
	}
}
