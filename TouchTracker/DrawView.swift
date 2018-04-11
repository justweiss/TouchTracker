//
//  DrawView.swift
//  TouchTracker
//
//  Created by Justin Weiss on 4/11/18.
//  Copyright © 2018 Justin Weiss. All rights reserved.
//

import UIKit

class DrawView: UIView {
    
    var currentLine: Line?
    var finishedLines = [Line]()
    
    func stroke(_ line: Line) {
        let path = UIBezierPath()
        path.lineWidth = 10
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        //Draw finished lines in black
        UIColor.black.setStroke()
        for line in finishedLines {
            stroke(line)
        }
        
        if let line = currentLine {
            //If there is a line currently being drawn, do it in red
            UIColor.red.setStroke()
            stroke(line)
        }
    }
    
}
