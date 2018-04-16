//
//  DrawView.swift
//  TouchTracker
//
//  Created by Justin Weiss on 4/11/18.
//  Copyright © 2018 Justin Weiss. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate {
    
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    var selectedLineIndex: Int? {
        didSet {
            if selectedLineIndex == nil {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    var moveRecognizer: UIPanGestureRecognizer!
    var longPressRecognizer: UILongPressGestureRecognizer!
    
    var currentCircle: Circle?
    var finishedCircles = [Circle]()
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var currentLineColor: UIColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var lineThickness: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        //let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecognizer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
    }
    
    func stroke(_ line: Line) {
        let path = UIBezierPath()
        path.lineWidth = line.thickness ?? lineThickness
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    func strokeCircle(_ circle: Circle) {
        let path = UIBezierPath(arcCenter: circle.center, radius: circle.radius, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
        path.lineWidth = 10
        path.stroke()
    }
    
    func indexOfLine(at point: CGPoint) -> Int? {
        //Find a line close to  point
        for (index, line) in finishedLines.enumerated() {
            let begin = line.begin
            let end = line.end
            
            //Check a few points on the line
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                //If the tapped point is within 20 points, lets return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        
        //If nothing is close enought to the tapped point, then we did not select a line
        return nil
    }
    
    @objc func deleteLine(_ sender: UIMenuController) {
        //Remove the selected line from the list of finshedLines
        if let index = selectedLineIndex {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            
            //Redraw everything
            setNeedsDisplay()
        }
    }
    
    @objc func doubleTap (_ gestureRecognizer: UITapGestureRecognizer) {
        print("Recognized a double tap")
        
        selectedLineIndex = nil
        currentLines.removeAll()
        finishedLines.removeAll()
        setNeedsDisplay()
    }
    
    @objc func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        print("Recognized a tap")
        
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        
        //Grab the menu controller
        let menu = UIMenuController.shared
        
        if selectedLineIndex != nil {
            
            //Make DrawView the target of menu item action messages
            becomeFirstResponder()
            
            //Create a new "Delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(DrawView.deleteLine(_:)))
            menu.menuItems = [deleteItem]
            
            //Tell the menu where it should come from and show it
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        } else {
            //Hide the menu if no line is selected
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    @objc func longPress(_ gestureRecognizer: UIGestureRecognizer) {
        print("Recognized a long press")
        
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll()
            }
        } else if gestureRecognizer.state == .ended {
            selectedLineIndex = nil
        }
        setNeedsDisplay()
    }
    
    @objc func moveLine(_ gestureRecognizer: UIPanGestureRecognizer) {
        print("Recognized a pan")
        
        //guard longPressRecognizer.state == .changed || longPressRecognizer.state == .ended //else {
          //  return
        //}
        if let index = selectedLineIndex, index != indexOfLine(at: gestureRecognizer.location(in: self)) {
            if gestureRecognizer.state == .began {
                selectedLineIndex = nil
            }
        }
        
        //If line is selected...
        if let index = selectedLineIndex {
            // When the pan recognizer changes its position...
            if gestureRecognizer.state == .changed {
                // How far has the pan moved?
                let translation = gestureRecognizer.translation(in: self)
                
                // Add the translation to the current beginning and end points of the line
                // Make sure there are no copy and paste typos!
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                
                // Redraw the screen
                setNeedsDisplay()
            }
        } else {
            // If no line is selected, do not do anything
            let velocity = gestureRecognizer.velocity(in: self)
            let speed = hypot(abs(velocity.x), abs(velocity.y))
            lineThickness = sqrt(speed)
            return
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func draw(_ rect: CGRect) {
        //Draw finished lines in black
        for line in finishedLines {
            line.color?.setStroke()
            stroke(line)
        }
        
        finishedLineColor.setStroke()
        for circle in finishedCircles {
            strokeCircle(circle)
        }
        
        currentLineColor.setStroke()
        for (_, line) in currentLines {
            stroke(line)
        }
        
        if let index = selectedLineIndex {
            UIColor.green.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
        
        if let circle = currentCircle {
            strokeCircle(circle)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //Log statement to see the order of events
        print(#function)
        
        if touches.count == 2 {
            let touchesArray = Array(touches)
            let begin = touchesArray[0].location(in: self)
            let end = touchesArray[1].location(in: self)
            
            let center = CGPoint(x: (begin.x + end.x) / 2, y: (begin.y + end.y) / 2)
            let radius = hypot(abs(begin.x - end.x), abs(begin.y - end.y))
            
            let newCircle = Circle(center: center, radius: radius)
            currentCircle = newCircle
        } else {
            for touch in touches {
                let location = touch.location(in: self)
                let newLine = Line(begin: location, end: location, thickness: nil, color: nil)
                let key = NSValue(nonretainedObject: touch)
                
                currentLines[key] = newLine
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        //Log statement to see the order of events
        print(#function)
        
        if touches.count == 2 {
            let touchesArray = Array(touches)
            let begin = touchesArray[0].location(in: self)
            let end = touchesArray[1].location(in: self)
            
            let radius = hypot(abs(begin.x - end.x), abs(begin.y - end.y))
            
            currentCircle?.radius = radius
        } else {
            for touch in touches {
                let key = NSValue(nonretainedObject: touch)
                currentLines[key]?.end = touch.location(in: self)
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        //Log statement to see the order of events
        print(#function)
        
        if touches.count == 2 {
            if var circle = currentCircle {
                let touchesArray = Array(touches)
                let begin = touchesArray[0].location(in: self)
                let end = touchesArray[1].location(in: self)
                
                let radius = hypot(abs(begin.x - end.x), abs(begin.y - end.y))
                circle.radius = radius
                
                finishedCircles.append(circle)
                currentCircle = nil
            }
        } else {
            for touch in touches {
                let key = NSValue(nonretainedObject: touch)
                if var line = currentLines[key] {
                    line.end = touch.location(in: self)
                    line.thickness = lineThickness
                    
                    let radians = atan2(abs(line.end.y - line.begin.y),
                                            abs(line.end.x - line.begin.x))
                    let degrees = radians * 180 / CGFloat(Double.pi)
                     
                    line.color = UIColor(red: degrees / 45,
                                             green: degrees / 90,
                                             blue: 1 - degrees / 135,
                                             alpha: 1.0)
                    
                    finishedLines.append(line)
                    currentLines.removeValue(forKey: key)
                }
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Log statement to see the order of events
        print(#function)
        
        currentLines.removeAll()
        currentCircle = nil
        
        setNeedsDisplay()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
}
