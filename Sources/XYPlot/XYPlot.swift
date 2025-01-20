//
//  XYPlot.swift
//  XYPlot
//
//  Created by Joseph Levy on 12/5/21.
//  First version with lines 12/6/21
//  Version with point symbols set up 12/21/21
//  Improved scaleAxes() & changed titles to AttributedStrings 2/10/22
//  Changed PlotSettings to struct for view updates to happen promptly 1/6/23
//  Added styledMarkdown: for AttributedString init and styledHeader func to use Headers in markdown 1/8/23
//  Completed changes back to AttributedString storing as Data to Coredata 1/10/23
//  Simplied/removed explicit init on a number of struct 1/10/23
//  Added Coredata support and
//  Added TextView for editing titles 7/2/23
//  Switched to RichTextEditor for titles 11/17/23
//  Switched to EditableText for titles from RichTextEditor 08/30/24
//  Modified to use UserDefaults rather than Coredata making PlotData Codable

import SwiftUI
import Utilities
//import RichTextEditor
import EditableText

extension View {
	/// Hide or show the view based on a boolean value.
	/// Example for visibility:
	///     Text("Label")
	///         .isHidden(true)
	/// Example for complete removal:
	///     Text("Label")
	///         .isRemoved(true)
	/// - Parameters:
	///    In isHidden
	///   - hidden: Set to `false` to show the view. Set to `true` to hide the view.
	///    In isRemoved
	///   - remove: Boolean value indicating whether or not to remove the view.
	///   Thanks to George Elsham on Stack Overflow for the idea for these. I separated into two functions
	@ViewBuilder func isHidden(_ hidden: Bool) -> some View {
		if hidden { self.hidden() } else { self }
	}
	@ViewBuilder func isRemoved(_ remove: Bool) -> some View {
		if !remove { self }
	}
}

public struct XYPlotTitle: View {
	@Binding public var text: AttributedString
	@State private var isPresented = false
	
	var hideAddTitleButton = false
	let overlayEditor: Bool
	public init(_ text: Binding<AttributedString>, inPlaceEditing: Bool = false, hideAddTitleButton: Bool = false) {
		_text = text
		overlayEditor = inPlaceEditing
		self.hideAddTitleButton = hideAddTitleButton
	}
	private var overlayEdit : Bool { overlayEditor && text.characters.count != 0}
	public var body: some View {
		ZStack {
			Button("Add a Title") {
				text = AttributedString("Title").setFont(to: Font.title)
				withAnimation { isPresented = !overlayEditor }
			}
			.font(.footnote)
			.isHidden(hideAddTitleButton || text.characters.count != 0)
		
			EditableText($text).isHidden(!overlayEdit)
			EditableTextInPopover($text).isHidden(overlayEdit)
				.padding(.leading)
		}
	}
}
/// XYPlot is a view that creates an XYPlot of PlotData with optional
public struct XYPlot: View {
	public init(data: Binding<PlotData>) {
		self._data = data
		print("-", terminator: "")
	}
	
	@Binding public var data : PlotData
	
	@State public  var isPresented: Bool = false
	
	@State private var xyLegendPos : CGPoint = .zero
	
	// State vars used with captureWidth,Height,Size
	private struct Captures: Codable {
		var plotAreaHeight: CGFloat = 0.0
		var yLabelsWidth: CGFloat = 0.0
		var sLabelsWidth: CGFloat = 0.0
		var sTitleWidth: CGFloat = 0.0
		var xLabelsHeight: CGFloat = 0.0
		var lastXLabelWidth: CGFloat = 0.0
		var lastYLabelHeight: CGFloat = 0.0
		var legendSize: CGSize = .zero
	}
	@State private var captures = Captures()
	var plotAreaHeight: CGFloat { get {captures.plotAreaHeight}}
	var yLabelsWidth: CGFloat { captures.yLabelsWidth }
	var sLabelsWidth: CGFloat { captures.sLabelsWidth }
	var sTitleWidth: CGFloat { captures.sTitleWidth }
	var xLabelsHeight: CGFloat { captures.xLabelsHeight }
	var lastXLabelWidth: CGFloat { captures.lastXLabelWidth }
	var lastYLabelHeight: CGFloat { captures.lastYLabelHeight}
	var legendSize: CGSize { captures.legendSize }
	
	// Computed variables
	
	private var settings : PlotSettings { get { data.settings } set { data.settings = newValue } }
	private var lines : [PlotLine] { data.plotLines }
	private var selection : Int? { data.settings.selection }
	
	private var showSecondary : Bool { settings.showSecondaryAxis && !data.noSecondary }
	
	private var xAxis : AxisParameters {
		get { settings.xAxis ?? AxisParameters() }
		set { settings.xAxis = newValue } }
	private var yAxis : AxisParameters {
		get { settings.yAxis ?? AxisParameters() }
		set { settings.yAxis = newValue } }
	private var sAxis : AxisParameters {
		get { showSecondary ? settings.sAxis ?? AxisParameters() : yAxis }
		set { settings.sAxis = newValue  } }
	
	private var xLabels: [String] {
		(0...xAxis.majorTics).map { i in
			String(format: settings.format, zeroIfTiny(xAxis.min + (xAxis.max - xAxis.min) * Double(i)/Double(xAxis.majorTics))) }
	}
	
	private var yLabels: [String] {
		(0...yAxis.majorTics).map { i in
			String(format: settings.format,
				   zeroIfTiny(yAxis.min + (yAxis.max - yAxis.min) * Double(yAxis.majorTics - i)/Double(yAxis.majorTics))) + " " }
	}
	
	private var sLabels: [String] {
		showSecondary ? (0...sAxis.majorTics).map { i in
			" "+String(format: settings.format, zeroIfTiny(sAxis.min + (sAxis.max - sAxis.min)
														   * Double(sAxis.majorTics - i)/Double(sAxis.majorTics)))+" "}
		: []
	}
	
	private func zeroIfTiny( _ value: Double, tinyValue: Double = 1e-15) -> Double {
		abs(value) > tinyValue ? value : 0.0
	}
	
	private var leadingWidth: CGFloat { yLabelsWidth }
	
	private var trailingWidth: CGFloat {
		showSecondary ? sLabelsWidth + sTitleWidth : lastXLabelWidth/2.0
	}
	
	private var topMostLabelHeight: CGFloat { lastYLabelHeight/2.0}
	
	private let pad : CGFloat = 4 // Make platform dependent?
	
	public var body: some View {
		ZStack {
			VStack(spacing: 0) {
				XYPlotTitle($data.settings.title, inPlaceEditing: true )
				// Title centered on plot area
					.padding(.leading, leadingWidth)
					.padding(.trailing, trailingWidth)
					.fixedSize().frame(width: 1)
				Invisible(height: topMostLabelHeight)
					.popover(isPresented: $isPresented) {
						PlotSettingsView(data: $data)
					}
				HStack(spacing: 0) {
					HStack(spacing: 0) { // the yAxis Title and Labels
						XYPlotTitle($data.settings.yTitle)
							.rotated()
							.padding(.trailing, pad)
						VStack(spacing: 0) {
							ForEach(yLabels.indices, id: \.self) { i in
								Text(yLabels[i])
									.captureHeight(in: $captures.lastYLabelHeight)
									.frame(height: plotAreaHeight/max(1.0,CGFloat(yAxis.majorTics)))
							}
						}
					}.captureWidth(in: $captures.yLabelsWidth)
						.fixedSize()      // Avoid using the yLabels height to size //
						.frame(height: 1) // plot area, 1 is arbitrary small no.    //
					GeometryReader { geo in // the plotArea
						let size = geo.size
						ZStack { // This is the plot area
							BackgroundView() /// add size to this view as parameter for gridlines
							/// Display the axes on layer on top of Background of ZStack
							Path { path in path.addLines(axesPath(size))}
								.stroke(.black, lineWidth: max(size.width, size.height)/500.0+0.5)
							/// Display the plotLines
							ForEach(lines.indices, id: \.self) { i in
								let line: PlotLine = lines[i]
								if line.lineColor != .clear {
									Path { path in path.addLines(transform(plotLine: line, size: size))}
										.stroke(line.lineColor, style: line.lineStyle)
										.clipShape(Rectangle().size(size)) // don't draw out of bounds
								}
								if line.pointColor != .clear { // for efficiency
									let points = transform(plotLine: line, size: size)
									ForEach(line.indices, id: \.self) { j in
										let point = points[j]
										let inBounds = 0.0 <= point.x && point.x <= size.width &&
										0.0 <= point.y && point.y <= size.height
										if inBounds {
											let x0 = size.width/2.0  // offset is from center
											let y0 = size.height/2.0 // w an h are divided by 2
											PointShapeView(shape: lines[i].pointShape)
												.offset(x: point.x - x0, y: point.y - y0)
										}
									}
								}
							}
						}
						.overlay( //  xLabels
							HStack(spacing: 0) {
								ForEach(xLabels.indices, id: \.self) { i in
									Text(xLabels[i])
										.captureWidth(in: $captures.lastXLabelWidth)
										.fixedSize()
										.frame(width: max(1.0,size.width/max(1.0,CGFloat(xAxis.majorTics))))
								}
							}
								.captureHeight(in: $captures.xLabelsHeight)
								.offset(y: (size.height+xLabelsHeight)/2.0+pad)
						)
					}.captureHeight(in: $captures.plotAreaHeight) // End of GeometryReader geo
						.onTapGesture {
							isPresented = true
						}
					if showSecondary {
						HStack(spacing: 0) {
							VStack(spacing: 0) {
								ForEach(sLabels.indices, id: \.self) { i in
									Text(sLabels[i])
										.frame(height: plotAreaHeight/CGFloat(sAxis.majorTics))
								}
							}.captureWidth(in: $captures.sLabelsWidth)
							XYPlotTitle($data.settings.sTitle)
								.rotated(Angle(degrees: 90.0))
								.captureWidth(in: $captures.sTitleWidth)
						}
						.fixedSize()      // Don't use sTitle height //
						.frame(height: 1) // to size plot area       //
					} else { // leave room for last x axis label
						Invisible(width: lastXLabelWidth/2.0)
					}
				} // End of HStack yAxis - Plot - sAxis
				
				// Invisible space holder for x Labels
				Invisible(height: xLabelsHeight)
				XYPlotTitle($data.settings.xTitle, inPlaceEditing: true)
					.padding(.top, xLabelsHeight/3.0)
					.padding(.leading, leadingWidth).padding(.trailing, trailingWidth)
					.fixedSize()     // Don't use xTitle width //
					.frame(width: 1) // to size plot area       //
			}// end of VStack
			GeometryReader { g in // topmost of ZStack the whole frame
				let plotAreaWidth = g.size.width - leadingWidth - trailingWidth
				LegendView(data: $data)
					.offset(x: xyLegendPos.x*plotAreaWidth, y: xyLegendPos.y*plotAreaHeight)
					.captureSize(in: $captures.legendSize)
					.highPriorityGesture(
						DragGesture()
							.onChanged { value in
								let plotAreaWidth = g.size.width-leadingWidth-trailingWidth
								let position = maxmin(
									CGPoint(x: value.translation.width + data.settings.legendPos.x*plotAreaWidth,
											y: value.translation.height + data.settings.legendPos.y*plotAreaHeight),
									size: CGSize(width: g.size.width-legendSize.width,
												 height: g.size.height-legendSize.height))
								xyLegendPos = CGPoint(x: position.x/plotAreaWidth, y: position.y/plotAreaHeight)
							}
							.onEnded { value in
								data.settings.legendPos =  xyLegendPos
								data.saveToUserDefaults()
							}
					)
					.onChange(of: data.settings.legendPos) { debugPrint("xyLegendPos Change"); xyLegendPos = $0 }
					.onAppear {
						debugPrint("XYPlot appears")
						data.readFromUserDefaults()
						xyLegendPos = data.settings.legendPos
						data.scaleAxes()
					}
			}
			.onChange(of: data, debounceTime: 0.4) { $0.saveToUserDefaults() }
		}// end of ZStack
	}// End of body
	
	private func maxmin(_ point: CGPoint, size: CGSize) -> CGPoint {
		CGPoint(x: max(min(point.x,size.width),0),y: max(min(point.y,size.height),0))
	}
	/// Creates the path that is the axes with tic marks set using the parameters in settings: PlotSetting
	///  size is from the GeometryReader that is the area in which the plot is made
	private func axesPath(_ size: CGSize) -> [CGPoint] {
		let width: CGFloat = size.width
		let height: CGFloat = size.height
		
		var x: CGFloat = 0.0
		var y: CGFloat = height
		
		var ret: [CGPoint] = []
		let nPoints = 4*(xAxis.majorTics*xAxis.minorTics + yAxis.majorTics*yAxis.minorTics +
						 (showSecondary ? sAxis.majorTics*sAxis.minorTics : yAxis.majorTics*yAxis.minorTics))
		ret.reserveCapacity(nPoints)
		/// Internal functions
		func addxy() { ret.append(CGPoint(x: x, y: y))}
		func addTic(x: CGFloat, y: CGFloat) { addxy();ret.append(CGPoint(x: x, y: y));addxy()}
		
		let dX =  width/Double(xAxis.minorTics)/Double(xAxis.majorTics)
		let dY =  height/Double(yAxis.minorTics)/Double(yAxis.majorTics)
		let dS =  showSecondary ? height/Double(sAxis.minorTics)/Double(sAxis.majorTics) : dY
		let diagonal = sqrt(height*height + width*width)
		let minorY = diagonal*settings.sizeMinor
		let majorY = diagonal*settings.sizeMajor
		let minorX = diagonal*settings.sizeMinor
		let majorX = diagonal*settings.sizeMajor
		for _ in 0..<xAxis.majorTics {
			for _ in 0..<xAxis.minorTics {
				addTic(x: x, y: height - minorY)
				x += dX
			}// Bottom
			addTic(x: x, y: height - majorY)
		}
		for _ in 0..<(showSecondary ? sAxis.majorTics : yAxis.majorTics) {
			for _ in 0..<(showSecondary ? sAxis.minorTics : yAxis.minorTics) {
				addTic(x: width - minorX, y: y)
				y -= dS
			} // Trailing
			addTic(x: x - majorX, y: y)
		}
		for _ in 0..<xAxis.majorTics {
			for _ in 0..<xAxis.minorTics {
				addTic(x: x, y: minorY)
				x -= dX
			} // Top
			addTic(x: x, y: majorY)
		}
		for _ in 0..<yAxis.majorTics {
			for _ in 0..<yAxis.minorTics {
				addTic(x: minorX, y: y)
				y += dY
			} // Leading
			addTic(x: x + majorX, y: y)
		}
		return ret
	}
	
	private func transform(plotLine: PlotLine , size: CGSize) -> [CGPoint] {
		plotLine.map { point in
			let width = size.width
			let height = size.height
			let x1: Double = point.x, y1: Double = point.y
			let xMin = xAxis.min, xMax = xAxis.max
			let yMin = plotLine.secondary && showSecondary ? sAxis.min : yAxis.min
			let yMax = plotLine.secondary && showSecondary ? sAxis.max : yAxis.max
			let p = CGPoint(x: width*(x1-xMin)/Double((xMax-xMin)),
							y: height*(1.0-(y1-yMin)/(yMax-yMin)))
			if p.x.isNaN || p.y.isNaN { return CGPoint.zero }
			return p
		}
	}
}

// Invisible space holder
public struct Invisible: View {
	var width: CGFloat = 0
	var height: CGFloat = 0
	
	init(width: CGFloat = 0,
		 height: CGFloat = 0) { self.width = width; self.height = height }
	public var body: some View {
		Color.clear
			.frame(width: width, height: height)
	}
}

public struct BackgroundView: View {
	public var body: some View {
		Color.white
		//Rectangle().foregroundColor(.white)
		// Could put grid line paths here
	}
}
#if DEBUG
// From Jim Dovey on Apple Developers Forum
// used this allow the use of State var in preview
// https://developer.apple.com/forums/thread/118589
// seems slow...
struct StatefulPreviewWrapper<Value, Content: View>: View {
	@State var value: Value
	var content: (Binding<Value>) -> Content
	
	var body: some View {
		content($value)
	}
	
	init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
		self._value = State(wrappedValue: value)
		self.content = content
	}
}

struct XYPlot_Previews: PreviewProvider {
	static var previews: some View {
		
		Group {
			StatefulPreviewWrapper(testPlotLines) {
				XYPlot(data: $0 ) }//testPlotLines ) //}
			.frame(width: 700, height: 500).border(Color.green)
		}
	}
}
#endif

// Some test lines
var testSettings  = PlotSettings(
	title: "# **Also a very very long plot title**".markdownToAttributed(),
	xAxis: AxisParameters(title: "## Much Longer Horizontal Axis Title".markdownToAttributed()),
	yAxis: AxisParameters(title: "## Incredibly Long Vertical Axis Title".markdownToAttributed()),
	sAxis: AxisParameters(title: "### Smaller Font Secondary Axis Title".markdownToAttributed()),
	savePoints: false
)

public var testPlotLines = {
	
	var line1 = PlotLine()
	var line2 = PlotLine()
	let π = Double.pi
	var x : Double
	var y : Double
	var y2: Double
	for i in 0...100 {
		x = Double(i)*0.03
		y = 2.9*exp(-(x-1.0)*(x-1.0)*16.0)
		line1.append(PlotPoint(x,y))
		y2 = 0.3*(sin(x*π)+1.0)
		line2.append(PlotPoint(x,y2))
	}
	line1.lineColor = .red;
	line1.pointShape = PointShape(Polygon(sides: 4, openShape: true).path, angle: .degrees(45.0), color: .red)
	line2.lineColor = .blue
	line2.lineStyle.dash = [15,5]; line2.lineStyle.lineWidth = 2; line2.secondary = true
	var plotData = PlotData(plotLines: [line1,line2], settings: testSettings, plotName: "Graph 1")
	plotData.scaleAxes()
	return plotData
}()


