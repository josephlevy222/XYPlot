//
//  AdjustAxis.swift
//  XYPlot
//
//  Created by Joseph Levy on 12/9/21.
//
import Foundation

public func pow10(_ x: Double) -> Double { pow(10.0, x) }
public typealias MajorMinor = (Int, Int)

let safe = 0.999 // allow 0.1% out of axes.

func bestTics(min: inout Double, max: inout Double) -> MajorMinor {
	let d = max - min
	var p: MajorMinor = (10, 5)
	var incRange = 0.0
	
	switch Int(d) {
	case 2:     		p = (10, 4)
	case 3, 30: 	 	p = (6, 5)
	case 4:     		p = (8, 5)
	case 5, 25: 		p = (10, 5)
	case 6, 12, 24: 	p = (6, 4)
	case 7...11: 		p = (Int(d), 5)
	case 13: 			p = (7, 4); 	incRange = 1
	case 14, 28: 		p = (7, 4)
	case 15: 			p = (10, 3)
	case 16, 32: 		p = (8, 4)
	case 17: 			p = (9, 4); 	incRange = 1
	case 18: 			p = (9, 4)
	case 19: 			p = (10, 4); 	incRange = 1
	case 20: 			p = (10, 4)
	case 21: 			p = (7, 3)
	case 22: 			p = (11, 4)
	case 23: 			p = (6, 4); 	incRange = 1
	case 26: 			p = (9, 3); 	incRange = 1
	case 27: 			p = (9, 3)
	case 29:		 	p = (6, 5); 	incRange = 1
	case 31: 			p = (8, 4); 	incRange = 1
	case 33: 			p = (11, 3)
	case 34: 			p = (7, 5); 	incRange = 1
	case 35: 			p = (7, 5)
	case 36...40: 		p = (8, 5); 	incRange = 40 - d
	case 41...45: 		p = (9, 5); 	incRange = 45 - d
	case 46...50: 		p = (10, 5); 	incRange = 50 - d
	case 51...55: 		p = (11, 5); 	incRange = 55 - d
	case 56...60: 		p = (6, 5); 	incRange = 60 - d
	case 61...70: 		p = (7, 5); 	incRange = 70 - d
	case 71...80: 		p = (8, 5); 	incRange = 80 - d
	case 81...90: 		p = (9, 5); 	incRange = 90 - d
	case 91...100: 		p = (10, 5); 	incRange = 100 - d
	default: break
	}
	
	if min < 0 {
		min -= incRange
		let step = Int(max - min) / p.0
		if step != 0 {
			min += Double(Int(min) % step)
			max += Double(Int(max) % step)
			p.0 = Int(max - min) / step
		}
	} else {
		max += incRange
	}
	return p
}

func adjustAxis(_ lower: inout Double, _ upper: inout Double) -> MajorMinor {
	if lower > upper { swap(&lower, &upper) }
	if lower.isNaN || upper.isNaN || lower.isInfinite || upper.isInfinite {
		(lower, upper) = (0, 1)
		return (0, 0)
	}
	
	let nabs = max(abs(lower), abs(upper))
	guard nabs > 0 && nabs != .infinity else {
		(lower, upper) = (0, 1)
		return (0, 0)
	}
	
	let e = pow10(floor(log10(nabs * safe)) - 1.0)
	if upper == lower { lower -= 0.5 * e; upper += 0.5 * e }
	
	var imax = ceil((upper < 0 ? upper / safe : upper * safe) / e)
	var imin = floor((lower < 0 ? lower * safe : lower / safe) / e)
	var p: MajorMinor = (10, 5)
	
	if imin < 0 && imax > 0 { // Force zero as a tic
		var zero = 0.0
		var pu = bestTics(min: &zero, max: &imax)
		var pl = bestTics(min: &imin, max: &zero)
		p.0 = pl.0 + pu.0
		
		if imax * Double(pl.0) != -imin * Double(pu.0) {
			if imax >= -imin {
				imin = -ceil(-imin / imax * Double(pu.0)) * imax / Double(pu.0)
				p.0 = pu.0 - Int(floor(imin * Double(pu.0) / imax))
			} else {
				imax = -ceil(-imax / imin * Double(pl.0)) * imin / Double(pl.0)
				p.0 = pl.0 - Int(floor(imax * Double(pl.0) / imin))
				swap(&pu, &pl)
				swap(&imin, &imax)
			}
		}
		
		if p.0 > 11 {
			let step = (imax - imin) / Double(p.0)
			let uEven = pu.0 % 2 == 0
			let lEven = (p.0 - pu.0) % 2 == 0
			
			if !uEven { imax += step }
			if !lEven { imin -= step }
			
			// Recompute p.0 correctly via boolean map instead of nested structures
			p.0 = (uEven && lEven) ? p.0 / 2 : (p.0 + (!uEven && !lEven ? 2 : 1)) / 2
		}
		if imax < imin { swap(&imin, &imax) }
	} else {
		p = bestTics(min: &imin, max: &imax)
	}
	
	(lower, upper) = (e * imin, e * imax)
	return p
}

extension PlotData {
	mutating public func scaleAxes() {
		if settings.autoScale { axesScale() }
	}
	
	mutating public func axesScale() {
		if plotLines.isEmpty { return }
		var newData = self
		
		var (xMin, xMax) = (Double.infinity, -Double.infinity)
		var (yMin, yMax) = (Double.infinity, -Double.infinity)
		var (sMin, sMax) = (Double.infinity, -Double.infinity)
		
		// Compute min/max for Lines
		for plotLine in plotLines {
			xMin = min(xMin, plotLine.values.lazy.map(\.x).min() ?? xMin)
			xMax = max(xMax, plotLine.values.lazy.map(\.x).max() ?? xMax)
			
			if plotLine.secondary && settings.showSecondaryAxis {
				sMin = min(sMin, plotLine.lazy.map(\.y).min() ?? sMin)
				sMax = max(sMax, plotLine.lazy.map(\.y).max() ?? sMax)
			} else {
				yMin = min(yMin, plotLine.lazy.map(\.y).min() ?? yMin)
				yMax = max(yMax, plotLine.lazy.map(\.y).max() ?? yMax)
				if !newData.settings.showSecondaryAxis { (sMin, sMax) = (yMin, yMax) }
			}
		}
		
		// Compute min/max for Bands
		for band in plotBands {
			xMin = min(xMin, band.upper.lazy.map(\.x).min() ?? xMin)
			xMax = max(xMax, band.upper.lazy.map(\.x).max() ?? xMax)
			
			let minY = min(band.upper.lazy.map(\.y).min() ?? .infinity, band.lower.lazy.map(\.y).min() ?? .infinity)
			let maxY = max(band.upper.lazy.map(\.y).max() ?? -.infinity, band.lower.lazy.map(\.y).max() ?? -.infinity)
			
			if band.secondary && settings.showSecondaryAxis {
				(sMin, sMax) = (min(sMin, minY), max(sMax, maxY))
			} else {
				(yMin, yMax) = (min(yMin, minY), max(yMax, maxY))
			}
		}
		
		if newData.hasPrimaryLines != newData.hasSecondaryLines {
			yMax = max(yMax, sMax); yMin = min(yMin, sMin)
		}
		
		var xTics = adjustAxis(&xMin, &xMax)
		var yTics = adjustAxis(&yMin, &yMax)
		var sTics = adjustAxis(&sMin, &sMax)
		
		// Sync secondary axis tics with primary
		if sTics.0 != 0 && !settings.independentTics {
			if yTics.0 != 0 {
				// Reusable logic to sync bounds by step
				let syncBounds = { (minVal: inout Double, maxVal: inout Double, step: Double, change: Int, checkExtra: Bool) in
					if minVal < 0 && maxVal > 0 && (!checkExtra || -minVal > maxVal) {
						minVal -= Double(change - change / 2) * step
						maxVal += Double(change / 2) * step
					} else {
						maxVal += Double(change) * step
					}
				}
				
				if sTics.0 > yTics.0 {
					if sTics.0 * 10 > yTics.0 * 15 {
						syncBounds(&sMin, &sMax, (sMax - sMin) / Double(sTics.0), yTics.0 * 2 - sTics.0, false)
						sTics = yTics
					} else {
						syncBounds(&yMin, &yMax, (yMax - yMin) / Double(yTics.0), sTics.0 - yTics.0, false)
						yTics = sTics
					}
				} else {
					if yTics.0 * 10 > sTics.0 * 15 {
						syncBounds(&yMin, &yMax, (yMax - yMin) / Double(yTics.0), sTics.0 * 2 - yTics.0, true)
						yTics = sTics
					} else {
						syncBounds(&sMin, &sMax, (sMax - sMin) / Double(sTics.0), yTics.0 - sTics.0, false)
						sTics = yTics
					}
				}
			} else {
				(yTics, yMax, yMin) = (sTics, sMax, sMin)
			}
		} else {
			if yTics.0 == 0 { yTics = (10, 5) }
			if sTics.0 == 0 { sTics = (10, 5) }
			if xTics.0 == 0 { xTics = (10, 5) }
		}
		
		newData.settings.xAxis = AxisParameters(min: xMin, max: xMax, majorTics: xTics.0, minorTics: xTics.1, title: settings.xAxis?.title ?? AttributedString())
		newData.settings.yAxis = AxisParameters(min: yMin, max: yMax, majorTics: yTics.0, minorTics: yTics.1, title: settings.yAxis?.title ?? AttributedString())
		newData.settings.sAxis = AxisParameters(min: sMin, max: sMax, majorTics: sTics.0, minorTics: sTics.1, title: settings.sAxis?.title ?? AttributedString())
		newData.settings.legendPos = self.settings.legendPos
		
		self = newData
	}
}
