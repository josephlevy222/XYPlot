//
//  LegendView.swift
//  XYPlot
//
//  Created by Joseph Levy on 3/4/22.
//

import SwiftUI


public struct LegendView: View {
    @Binding public var data: PlotData
    public init(data: Binding<PlotData>) { self._data = data }
    var lines : [PlotLine] { data.plotLines }
    
    @State private var isPresented = false
    
    @ViewBuilder public func arrow(show: Bool, left: Bool = true) -> some View {
        if !data.noSecondary {
			PointShapeView(shape: PointShape(Arrow(left: left).path, color: show ? .black : .white))}
        else { EmptyView() }
    }
    
    public var body: some View {
        if (data.settings.legend ) {
            Group {
                VStack(spacing: 0) {
                    Color.clear.frame(width: 50, height: 2)
                    ForEach(0..<lines.count, id: \.self) { i in
                        Button(action: {
                            data.settings.selection = i
                            isPresented = true
                        }) { // Label
                            HStack(alignment: .bottom) {
                                Color.clear.frame(width: 1, height: 2)
                                arrow(show: !lines[i].secondary, left: true)
                                VStack(spacing: 0) {
                                    Color.clear.frame(width: 50, height: 2)
                                    let legend = (lines[i].legend ?? "" == "" ) ?  "Trace \(i)" : lines[i].legend!
                                    Text(legend).font(.footnote).frame(minWidth: 50).padding(.bottom, 4)
                                    ZStack {
                                        Path { path in path.move(to: .zero); path.addLine(to: CGPoint(x: 50, y: 0))}
                                            .stroke(lines[i].lineColor, style: lines[i].lineStyle)
											#if os(iOS) && !targetEnvironment(macCatalyst)
                                            .frame(width: 50, height: 0.5) // height 0.5 makes the line centered on the points !?
											#else
                                            .frame(width: 50, height: 1.0) // need at least 1.0 for macOS
											#endif
										PointShapeView(shape: lines[i].pointShape)
                                            .offset(x: -10.0, y: 0).frame(height: 1)
										PointShapeView(shape: lines[i].pointShape).frame(height: 1)
                                            .offset(x:  10.0, y: 0)
                                    }
                                }
                                arrow(show: lines[i].secondary, left: false)
                                Color.clear.frame(width: 1, height: 1)
                            }
                        }.contentShape(Rectangle()).buttonStyle(.plain)
                    }
                    Color.clear.frame(width: 50, height: 10)
                }.background(Color.white).contentShape(Rectangle()).border(Color.black)
            }.popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds) ) { PlotLineDialog(plotData: $data)  }
        } else { EmptyView() }
    }
}
#if DEBUG
struct LegendView_Previews: PreviewProvider {
    static var previews: some View {
		LegendView(data:  .constant(testPlotLines) ) //}
    }
}

#endif
