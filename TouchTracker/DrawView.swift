//
//  DrawView.swift
//  TouchTracker
//
//  Created by Justin Weiss on 4/11/18.
//  Copyright © 2018 Justin Weiss. All rights reserved.
//

import UIKit

class DrawView: UIView {
    
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    
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
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self,
                                                         action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
    }
    
    func stroke(_ line: Line) {
        let path = UIBezierPath()
        //path.lineWidth = 10
        path.lineWidth = lineThickness
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    @objc func doubleTap (_ gestureRecognizer: UITapGestureRecognizer) {
        print("Recognized a double tap")
        
        currentLines.removeAll()
        finishedLines.removeAll()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        //Draw finished lines in black
        finishedLineColor.setStroke()
        for line in finishedLines {
            stroke(line)
        }
        
        currentLineColor.setStroke()
        for (_, line) in currentLines {
            stroke(line)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //Log statement to see the order of events
        print(#function)
        
        for touch in touches {
            //Get location of the touch in view's coordinate system
            let location = touch.location(in: self)
            
            let newLine = Line(begin: location, end: location)
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newLine
        }
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        //Log statement to see the order of events
        print(#function)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = touch.location(in: self)
        }
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        //Log statement to see the order of events
        print(#function)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLines[key] {
                line.end = touch.location(in: self)
                
                finishedLines.append(line)
                currentLines.removeValue(forKey: key)
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Log statement to see the order of events
        print(#function)
        
        currentLines.removeAll()
        
        setNeedsDisplay()
    }
    
}
