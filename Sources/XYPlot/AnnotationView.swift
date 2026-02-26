//
//  AnnotationView.swift
//  XYPlot
//
//  Created by Joseph Levy on 2/26/26.
//
import SwiftUI

public struct AnnotationView: View {
	@Binding public var data: PlotData
	public init(data: Binding<PlotData>) { self._data = data }
	
	public var body: some View {
		if let text = data.settings.annotation, !text.isEmpty {
			Text(text)
				.font(.system(.caption, design: .monospaced))
				.padding(6)
				.background(Color.white)
				.border(Color.black)
				.contentShape(Rectangle())
		} else { EmptyView() }
	}
}
