//
//  PlotData.swift
//  XYPlot-Demo
//
//  Created by Joseph Levy on 12/22/23.
//

import SwiftUI

/// Axis Parameters is an x, y or secondary (s) axis extent, tics, and tile
public struct AxisParameters : Equatable, Codable  {
	
	public init(min: Double = 0.0, max: Double = 1.0, majorTics: Int = 10,
				minorTics: Int = 5, title: AttributedString = .init(), show: Bool = true, hideTitle: Bool = false) {
		self.min = min
		self.max = max
		self.majorTics = majorTics
		self.minorTics = minorTics
		self.title = title
		self.show = show
		self.hideTitle = hideTitle
	}
	
	public var show = true
	public var min = 0.0
	public var max = 1.0
	public var majorTics = 10
	public var minorTics = 5
	public var title = AttributedString()
	public var hideTitle: Bool = false
}

/// PlotSettings is used by PlotData to define axes and axes labels
public struct PlotSettings : Equatable, Codable  {
	/// Parameters
	public var title : AttributedString
	
	public var xAxis : AxisParameters?
	public var yAxis : AxisParameters?
	public var sAxis : AxisParameters?

	// Computed properties for minimizing code changes when adding title to AxisParameters
	public var xTitle : AttributedString { 	get { xAxis?.title ?? AttributedString()}
											set { xAxis?.title = newValue.convertToNSFonts } }
	public var yTitle : AttributedString { 	get { yAxis?.title ?? AttributedString()}
											set { yAxis?.title = newValue.convertToNSFonts } }
	public var sTitle : AttributedString { 	get { sAxis?.title ?? AttributedString()}
											set { sAxis?.title = newValue.convertToNSFonts } }
	// -----------------------------------------------------------------------------------
	public var sizeMinor = 0.005
	public var sizeMajor = 0.01
	public var format = "%g" //"%.1f"//
	public var showSecondaryAxis : Bool = false
	public var autoScale : Bool = true
	public var independentTics : Bool = false
	public var legendPos = CGPoint(x: 0, y: 0)
	public var legend = true
	public var selection : Int?
	public var savePoints: Bool
	public init(title: AttributedString = .init(), xAxis: AxisParameters? = nil, yAxis: AxisParameters? = nil,
				sAxis: AxisParameters? = nil, sizeMinor: Double = 0.005, sizeMajor: Double = 0.01,
				format: String = "%g", showSecondaryAxis: Bool = false, autoScale: Bool = true,
				independentTics: Bool = false, legendPos: CGPoint = .zero, legend: Bool = true, selection: Int? = nil,
				savePoints: Bool = true) {
		self.title = title.convertToNSFonts
		self.xAxis = xAxis
		self.yAxis = yAxis
		self.sAxis = sAxis
		self.sizeMajor = sizeMajor
		self.sizeMinor = sizeMinor
		self.format = format
		self.showSecondaryAxis = showSecondaryAxis
		self.autoScale = autoScale
		self.independentTics = independentTics
		self.legendPos = legendPos
		self.selection = selection
		self.savePoints = savePoints
	}
}

/// An element of a PlotLIne with an (x,y) point
public struct PlotPoint : Equatable, Codable {
	public init(x: Double, y: Double, label: String? = nil) {
		self.x = x
		self.y = y
		self.label = label
	}
	
	//CGPoint?
	public var x: Double
	public var y: Double
	public var label: String?  // not implemented to display
	/// Used to place points on a PlotLine
	/// - Parameters:
	///   - x: x axis point value
	///   - y: y axis point  value
	///   - label: unimplemented point label
}

public extension PlotPoint { /// Makes x: and y: designation unnecessary
	init(_ x: Double, _ y: Double, label: String? = nil) { self.x = x; self.y = y; self.label = label }
}

/// Make  StrokeStyle Codable
extension StrokeStyle: Codable {
	
	enum CodingKeys : CodingKey {
		case lineWidth, lineCap, lineJoin, miterLimit, dash, dashPhase
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.init( lineWidth:  try values.decode(CGFloat.self, forKey: .lineWidth),
				   lineCap:    CGLineCap(rawValue: try values.decode(Int32.self, forKey: .lineCap)) ?? .butt,
				   lineJoin:   CGLineJoin(rawValue: try values.decode(Int32.self, forKey: .lineJoin)) ?? .miter,
				   miterLimit: try values.decode(CGFloat.self, forKey: .miterLimit),
				   dash:       try values.decode([CGFloat].self, forKey: .dash),
				   dashPhase:  try values.decode(CGFloat.self, forKey: .dashPhase) )
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		do {
			try container.encode(lineWidth, forKey: .lineWidth)
			try container.encode(lineCap.rawValue, forKey: .lineCap)
			try container.encode(lineJoin.rawValue, forKey: .lineJoin)
			try container.encode(miterLimit, forKey: .miterLimit)
			try container.encode(dash, forKey: .dash)
			try container.encode(dashPhase, forKey: .dashPhase)
		} catch (let error) { print(error.localizedDescription) }
	}
}

/// PlotLine array is used by PlotData to define multiple  lines
public struct PlotLine : RandomAccessCollection, MutableCollection, Equatable, Codable {
	
	public static func == (lhs: PlotLine, rhs: PlotLine) -> Bool {
		lhs.values == rhs.values && lhs.lineColorInt == rhs.lineColorInt &&
		lhs.lineStyle == rhs.lineStyle && lhs.secondary == rhs.secondary &&
		lhs.pointShape == rhs.pointShape && lhs.legend == rhs.legend
	}
	
	public var values: [PlotPoint]
	       
	public var lineColor: Color { // encode and decode for Color
		get { Color(sARGB: lineColorInt)}
		set { lineColorInt = newValue.sARGB }
	}
	       var lineColorInt : Int/*Color codable substitute*/
	public var lineStyle: StrokeStyle
	public var pointShape: PointShape
	public var secondary: Bool
	public var legend: String?
	public var pointColor: Color { pointShape.color } // added to PointShape

	/// - Parameters:
	///   - values: PlotPoint array of line
	///   - lineColor: line color 
	///   - lineStyle: line style
	///   - pointColor: point symbol color
	///   - pointShape: point symbol from ShapeParameters
	///   - secondary: true if line should use secondary (right-side) axis
	///   - legend: optional String of line name;
	public init(values: [PlotPoint] = [],
				lineColor: Color = .black,
				lineStyle: StrokeStyle = StrokeStyle(lineWidth: 2),
				pointColor: Color = .clear,
				pointShape: PointShape = .init(),
				secondary: Bool = false,
				legend: String? = nil) {
		self.values = values
		self.lineColorInt = lineColor.sARGB
		self.lineStyle = lineStyle
		self.pointShape = pointShape
		self.secondary = secondary
		self.legend = legend
		self.pointShape.color = pointColor
	}
	
	/// add array append and clear -- other Array methods can be added similarly
	public mutating func append(_ plotPoint: PlotPoint) { values.append(plotPoint)}
	public mutating func clear() { values = [] }
	
	/// Collection protocols make it work with higher order functions ( like map)
	public var startIndex: Int { values.startIndex }
	public var endIndex: Int { values.endIndex}
	public subscript(_ position: Int) -> PlotPoint {
		get { values[position] }
		set(newValue) { values[position] = newValue }
	}
}

/// PlotData is the info needed for XYPlot to display a plot
/// - Parameters:
///   - plotLines: PlotLine array of the lines to plot
///   - plotSettings: scaling, tics, and titles of plot
///   - plotName: String that is unique to this data set for UserDefaults storage
///   Methods:
///   - saveToUserDefaults(): Saves to UserDefaults with key in plotName
///   - readFromUserDefaults()  // Retrieves from key plotname
///   - scaleAxes(): Adjusts settings to make plot fix in axes if autoscale is true
///   - axesScale(): Adjust setting to make plot fit in axes (regardlless of autoScale)
public struct PlotData : Equatable, Codable {
	
	public var plotLines: [PlotLine]
	public var settings : PlotSettings
	public var plotName: String?
	public init(plotLines: [PlotLine] = [], settings: PlotSettings, plotName: String? = nil) {
		self.plotLines = plotLines
		self.settings = settings
		if let plotName { self.plotName = plotName }
	}
	
	public func saveToUserDefaults() {
		guard let plotName else { return }
		let encoder = JSONEncoder()
		let plotDataToEncode = settings.savePoints ? self
		: PlotData(plotLines: plotLines.map { plotLine in
			var newLine = plotLine
			newLine.clear() // remove PlotLine values
			return newLine
		}, settings: settings, plotName: plotName)
		if let data = try? encoder.encode(plotDataToEncode) {
			//debugPrint("Saving to UserDefaults: \(plotName)")
			UserDefaults.standard.set(data, forKey: plotName)
		} else { debugPrint("Could not save to UserDefaults")}
	}
	
	mutating public func readFromUserDefaults() {
		guard let plotName else { return }
		let decoder = JSONDecoder()
		if let data = UserDefaults.standard.data(forKey: plotName),
			var plotDataFromDecode = try? decoder.decode(PlotData.self, from: data) {
			if !plotDataFromDecode.settings.savePoints { // Put existing point values in plotLines
				plotDataFromDecode.plotLines = plotDataFromDecode.plotLines.indices.map { i in
					var newLine = plotDataFromDecode.plotLines[i]
					if i < plotLines.count  {
						newLine.values = plotLines[i].values
					}
					return newLine
				}
			}
			self = plotDataFromDecode
		}
	}
	
	static public func == (lhs: PlotData, rhs: PlotData) -> Bool {
		rhs.plotLines.count == lhs.plotLines.count && lhs.settings == rhs.settings && rhs.plotLines == lhs.plotLines
	}
	
	subscript(_ position: Int) -> PlotLine {
		get { plotLines[position] }
		set(newValue) { plotLines[position] = newValue }
	}
	
	var hasPrimaryLines : Bool { plotLines.reduce(false, { $0 || !$1.secondary })}
	var hasSecondaryLines : Bool { plotLines.reduce(false, { $0 || $1.secondary})}
	var noSecondary : Bool { !hasPrimaryLines || !hasSecondaryLines || !settings.showSecondaryAxis}
}
