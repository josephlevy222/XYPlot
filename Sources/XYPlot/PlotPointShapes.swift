//
//
//
//  PlotPointShapes.swift
//  XYPlot
//
//  Created by Joseph Levy on 12/20/21.
//

import SwiftUI
import Utilities

public struct Arrow : Shape {
    public var left = true
    public func path(in rect : CGRect) -> Path {
        var path = Path()
        let h = sin(atan(0.5))
        let startPoint = CGPoint(x: left ? 0 : rect.width, y: rect.height*0.5)
        path.move(to: startPoint)
        path.addLine(to: CGPoint(x: rect.width*0.5, y: rect.height*(0.5-h)))
        path.move(to: startPoint)
        path.addLine(to: CGPoint(x: rect.width*0.5, y: rect.height*(0.5+h)))
        path.move(to: startPoint)
        path.addLine(to: CGPoint(x: left ? rect.width : 0, y: rect.height*0.5))
        return path
    }
}

public struct Polygon : Shape {
    public init(sides: Int = 5, openShape: Bool = false, cornerStart: Bool = false) {
        self.sides = sides
        self.openShape = openShape
        self.cornerStart = cornerStart
    }
    
    /// Modified from a version found on to have openShape ( plus, X, asterix)
    /// https://blog.techchee.com/how-to-create-custom-shapes-in-swiftui/
    /// also see that site for stars which are not implemented
    public var sides : Int = 5
    public var openShape : Bool = false
    public var cornerStart : Bool = false
    public func path(in rect : CGRect ) -> Path {
        // get the center point and the radius
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = (cornerStart ? sqrt(rect.width * rect.width + rect.height * rect.height) : rect.width) / 2
        
        // get the angle in radian,
        // 2*pi divided by the number of sides
        let angle = Double.pi * 2 / Double(sides)
        let offset = cornerStart ?  Double.pi/4.0 : 0.0
        var path = Path()
        var startPoint = CGPoint(x: 0, y: 0)
        
        for side in 0 ..< sides {
            
            let x = center.x + CGFloat(cos(Double(side) * angle + offset)) * CGFloat (radius)
            let y = center.y + CGFloat(sin(Double(side) * angle + offset)) * CGFloat(radius)
            let vertexPoint = CGPoint( x: x, y: y)
            
            if !openShape {
                if (side == 0) {
                    startPoint = vertexPoint
                    path.move(to: startPoint )
                }
                else {
                    path.addLine(to: vertexPoint)
                }
                // move back to starting point to close path
                if ( side == (sides - 1) ){
                    path.closeSubpath()
                }
            } else {
                path.move(to: center)
                path.addLine(to: vertexPoint)
            }
        }
        return path
    }
}

fileprivate let unitRect = CGRect(origin: .zero , size: .init(width: 1, height: 1))

public struct PointShape : InsettableShape, Equatable, Codable {
	
    public func inset(by amount: CGFloat) -> PointShape {
        var shape = self
        shape.insetAmount -= amount
        return shape
    }
	
	public func equalPathandAngle(_ rhs: PointShape) -> Bool {
		angle == rhs.angle && path(in: unitRect).description == rhs.path(in: unitRect).description
	}
    static public func == (lhs: PointShape, rhs: PointShape) -> Bool {
        lhs.fill == rhs.fill &&  rhs.color == lhs.color && lhs.size == rhs.size
		&& lhs.equalPathandAngle(rhs) // equal paths for equal CGRects
    }
	
    public typealias InsetShape = PointShape

	public var color = Color.black
	public var fill = false
	public var angle = Angle(radians: 0.0)
    public var insetAmount: CGFloat = 0
	public var size: CGFloat
	public var shapePath : Path = Rectangle().path(in: unitRect) // save unitRect Path
	
	public init(_ shape: @escaping (CGRect) -> Path = Polygon(sides: 4).path, angle: Angle = .radians(0.0),
				fill: Bool = false, color: Color = .black, size: CGFloat  = 1.0)  {
		shapePath = shape(unitRect)
		self.angle = angle
		self.fill = fill
		self.color = color
		self.size = size
	}
	
	public func path(in rect: CGRect) -> Path {
		shapePath.path(in: unitRect)
		         .applying(CGAffineTransform(scaleX: rect.width, y: rect.height)) }

	enum CodingKeys: CodingKey { case color, fill, angle, insetAmount, shapePath, size }
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let shape =  try values.decode(String.self, forKey: .shapePath)
		shapePath =  Path(shape) ?? Polygon(sides: 4, openShape: false, cornerStart: false).path(in: unitRect)
		insetAmount = try values.decode(CGFloat.self, forKey: .insetAmount)
		color = Color(sARGB: try values.decode(Int.self, forKey: .color))
		fill = try values.decode(Bool.self, forKey: .fill)
		angle = Angle(radians: try values.decode(CGFloat.self, forKey: .angle))
		size = try values.decode(CGFloat.self, forKey: .size)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		do {
			try container.encode(shapePath.description, forKey: .shapePath)
			try container.encode(insetAmount, forKey: .insetAmount)
			try container.encode(color.sARGB, forKey: .color)
			try container.encode(fill, forKey: .fill)
			try container.encode(angle.radians, forKey: .angle)
			try container.encode(size, forKey: .size)
		} catch (let error) { print(error.localizedDescription)}
	}
}

public struct PointShapeView : View {
	public init(shape: PointShape){ self.shape = shape }
	public init(_ shape: PointShape) { self.shape = shape }
	public var shape : PointShape
	private var size : CGSize { CGSize(width: shape.size, height: shape.size)}
	private var angle: Angle { shape.angle }
    public var body: some View {
        ZStack {
			shape.fill(shape.fill ? shape.color : Color.clear)
			shape.strokeBorder(lineWidth: 2.0/shape.size).foregroundColor(shape.color)
		}.rotated(angle).scaleEffect(size)// anchor is center
    }
}

public var pointSymbols : [PointShapeView] = [ // Some ShapeView samples
	PointShapeView(.init(Rectangle().path, color: .clear)), // None
    PointShapeView(PointShape()), // Default Black Diamond
	PointShapeView(.init(Polygon(sides: 4).scale(x: 0.7, y: 1.0).path, color: .red)), // Narrowed Red Diamond
	PointShapeView(.init(Rectangle().path, color: .red, size: 0.7)), // Square sized to Polygon Diamond
	PointShapeView(.init(Rectangle().scale(0.707).path, color: .red)),// Square sized to Polygon Diamond again
	PointShapeView(.init(Circle().path, color: .blue)),   // Circle
    PointShapeView(.init(Rectangle().scale(0.707).path, angle: .degrees(45.0), color: .green)), // Diamond from Square
    PointShapeView(.init(Polygon(sides: 3).path, angle: .degrees(90.0), color: .purple)), // Triangle
    PointShapeView(.init(Polygon(sides: 3).path, angle: .degrees(-90.0), color: .orange)), // Inverted Triangle
    PointShapeView(.init(Rectangle().scale(0.707).path, fill: false, color: .red)), // Square
	PointShapeView(.init(Rectangle().path, fill: false, color: .red, size: 0.707)), // Square
    PointShapeView(.init(Circle().path, fill: true, color: .blue)),   // Circle
    PointShapeView(.init(Polygon(sides: 13).path, fill: false,color: .blue)),//Almost Circle from Polygon
    PointShapeView(.init(Polygon(sides: 4).path, angle: .degrees(0.0), fill: false,color: .green)),  // Open Diamond
    PointShapeView(.init(Polygon(sides: 3).path, angle: .degrees(90.0), fill: false,color: .purple)), //Open Triangle
    PointShapeView(.init(Polygon(sides: 3).path, angle: .degrees(-90.0), fill: false,color: .orange)), //Inverted Triangle
    PointShapeView(.init(Polygon(sides: 4, openShape: true).path, fill: false, color: .black)), // Plus
    PointShapeView(.init(Polygon(sides: 4, openShape: true).path, angle: .degrees(45.0),fill: false)), // X
    PointShapeView(.init(Polygon(sides: 6, openShape: true).path, fill: false, color: .black)), // Asterix
    PointShapeView(.init(Arrow().path)),
    PointShapeView(.init(Arrow(left: false).path))
]
#if DEBUG

struct PlotShapesView_Previews: PreviewProvider {
    static var previews: some View {
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
        let pentagonString = Polygon(sides: 5, openShape: false).path(in: unitRect).description
        VStack {
            VStack {
                Text(Rectangle().path(in: unit).description+"\n")
                Text(Ellipse().path(in: unit).description+"\n")
                Text(pentagonString)
				PointShapeView(.init(Path(pentagonString)?.path ?? Rectangle().path))
				Text(pointSymbols[3].shape.path(in: unitRect).description)
            }.offset(y: -CGFloat(pointSymbols.count)*10.0)
            HStack {
                ForEach(pointSymbols.indices, id: \.self){ i in
                    pointSymbols[i].offset(y: CGFloat((2*i-pointSymbols.count)*10))
                }
            }
        }
    }
}
#endif
