//
//  PlotSettingsView.swift
//  XYPlot
//
//  Created by Joseph Levy on 12/8/21.
//

import SwiftUI
import Utilities
import NumericTextField

struct fieldView : ViewModifier {
    var disable = false
    func body(content: Content) -> some View {
        content
            .padding(.trailing, 5)
            .multilineTextAlignment(.trailing)
            .frame(width: 100)
            .border(.black)
            .foregroundColor(disable ? .gray : .black)
            .disabled(disable)
    }
}

public extension View {
    func fieldViewStyle(disable: Bool) -> some View {
        modifier(fieldView(disable: disable))
    }
}

struct HorizontalPair : View {
    var caption1 : String
    @Binding var entry1 : String
    var caption2 : String
    @Binding var entry2 : String
    var disable : Bool = false
    var disableTic : Bool = false
    var body: some View {
        HStack {
            Text(caption1).padding(.horizontal).frame(width: 150)
            NumericTextField("", numericText: $entry1)
                .fieldViewStyle(disable: disable)
            Text(caption2).padding(.horizontal).frame(width: 150)
            NumericTextField("", numericText: $entry2, style: intStyle)
                .fieldViewStyle(disable: disable || disableTic)
        }
    }
}

let intStyle = NumericStringStyle(decimalSeparator: false, negatives: false, exponent: false)

public struct PlotSettingsView: View {  // Not for smaller screens
    @Environment(\.dismiss) var dismiss
    
    @Binding var data: PlotData
    
    @State private var xMin = String(0)
    @State private var xMax = String(1)
    @State private var xTicMajor = String(10)
    @State private var xTicMinor = String(5)
    @State private var yMin = String(0)
    @State private var yMax = String(1)
    @State private var yTicMajor = String(10)
    @State private var yTicMinor = String(5)
    @State private var sMin = String(0)
    @State private var sMax = String(1)
    @State private var sTicMajor = String(10)
    @State private var sTicMinor = String(5)
    @State private var autoScale = false
    @State private var useSecondary = false
    @State private var independentTics = false
    @State private var showLegend = true
    @State private var legendPos : CGPoint = .zero
    
    public init(data: Binding<PlotData>) { // Because onAppear has bug
        self._data = data
        var settings : PlotSettings { data.wrappedValue.settings }
        
        _useSecondary = State(initialValue: settings.showSecondaryAxis)
        _independentTics = State(initialValue: settings.independentTics)
        _autoScale = State(initialValue: settings.autoScale)
        _showLegend = State(initialValue: settings.legend )
        _legendPos = State(initialValue: settings.legendPos )
        
        if let xAxis = settings.xAxis {
            _xMin = State(initialValue: String(xAxis.min))
            _xMax = State(initialValue: String(xAxis.max))
            _xTicMajor = State(initialValue: String(xAxis.majorTics))
            _xTicMinor = State(initialValue: String(xAxis.minorTics))
        }
        if let yAxis = settings.yAxis {
            _yMin = State(initialValue: String(yAxis.min))
            _yMax = State(initialValue: String(yAxis.max))
            _yTicMajor = State(initialValue: String(yAxis.majorTics))
            _yTicMinor = State(initialValue: String(yAxis.minorTics))
        }
        if let sAxis = settings.sAxis {
            _sMin = State(initialValue: String(sAxis.min))
            _sMax = State(initialValue: String(sAxis.max))
            _sTicMajor = State(initialValue: String(sAxis.majorTics))
            _sTicMinor = State(initialValue: String(sAxis.minorTics))
        }
    }
    
    public var body: some View {
        VStack {
            Text("Plot Parameters").font(.title2).padding() // 1
            HStack {//2
                Spacer()//1
                Text("Auto Scale")
                CheckBoxView(checked: $autoScale)
                Spacer()
                Text("Use Secondary")
                CheckBoxView(checked: $useSecondary)
                    .onChange(of: useSecondary) { isOn in
                        if autoScale { return }
                        if !isOn {
                            if !independentTics {
                                var vMax = max(Double(yMax)!,Double(sMax)!)
                                var vMin = min(Double(yMin)!,Double(sMin)!)
                                let tics = adjustAxis(&vMin, &vMax)
                                yMax = String(vMax); yMin = String(vMin)
                                sMax = yMax; sMin = yMin
                                yTicMajor = String(tics.0); yTicMinor = String(tics.1)
                            }
                            else {
                                var vMax = Double(sMax)!
                                var vMin = Double(sMin)!
                                let tics = adjustAxis(&vMin, &vMax)
                                sMax = String(vMax); sMin = String(vMin)
                                sTicMajor = String(tics.0); sTicMinor = String(tics.1)
                            }
                        }
                    }
                Spacer()
                Text("Use Secondary Tics").foregroundColor(useSecondary ? .black : .gray)
                CheckBoxView(checked:  $independentTics )
                    .disabled(!useSecondary).foregroundColor(useSecondary ? .black : .gray).opacity(useSecondary ? 1.0 : 0.5)
                    .onChange(of: independentTics) { isOn in
                        if autoScale { return }
                        if isOn && useSecondary {
                            var vMax = Double(sMax)!
                            var vMin = Double(sMin)!
                            let tics = adjustAxis(&vMin, &vMax)
                            sMax = String(vMax); sMin = String(vMin)
                            sTicMajor = String(tics.0); sTicMinor = String(tics.1)
                        }
                        if isOn && !useSecondary {
                            sTicMajor = yTicMajor; sTicMinor = yTicMinor
                        }
                    }
                Spacer()//10
            }.frame(width: 500)
            
            HorizontalPair(caption1: "Minimum x", entry1: $xMin,
                           caption2: "Major Tics x", entry2: $xTicMajor,
                           disable: autoScale)
            HorizontalPair(caption1: "Maximum x", entry1: $xMax,
                           caption2: "Minor Tics x", entry2: $xTicMinor,
                           disable: autoScale)
            HorizontalPair(caption1: "Minimum y", entry1: $yMin,
                           caption2: "Major Tics y", entry2: $yTicMajor,
                           disable: autoScale)
            HorizontalPair(caption1: "Maximum y", entry1: $yMax,
                           caption2: "Minor Tics y", entry2: $yTicMinor,
                           disable: autoScale)
            HorizontalPair(caption1: "Minimum s", entry1: $sMin,
                           caption2: "Major Tics s", entry2: $sTicMajor,
                           disable: autoScale || !useSecondary, disableTic: autoScale || !independentTics)
            HorizontalPair(caption1: "Maximum s", entry1: $sMax,
                           caption2: "Minor Tics s", entry2: $sTicMinor,
                           disable: autoScale || !useSecondary, disableTic: autoScale || !independentTics)
            HStack { Spacer(); Text("Show Legend"); CheckBoxView(checked: $showLegend); Spacer() }.padding(.top)
            HStack {//9
                Button(action: {
                    dismiss()
                }, label: { Text("Cancel").foregroundColor(.accentColor)}).frame(width: 100).padding(.horizontal)
                Button(action: {
                    // Make copies of data to change since plotLines and settings
                    // need be fetched or stored to data Binding directly
                    var settings = data.settings
                    let plotLines = data.plotLines // save for later
                    
                    if let x = Double(xMin) { settings.xAxis?.min = x }
                    if let x = Double(xMax) { settings.xAxis?.max = x }
                    if let x = Double(yMin) { settings.yAxis?.min = x }
                    if let x = Double(yMax) { settings.yAxis?.max = x }
                    if let x = Double(sMin) { settings.sAxis?.min = x }
                    if let x = Double(sMax) { settings.sAxis?.max = x }
                    if let tic = Int(xTicMajor) { settings.xAxis?.majorTics = tic}
                    if let tic = Int(xTicMinor) { settings.xAxis?.minorTics = tic}
                    if let tic = Int(yTicMajor) { settings.yAxis?.majorTics = tic }
                    if let tic = Int(yTicMinor) { settings.yAxis?.minorTics = tic }
                    if let tic = Int(sTicMajor) { settings.sAxis?.majorTics = tic }
                    if let tic = Int(sTicMinor) { settings.sAxis?.minorTics = tic }
                    
                    settings.autoScale = autoScale
                    settings.showSecondaryAxis = useSecondary
                    settings.independentTics = independentTics
                    settings.legendPos = legendPos
                    settings.legend = showLegend
                    
                    data = PlotData(plotLines: plotLines, settings: settings)
                    data.scaleAxes()
                    dismiss()
                }) { Text("Ok").foregroundColor(.accentColor) }
                    .frame(width: 100).padding(.horizontal)
            }.font(.body)
        }
        .textFieldStyle(.plain)
        .buttonStyle(RoundedCorners(color: .white.opacity(0.1), shadow: 2 ))
        .frame(width: 550)
        .background(Color.white)
    }
}

public struct RoundedCorners: ButtonStyle {
    var color: Color
    var lineColor: Color = .black
    var shadow: CGFloat = 0
    var radius: CGFloat = 4
    let selectedColor: Color = .white
    public func makeBody(configuration: Self.Configuration) -> some View {
        let backgroundColor = configuration.isPressed ? selectedColor : color
        configuration.label
            .horizontalFill()
            .background(backgroundColor
                .clipShape(RoundedRectangle(cornerRadius: radius))
                .background(Color.white // so opacity < 1 does not let shadow thru
                    .clipShape(RoundedRectangle(cornerRadius: radius))
                )
            )
            .background(RoundedRectangle(cornerRadius: radius)
                            .stroke(lineColor, lineWidth: 1)
                            .shadow(color: .black, radius: shadow, x: shadow, y: shadow)
            )
            .padding()
    }
}

struct PlotSettingsView_Previews: PreviewProvider {
    @State static var isShowingSettings: Bool = false
    static var previews: some View {
        PlotSettingsView(data: .constant(testPlotLines) ).border(.green)
    }
}

