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
    func path(in rect : CGRect) -> Path {
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
        // 2 pi divided by the number of sides
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

public struct ShapeParameters : Equatable {
    
    static public func == (lhs: ShapeParameters, rhs: ShapeParameters) -> Bool {
        lhs.angle == rhs.angle && lhs.filled == rhs.filled &&  rhs.color == lhs.color //rhs.open == lhs.open &&
        && lhs.shape(CGRect(x: 0, y: 0, width: 10, height: 10)) == rhs.shape(CGRect(x: 0, y: 0, width: 10, height: 10)) && lhs.size == rhs.size // equal paths for equal CGRects
    }
    
    public var shape: (CGRect) -> Path = Polygon(sides: 4).path
    public var angle : Angle = .degrees(0.0)
    public var filled: Bool  = false
    public var color: Color = .black
    public var size: CGFloat = 1.0
}

public struct CustomShape : InsettableShape {
    public func inset(by amount: CGFloat) -> CustomShape {
        var shape = self
        shape.insetAmount -= amount
        return shape
    }
    
    public typealias InsetShape = CustomShape
    
    public var insetAmount: CGFloat = 0
     
    public init(_ shape: @escaping (_ in: CGRect) -> Path) { shapePath = shape }
    public var shapePath = Rectangle().path
    public func path(in rect: CGRect) -> Path { shapePath(rect) }
}

public struct ShapeView : View {
    public var scale: CGFloat {shape.size}
    public var shape = ShapeParameters()
    public var body: some View {
        ZStack {
            CustomShape(shape.shape).fill(shape.filled ? shape.color : Color.clear)
                .rotated(shape.angle).scaleEffect(CGSize(width: scale, height: scale))// anchor is center
            CustomShape(shape.shape).strokeBorder(lineWidth: 2.0/scale).foregroundColor(shape.color)
                .rotated(shape.angle).scaleEffect(CGSize(width: scale, height: scale))
                // scaleEffect scales the line width too, made strokeBorder(lineWidth: 2/scale to avoid
        }
    }
}

public var pointSymbols : [ShapeView] = [ // Some ShapeView samples
    ShapeView(shape: .init(color: .clear)), // None
    ShapeView(shape: ShapeParameters()), // Default Black Diamond
    ShapeView(shape: .init(shape: Polygon(sides: 4).scale(x: 0.7, y: 1.0).path, color: .red)), // Narrowed Red Diamond
    ShapeView(shape: .init(shape: Rectangle().scale(0.707).path, color: .red)), // Square sized to Polygon Diamond
    ShapeView(shape: .init(shape: Rectangle().path, color: .red, size: 0.707)), // Square sized to Polygon Diamond again
    ShapeView(shape: .init(shape: Circle().path, color: .blue)),   // Circle
    ShapeView(shape: .init(shape: Rectangle().scale(0.707).path, angle: .degrees(45.0), color: .green)), // Diamond from Square
    ShapeView(shape: .init(shape: Polygon(sides: 3).path, angle: .degrees(90.0), color: .purple)), // Triangle
    ShapeView(shape: .init(shape: Polygon(sides: 3).path, angle: .degrees(-90.0), color: .orange)), // Inverted Triangle
    ShapeView(shape: .init(shape: Rectangle().scale(0.707).path, filled: false, color: .red)), // Square
    ShapeView(shape: .init(shape: Rectangle().path, filled: false, color: .red, size: 0.707)), // Square
    ShapeView(shape: .init(shape: Circle().path, filled: false, color: .blue)),   // Circle
    ShapeView(shape: .init(shape: Polygon(sides: 13).path, filled: false,color: .blue, size: 2.0)),  // Almost Circle from Polygon
    ShapeView(shape: .init(shape: Polygon(sides: 4).path, angle: .degrees(0.0), filled: false,color: .green)),  // Open Diamond
    ShapeView(shape: .init(shape: Polygon(sides: 3).path, angle:  .degrees(90.0), filled: false,color: .purple)),// Open Triangle
    ShapeView(shape: .init(shape: Polygon(sides: 3).path, angle: .degrees(-90.0), filled: false,color: .orange)),// Inverted Triangle
    ShapeView(shape: .init(shape: Polygon(sides: 4, openShape: true).path, filled: false, color: .black)), // Plus
    ShapeView(shape: .init(shape: Polygon(sides: 4, openShape: true).path, angle: .degrees(45.0), filled: false, color: .black)),  // X
    ShapeView(shape: .init(shape: Polygon(sides: 6, openShape: true).path, filled: false, color: .black)), // Asterix
    ShapeView(shape: .init(shape: Arrow().path)),
    ShapeView(shape: .init(shape: Arrow(left: false).path))
]


struct PlotShapesView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ForEach(pointSymbols.indices, id: \.self){ i in
                pointSymbols[i].offset(y: CGFloat((2*i-pointSymbols.count)*10))
            }
        }
    }
}



