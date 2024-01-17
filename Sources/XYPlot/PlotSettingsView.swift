//
//  PlotSettingsView.swift
//  XYPlot
//
//  Created by Joseph Levy on 12/8/21.
//
import SwiftUI
import Utilities
import NumericTextField

struct fieldViewModifier : ViewModifier {
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
		modifier(fieldViewModifier(disable: disable))
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

struct PlotSettingsViewModel {
	var settings: PlotSettings
	var x : AxisStrings
	var y : AxisStrings
	var s : AxisStrings

	struct AxisStrings {
		var from: AxisParameters?
		var min = String(0)
		var max = String(1)
		var majorTics = String(10)
		var minorTics = String(5)
		init(_ axis: AxisParameters?) {
			from = axis
			min = String(axis?.min ?? 0)
			max = String(axis?.max ?? 1)
			majorTics = String(axis?.majorTics ?? 10)
			minorTics = String(axis?.minorTics ?? 5)
		}
		var axisParameters: AxisParameters? {
			var from = from
			if let x = Double(min) { from?.min = x }
			if let x = Double(max) { from?.max = x }
			if let tic = Int(majorTics) { from?.majorTics = tic }
			if let tic = Int(minorTics) { from?.minorTics = tic }
			return from
		}
	}
	public init(data: PlotData) {
		settings = data.settings
		x = AxisStrings(settings.xAxis)
		y = AxisStrings(settings.yAxis)
		s = AxisStrings(settings.sAxis)
	}
}

public struct PlotSettingsView: View {  // Not for smaller screens
	@Binding var data: PlotData
	
	@Environment(\.dismiss) var dismiss
	@State private var vm : PlotSettingsViewModel
	
	public init(data: Binding<PlotData>) {
		_data = data
		_vm = State(initialValue: PlotSettingsViewModel(data: data.wrappedValue))
	}
	
	public var body: some View {
		VStack {
			Text("Plot Parameters").font(.title2).padding() // 1
			HStack {//2
				Spacer()//1
				Text("Auto Scale")
				CheckBoxView(checked: $vm.settings.autoScale)
				Spacer()
				Text("Use Secondary")
				CheckBoxView(checked: $vm.settings.showSecondaryAxis)
					.onChange(of: vm.settings.showSecondaryAxis) { isOn in
						if vm.settings.autoScale { return }
						if !isOn {
							if !vm.settings.independentTics {
								var vMax = max(Double(vm.y.max)!,Double(vm.s.max)!)
								var vMin = min(Double(vm.y.min)!,Double(vm.s.min)!)
								let tics = adjustAxis(&vMin, &vMax)
								vm.y.max = String(vMax); vm.y.max = String(vMin)
								vm.s.max = vm.y.max; vm.s.min = vm.y.min
								vm.y.majorTics = String(tics.0); vm.y.minorTics = String(tics.1)
							}
							else {
								var vMax = Double(vm.s.max)!
								var vMin = Double(vm.s.min)!
								let tics = adjustAxis(&vMin, &vMax)
								vm.s.max = String(vMax); vm.s.min = String(vMin)
								vm.s.majorTics = String(tics.0); vm.s.minorTics = String(tics.1)
							}
						}
					}
				Spacer()
				Text("Use Secondary Tics").foregroundColor(vm.settings.showSecondaryAxis ? .black : .gray)
				CheckBoxView(checked:  $vm.settings.independentTics )
					.disabled(!vm.settings.showSecondaryAxis)
					.foregroundColor(vm.settings.showSecondaryAxis ? .black : .gray)
					.opacity(vm.settings.showSecondaryAxis ? 1.0 : 0.5)
					.onChange(of: vm.settings.independentTics) { isOn in
						if vm.settings.autoScale { return }
						if isOn && vm.settings.showSecondaryAxis {
							var vMax = Double(vm.s.max)!
							var vMin = Double(vm.s.min)!
							let tics = adjustAxis(&vMin, &vMax)
							vm.s.max = String(vMax); vm.s.min = String(vMin)
							vm.s.majorTics = String(tics.0); vm.s.minorTics = String(tics.1)
						}
						if isOn && !vm.settings.showSecondaryAxis {
							vm.s.majorTics = vm.y.majorTics
							vm.s.minorTics = vm.y.minorTics
						}
					}
				Spacer()//10
			}.frame(width: 500)
			
			HorizontalPair(caption1: "Minimum x", entry1: $vm.x.min,
						   caption2: "Major Tics x", entry2: $vm.x.majorTics,
						   disable: vm.settings.autoScale)
			HorizontalPair(caption1: "Maximum x", entry1: $vm.x.max,
						   caption2: "Minor Tics x", entry2: $vm.x.minorTics,
						   disable: vm.settings.autoScale)
			HorizontalPair(caption1: "Minimum y", entry1: $vm.y.min,
						   caption2: "Major Tics y", entry2: $vm.y.majorTics,
						   disable: vm.settings.autoScale)
			HorizontalPair(caption1: "Maximum y", entry1: $vm.y.max,
						   caption2: "Minor Tics y", entry2: $vm.y.minorTics,
						   disable: vm.settings.autoScale)
			HorizontalPair(caption1: "Minimum s", entry1: $vm.s.min,
						   caption2: "Major Tics s", entry2: $vm.s.majorTics,
						   disable: vm.settings.autoScale || !vm.settings.showSecondaryAxis,
						   disableTic: vm.settings.autoScale || !vm.settings.independentTics)
			HorizontalPair(caption1: "Maximum s", entry1: $vm.s.max,
						   caption2: "Minor Tics s", entry2: $vm.s.minorTics,
						   disable: vm.settings.autoScale || !vm.settings.showSecondaryAxis,
						   disableTic: vm.settings.autoScale || !vm.settings.independentTics)
			HStack { Spacer(); Text("Show Legend"); CheckBoxView(checked: $vm.settings.legend); Spacer() }.padding(.top)
			HStack {//9
				Button(action: {
					dismiss()
				}, label: { Text("Cancel").foregroundColor(.accentColor)}).frame(width: 100).padding(.horizontal)
				Button(action: { // Ok button
					vm.settings.xAxis = vm.x.axisParameters
					vm.settings.yAxis = vm.y.axisParameters
					vm.settings.sAxis = vm.s.axisParameters

					data.settings = vm.settings
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
//#if DEBUG
struct PlotSettingsView_Previews: PreviewProvider {
	@State static var isShowingSettings: Bool = false
	static var previews: some View {
		PlotSettingsView(data: .constant(testPlotLines) ).border(.green)
	}
}
//#endif
