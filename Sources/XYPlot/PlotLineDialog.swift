//
//  PlotLineDialog.swift
//  XYPlot.swift
//
//  Created by Joseph Levy on 3/14/22.
//

import SwiftUI
import Utilities

public struct PlotLineDialog: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding public var plotData: PlotData
    
    init(plotData: Binding<PlotData>) { _plotData = plotData }
    @State private var i : Int = 0
    @State private var lineName : String = ""
    @State private var lineColor : Color = .black
    @State private var lineWidth : CGFloat = 1.0
    @State private var lineStyle : Int = 0
    @State private var pointColor : Color = .black
    @State private var pointStyle : Int = 0
    
    @State private var showPointStyler = false
    @State private var pointFill = false
    @State private var pointSize: CGFloat = 1.0
    
    @State private var presenting: Bool = false
    @State private var showDropdown: Bool = false
    @State private var lineOff = false
    @State private var pointOff = false
    let lineStyles: [[CGFloat]] = [[], [15,5], [5], [15,5,5,5]]
    let lineStyleNames = ["Solid", "Dashed", "Dotted", "Dashdot"].map { HTMLParser($0).attributedString }
    
    var legend : String { lineName }
    var newPointColor: Color  { pointOff ? Color.clear : pointColor }
    var newLineColor: Color { lineOff ? Color.clear : lineColor }
    @State private var savedLineColor: Color = .red
    @State private var savedPointColor: Color = .red
    @State private var useSecondary = false
    public var body: some View {
        ScrollView  {
            VStack {
                List {
                    HStack {
                        Text("\(legend)"); Spacer()
                        ZStack(alignment: .center) { // line sample
                            Path { path in path.move(to: .zero); path.addLine(to: CGPoint(x: 100, y: 0))}
                                .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, dash: lineStyles[lineStyle] ))
#if os(iOS) && !targetEnvironment(macCatalyst)
                                .frame(width: 100, height: 0.5) // height 0.5 makes the line centered on the points !?
#else
                                .frame(width: 100, height: 1.0)
#endif
							PointShapeView(shape: PointShape( {symbolShapes[pointStyle].path(in: $0)}, angle: symbolShapes[pointStyle].angle, fill: pointFill, color: pointColor, size: pointSize))
								.offset(x: -25.0, y: 0)
							PointShapeView(shape: PointShape( {symbolShapes[pointStyle].path(in: $0)}, angle: symbolShapes[pointStyle].angle, fill: pointFill, color: pointColor, size: pointSize))
                                .offset(x:  25.0, y: 0)
                        }}
                    HStack { Text("Use with right axis"); Spacer(); CheckBoxView(checked: $useSecondary)}
                    Section {
                        HStack {
                            Text("Line Name")
                            TextField("Name", text: $lineName)
                                .background(Color.white ).border( Color.black )
                        }
                        HStack(spacing: 0) {
                            ColorPicker("Line Color     ",selection: $lineColor).disabled(lineOff)
#if !targetEnvironment(macCatalyst)
                                .fixedSize()
#endif
                            Spacer()
                            Text(" Off ")
                            CheckBoxView(checked: $lineOff).onChange(of: lineOff) { off in
                                if off && lineColor != .clear { savedLineColor = lineColor }
                                lineColor = off ? .clear : savedLineColor
                            }
                        }
                        Stepper(value: $lineWidth, in: 0.0...10.0, step: 0.5 ) {
                            Text("Line Width: \(String(format: "%.1f", lineWidth))")
                                .onChange(of: lineWidth) { newWidth in
                                    if newWidth == 0.0 { lineOff = true }
                                }
                        }
                        HStack {
                            Text("Line Style")
                            Spacer()
                            Dropdown(placeHolder: "Dash" , selection: $lineStyle, options: lineStyleNames)
                        }
                    }
                    Section {
                        HStack(spacing: 0) {
                            ColorPicker("Symbol Color",selection: $pointColor).disabled(pointOff)
#if !targetEnvironment(macCatalyst)
                                .fixedSize()
#endif
                            Spacer()
                            Text(" Off ")
                            CheckBoxView(checked: $pointOff).onChange(of: pointOff) { off in
                                if off && pointColor != .clear { savedPointColor = pointColor}
                                pointColor = off ? .clear : savedPointColor
                            }
                        }
                        
                        HStack { Text("Symbol Filled");Spacer(); CheckBoxView(checked: $pointFill)}
                        HStack {
                            Text("Symbol Shape")
                            Spacer()
                            Button(action:  { showDropdown = true }) {
                                if(pointColor == Color.clear) { Text("None")}
								else {
									PointShapeView(shape: PointShape(symbolShapes[pointStyle].shapePath.path,
																angle: symbolShapes[pointStyle].angle,
																	 fill: pointFill, color: pointColor, size: pointSize))
								}
                            }
                            .popover(isPresented: $showDropdown, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                                VStack(spacing: 0) {
                                    ForEach(symbolShapes.indices, id:\.self) { i in
                                        VStack {
                                            Button(action: {
												showDropdown = false
												pointStyle = i
											}) {
												PointShapeView(shape: PointShape(symbolShapes[i].path, 
																			angle: symbolShapes[i].angle))
												.padding().contentShape(Rectangle()) }
											.background(Color.white)
											Divider()
                                        }
                                        .textFieldStyle(.automatic)
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        Stepper(value: $pointSize, in: 0.2...3.0, step: 0.2 ) {
                            Text("Symbol Size: \(String(format: "%.2f", pointSize))").fixedSize()
                        }
                    }
                }
                HStack {
                    Button("Cancel") { dismiss() }.foregroundColor(.accentColor)
                    Spacer()
                    Button(action: {
						var plotLine = PlotLine()
                        plotLine.lineColor = lineColor
                        plotLine.lineStyle = StrokeStyle(lineWidth: lineWidth, dash: lineStyles[lineStyle])
                        let shape = symbolShapes[pointStyle]
						plotLine.pointShape = PointShape(shape.path, angle: shape.angle, fill: pointFill,
														 color: pointColor, size: pointSize )
                        plotLine.legend = lineName
                        plotLine.secondary = useSecondary
						plotLine.values = plotData.plotLines[i].values
						
                        plotData.plotLines[i] = plotLine
                        plotData.scaleAxes()
                        dismiss()
					}) { Text("Ok").foregroundColor(.accentColor).contentShape(Rectangle())}
                }.buttonStyle(RoundedCorners(color: .white.opacity(0.1), shadow: 2 ))
            }
            .background(Color.white)
            .frame(width: 300, height: 620)
            .padding()
            .onAppear {
                i = plotData.settings.selection ?? 0
                let plotLine : PlotLine = plotData.plotLines[self.i]
                lineName =  plotLine.legend ?? "Trace \(self.i)"
                useSecondary = plotLine.secondary
                if plotLine.lineColor == .clear { 
					lineOff = true;
					savedLineColor = (plotLine.pointColor == .clear ? .black : plotLine.pointColor) } else { lineOff = false }
                if plotLine.pointColor == .clear { 
					pointOff = true;
					savedPointColor = (plotLine.lineColor == .clear ? .black : plotLine.lineColor) } else { pointOff = false }
                lineColor = plotLine.lineColor
                pointColor = plotLine.pointColor
                lineWidth = plotLine.lineStyle.lineWidth
                lineStyle = lineStyles.firstIndex(of: plotLine.lineStyle.dash ) ?? 0
				pointStyle = symbolShapes.firstIndex { $0.equalPathandAngle(plotLine.pointShape) }
				?? {
					symbolShapes.append(PointShape(plotLine.pointShape.path, angle: plotLine.pointShape.angle))
					print("Adding shape to symbolShapes")
					return symbolShapes.count-1
				}()
                pointFill = plotLine.pointShape.fill
                pointSize = plotLine.pointShape.size
            }
        }
		.fixedSize()
    }
}

public var symbolShapes : [PointShape] = [ // Default shapes
	.init(Polygon(sides: 4).path), // Diamond
    .init(Polygon(sides: 4).path, angle: .degrees(45.0)),// Square
    .init(Circle().path), // Circle
    .init(Polygon(sides: 3).path, angle: .degrees(-90.0)),// Triangle
    .init(Polygon(sides: 6, openShape: true).path),// Asterix
    .init(Polygon(sides: 4, openShape: true).path, angle: .degrees(45.0)), // X
    .init(Polygon(sides: 4, openShape: true).path) // +
]


#if DEBUG
struct PlotLineDialog_Previews: PreviewProvider {
    
    static var previews: some View {
		PlotLineDialog(plotData: .constant(testPlotLines)).border(Color.green)
        
    }
}
#endif
