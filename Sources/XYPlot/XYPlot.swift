//
//  XYPlot.swift
//  XYPlot
//
//  Created by Joseph Levy on 12/5/21.
//  First version with lines 12/6/21
//  Version with point symbols set up 12/21/21
//  Improved scaleAxes() & changed titles to AttributedStrings 2/10/22
//  Added support for saving plot settings and line settings to Core Data 12/13/22 ***INCOMPLETE***

import SwiftUI
import Utilities

/// Axis Parameters is an x, y or secondary (s) axis extent, tics, and tile
public struct AxisParameters : Equatable  {
    public init(min: Double = 0.0,
         max: Double = 1.0,
         majorTics: Int = 10,
         minorTics: Int = 5,
         title:  AttributedString? = nil ) {
        self.min = min
        self.max = max
        self.majorTics = majorTics
        self.minorTics = minorTics
        self.title = title
    }
    public var min = 0.0
    public var max = 1.0
    public var majorTics = 10
    public var minorTics = 5
    public var title:  AttributedString? = nil
}

/// PlotSettings is used by PlotData to define axes and axes labels
public struct PlotSettings : Equatable  {
    /// Parameters
    /// 
    public var settingsID: UUID?
    
    public var title  = AttributedString()
    
    public var xAxis : AxisParameters?
    public var yAxis : AxisParameters?
    public var sAxis : AxisParameters?

    // Computed properties for minimizing code changes when adding title to AxisParameters
    public var xTitle : AttributedString { get { xAxis?.title ?? ""} set { xAxis?.title = newValue } }
    public var yTitle : AttributedString { get { yAxis?.title ?? ""} set { yAxis?.title = newValue } }
    public var sTitle : AttributedString { get { sAxis?.title ?? ""} set { sAxis?.title = newValue } }
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
    public init(title: AttributedString = .init(), xAxis: AxisParameters? = nil, yAxis: AxisParameters? = nil,
                sAxis: AxisParameters? = nil, sizeMinor: Double = 0.005, sizeMajor: Double = 0.01,
                format: String = "%g", showSecondaryAxis: Bool = false, autoScale: Bool = true,
                independentTics: Bool = false, legendPos: CGPoint = .zero, legend: Bool = true, selection: Int? = nil) {
        self.title = title
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
    }
}

/// An element of a PlotLIne with an (x,y) point
public struct PlotPoint : Equatable {
    //CGPoint?
    var x: Double
    var y: Double
    var label: String?  // not implemented to display
    /// Used to place points on a PlotLine
    /// - Parameters:
    ///   - x: x axis point value
    ///   - y: y axis point  value
    ///   - label: unimplemented point label
}

public extension PlotPoint { /// Makes x: and y: designation unnecessary
    init(_ x: Double, _ y: Double, label: String? = nil) { self.x = x; self.y = y; self.label = label }
}

import CoreData
import Combine
/// PlotLine array is used by PlotData to define multiple  lines
public class PlotLine : RandomAccessCollection, MutableCollection, Equatable, ObservableObject
{
    static var moc: NSManagedObjectContext { XYPlot.CoreDataManager.shared.moc }
    public static func == (lhs: PlotLine, rhs: PlotLine) -> Bool {
        lhs.values == rhs.values && lhs.lineColor == rhs.lineColor &&
        lhs.lineStyle == rhs.lineStyle && lhs.secondary == rhs.secondary &&
        lhs.pointShape == rhs.pointShape && lhs.legend == rhs.legend
    }
    public var id: NSManagedObjectID? // nil if not assigned
    @Published public var values: [PlotPoint]
    @Published public var lineColor : Color
    @Published public var lineStyle: StrokeStyle
    @Published public var pointShape: ShapeParameters
    @Published public var secondary: Bool
    @Published public var legend: String?
    public var pointColor: Color { pointShape.color } // added to ShapeParameters
    public var onChangeAction: () -> Void = { }
    var subscriptions = Set<AnyCancellable>()
    /// - Parameters:
    ///   - values: PlotPoint array of line
    ///   - lineColor: line color
    ///   - lineStyle: line style
    ///   - pointColor: point symbol color
    ///   - pointShape: point symbol from ShapeParameters
    ///   - secondary: true if line should use secondary (right-side) axis
    ///   - legend: optional String of line name;
    ///
    // Consider removing pointColor and custom init
    
    public init(values: [PlotPoint] = [],
         lineColor: Color = .black,
         lineStyle: StrokeStyle = StrokeStyle(lineWidth: 2),
         pointColor: Color = .clear,
         pointShape: ShapeParameters = ShapeParameters(),
         secondary: Bool = false,
         legend: String? = nil) {
        self.values = values
        self.lineColor = lineColor
        self.lineStyle = lineStyle
        self.pointShape = pointShape
        self.secondary = secondary
        self.legend = legend
        self.pointShape.color = pointColor
        self.$pointShape.removeDuplicates().sink { newPointShape in self.onChangeAction() }.store(in: &subscriptions)
        self.$lineColor.removeDuplicates().sink { newLineColor in self.onChangeAction() }.store(in: &subscriptions)
        if self.id == nil { // Create a managed entity
            let newLine = Line(context: PlotLine.moc)
            newLine.lineStyle = 0
            newLine.lineColor = Int64(lineColor.sARGB)
            newLine.lineName = legend
            newLine.symbolColor = Int64(pointColor.sARGB)
            newLine.symbolShape = 0
            newLine.symbolSize = 1.0
            newLine.symbolFilled = false
            newLine.lineWidth = 2.0
            newLine.useRightAxis = false
            self.id = newLine.objectID
        }
    }
    
//    func onChange<T>(action: @escaping () -> Void ) { onChangeAction = action } // good place to hook up core data
    
    /// add array append and clear -- other Array methods can be added similarly
    public func append(_ plotPoint: PlotPoint) { values.append(plotPoint)}
    public func clear() { values = [] }
    
    /// Collection protocols make it work with higher order functions ( like map)
    public var startIndex: Int { values.startIndex }
    public var endIndex: Int { values.endIndex}
    public subscript(_ position: Int) -> PlotPoint {
        get { values[position] }
        set(newValue) { values[position] = newValue }
    }
}

public struct PlotData : Equatable {
    public var plotLines: [PlotLine]
    public var settings : PlotSettings
    
    static public func == (lhs: PlotData, rhs: PlotData) -> Bool {
        lhs.plotLines == rhs.plotLines && lhs.settings == rhs.settings
    }

    subscript(_ position: Int) -> PlotLine {
        get { plotLines[position] }
        set(newValue) { plotLines[position] = newValue }
    }
    
    /// PlotData is the info needed for XYPlot to display a plot
    /// - Parameters:
    ///   - plotLines: PlotLine array of the lines to plot
    ///   - settings: scaling, tics, and titles of plot
    ///   Methods:
    ///   - scaleAxes(): Adjusts settings to make plot fix in axes if autoscale is true
    ///   - axesScale(): Adjust setting to make plot fit in axes (regardlless of autoScale)
    ///   
    public init(plotLines: [PlotLine] = .init(), settings: PlotSettings)  {
        self.plotLines = plotLines; self.settings = settings
    }
    // func scaleAxes() -> PlotData .. defined in AdjustAxis.swift
    
    var hasPrimaryLines : Bool { plotLines.reduce(false, { $0 || !$1.secondary })}
    var hasSecondaryLines : Bool { plotLines.reduce(false, { $0 || $1.secondary})}
    var noSecondary : Bool { !hasPrimaryLines || !hasSecondaryLines || !settings.showSecondaryAxis}
}

/// XYPlot is a view that creates an XYPlot of PlotData with optional
public struct XYPlot: View {
    
    @Binding var data : PlotData
    
    @State private var isPresented: Bool
    @State private var xyLegendPos : CGPoint
    @State private var newLegendPos : CGPoint
    
    // State vars used with captureWidth,Height,Size
    @State private var plotAreaHeight: CGFloat
    @State private var yLabelsWidth: CGFloat
    @State private var sLabelsWidth: CGFloat
    @State private var sTitleWidth: CGFloat
    @State private var xLabelsHeight: CGFloat
    @State private var lastXLabelWidth: CGFloat
    @State private var lastYLabelHeight: CGFloat
    @State private var legendSize: CGSize
    
    public init(data: Binding<PlotData>) { // Because onAppear has bugs ??
        self._data = data
        var settings : PlotSettings { data.wrappedValue.settings }
        _isPresented = State(initialValue: false)
        _xyLegendPos = State(initialValue: .zero)
        _newLegendPos = State(initialValue: .zero)
        _plotAreaHeight = State(initialValue: 0.0)
        _yLabelsWidth = State(initialValue: 0.0)
        _sLabelsWidth = State(initialValue: 0.0)
        _sTitleWidth = State(initialValue: 0.0)
        _xLabelsHeight = State(initialValue: 0.0)
        _lastXLabelWidth = State(initialValue: 0.0)
        _lastYLabelHeight = State(initialValue: 0.0)
        _legendSize = State(initialValue: .zero)
    }
    
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
        get { settings.sAxis ?? AxisParameters() }
        set { settings.sAxis = newValue } }
    
    private var xLabels: [String] {
        (0...xAxis.majorTics).map { i in
            String(format: settings.format, zeroIfTiny(xAxis.min +
                                                       (xAxis.max - xAxis.min) * Double(i)/Double(xAxis.majorTics))) }
    }
    
    private var yLabels: [String] {
        (0...yAxis.majorTics).map { i in
            String(format: settings.format, zeroIfTiny(yAxis.min +
                                                       (yAxis.max - yAxis.min)
                                                       * Double(yAxis.majorTics - i)/Double(yAxis.majorTics))) + " " }
    }
    
    private var sLabels: [String] {
        showSecondary ? (0...sAxis.majorTics).map { i in
            " "+String(format: settings.format, zeroIfTiny(sAxis.min +
                                                           (sAxis.max - sAxis.min)  * Double(sAxis.majorTics - i)/Double(sAxis.majorTics)))+" "}
        : []
    }
    
    private func zeroIfTiny( _ value: Double, tinyValue: Double = 1e-15) -> Double {
        abs(value) > tinyValue ? value : 0.0
    }
    
    private var leadingWidth: CGFloat { yLabelsWidth }
    
    private var trailingWidth: CGFloat {
        showSecondary ? sLabelsWidth + sTitleWidth : lastXLabelWidth/2.0
    }
    
    private var topHeight: CGFloat { lastYLabelHeight/2.0}
    
    private let pad : CGFloat = 4 // Make platform dependent?
    
    @ViewBuilder private func Title(_ text: AttributedString) ->  some View {
        if text.characters.count == 0 { EmptyView() } else { Text(text) }
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Title(settings.title) // Title centered on plot area
                    .padding(.leading, leadingWidth)
                    .padding(.trailing, trailingWidth)
                    .fixedSize().frame(width: 1)
                Invisible(height: topHeight)
                    .popover(isPresented: $isPresented) {
                        PlotSettingsView(data: $data)
                    }
                HStack(spacing: 0) { // yTitle and room for labels
                    HStack(spacing: 0) {
                        Title(settings.yTitle)
                            .rotated()
                            .padding(.trailing, pad)
                        VStack(spacing: 0) {
                            ForEach(yLabels.indices, id: \.self) { i in
                                Text(yLabels[i])
                                    .captureHeight(in: $lastYLabelHeight)
                                    .frame(height: plotAreaHeight/max(1.0,CGFloat(yAxis.majorTics)))
                                
                            }
                        }
                    }.captureWidth(in: $yLabelsWidth)
                        .fixedSize()      // Avoid using the yLabels height to size //
                        .frame(height: 1) // plot area, 1 is arbitrary small no.    //
                    GeometryReader { geo in // the plotArea
                        let size = CGSize(width: geo.size.width, height: geo.size.height)
                        ZStack { // This is the plot area
                            BackgroundView() /// add size to this view as parameter for gridlines
                            /// Display the axes on layer on top of Background of ZStack
                            Path { path in path.addLines(axesPath(size))}
                                .stroke(.black, lineWidth: max(size.width, size.height)/500.0+0.5)
                            /// Display the plotLines
                            ForEach(lines.indices, id: \.self) { i in
                                let plotLine = lines[i]
                                let line = transform(plotLine: plotLine, size: size)
                                if plotLine.lineColor != .clear {
                                    Path { path in path.addLines(line)}
                                        .stroke(plotLine.lineColor, style: plotLine.lineStyle)
                                        .clipShape(Rectangle().size(size)) // don't draw out of bounds
                                }
                                if plotLine.pointColor != .clear { // for efficiency
                                    ForEach(line.indices, id: \.self) { j in
                                        let point = line[j]
                                        let inBounds = 0.0 <= point.x && point.x <= size.width &&
                                                       0.0 <= point.y && point.y <= size.height
                                        if inBounds {
                                            let x0 = size.width/2.0  // offset is from center
                                            let y0 = size.height/2.0 // w an h are divided by 2
                                            ShapeView(shape: plotLine.pointShape)
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
                                        .captureWidth(in: $lastXLabelWidth)
                                        .fixedSize()
                                        .frame(width: max(1.0,size.width/max(1.0,CGFloat(xAxis.majorTics))))
                                }
                            }
                                .captureHeight(in: $xLabelsHeight)
                                .offset(y: (size.height+xLabelsHeight)/2.0+pad)
                        )
                    }.captureHeight(in: $plotAreaHeight) // End of GeometryReader geo
                    
                    if showSecondary {
                        HStack(spacing: 0) {
                            VStack(spacing: 0) {
                                ForEach(sLabels.indices, id: \.self) { i in
                                    Text(sLabels[i])
                                        .frame(height: plotAreaHeight/CGFloat(sAxis.majorTics))
                                }
                            }.captureWidth(in: $sLabelsWidth)
                            Title(settings.sTitle)
                                .rotated(Angle(degrees: 90.0))
                                .captureWidth(in: $sTitleWidth)
                        }
                        .fixedSize()      // Don't use sTitle height //
                        .frame(height: 1) // to size plot area       //
                    } else { // leave room for last x axis label
                        Invisible(width: lastXLabelWidth/2.0)
                    }
                } // End of HStack yAxis - Plot - sAxis
                
                // Invisible space holder for x Labels
                Invisible(height: xLabelsHeight)
                Title(settings.xTitle)
                    .padding(.top, xLabelsHeight/3.0)
                    .padding(.leading, leadingWidth).padding(.trailing, trailingWidth)
                    .fixedSize()     // Don't use xTitle width //
                    .frame(width: 1) // to size plot area       //
            }// end of VStack
            GeometryReader { g in
                let offsets = scalePos(xyLegendPos,size: g.size)
                LegendView(data: $data)
                    .offset(x: offsets.x, y: offsets.y)
                    .captureSize(in: $legendSize)
                    .highPriorityGesture(
                        DragGesture()
                            .onChanged { value in
                                let position = maxmin(
                                    CGPoint(x: value.translation.width + newLegendPos.x*g.size.width,
                                            y: value.translation.height + newLegendPos.y*g.size.height),
                                    size: CGSize(width: g.size.width-legendSize.width, height: g.size.height-legendSize.height))
                                xyLegendPos = scalePos(position, size: CGSize(width: 1.0/g.size.width, height: 1.0/g.size.height))
                            }
                            .onEnded { value in
                                newLegendPos = xyLegendPos
                            }
                    )
                    .onChange(of: newLegendPos) { newPos in data.settings.legendPos = newPos }
                    .onAppear {
                        let oldPos = data.settings.legendPos
                        xyLegendPos = oldPos
                        newLegendPos = oldPos
                    }
            }
        }// end of ZStack
        .onTapGesture { 
            isPresented = true
        }
    }// End of body
    
    private func scalePos(_ p: CGPoint, size: CGSize) -> CGPoint { CGPoint(x: p.x*size.width, y: p.y*size.height ) }
    
    private func maxmin(_ point: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(x: max(min(point.x,size.width),0),y:max(min(point.y,size.height),0))
    }
    /// Creates the path that is the axes with tic marks set using the parameters in settings: PlotSetting
    ///  size is from the GeometryReader that is the area in which the plot is made
    private func axesPath(_ size: CGSize) -> [CGPoint] {
        let width: CGFloat = size.width
        let height: CGFloat = size.height
        
        var x: CGFloat = 0.0
        var y: CGFloat = height
        
        var ret: [CGPoint] = []
        let nPoints = 4*(xAxis.majorTics*xAxis.minorTics + yAxis.majorTics*yAxis.minorTics + sAxis.majorTics*sAxis.minorTics)
        
        ret.reserveCapacity(nPoints)
        /// Internal functions
        func addxy() { ret.append(CGPoint(x: x, y: y))}
        func addTic(x: CGFloat, y: CGFloat) { addxy();ret.append(CGPoint(x: x, y: y));addxy()}
        
        let dX =  width/Double(xAxis.minorTics)/Double(xAxis.majorTics)
        let dY =  height/Double(yAxis.minorTics)/Double(yAxis.majorTics)
        let dS =  height/Double(sAxis.minorTics)/Double(sAxis.majorTics)
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
        for _ in 0..<sAxis.majorTics {
            for _ in 0..<sAxis.minorTics {
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
        }//.environment(\.managedObjectContext, XYPlot.CoreDataManager.shared.persistentContainer.viewContext)
    }
}
#endif
// Some test lines
public var testPlotLines : PlotData = {
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
    line1.pointShape = ShapeParameters(shape: Polygon(sides: 4, openShape: true).path, angle: .degrees(45.0), color: .red)
    line2.lineColor = .blue
    line2.lineStyle.dash = [15,5]; line2.lineStyle.lineWidth = 2; line2.secondary = true
    var data = PlotData(plotLines:  [line1,line2], settings: .init()); data.scaleAxes()
    return data
}()


