//
//  ClassCoverage.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/5/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import Foundation

func ==(lhs: ClassCoverage, rhs: ClassCoverage) -> Bool {
    return (lhs.path == rhs.path)
}

func <(lhs: ClassCoverage, rhs: ClassCoverage) -> Bool {
    return (lhs.path < rhs.path)
}

class ClassCoverage: Comparable {
    let path: String
    let pathComponents:[String]
    let filename:String?
    let lines: [String]

    var lineCount:Int { return lines.count }
    var totalLineHitCount:Int { return _totalLineHitCount }
    var lineHits:[(Int,Int)] { return _lineHits }
    var lineRate:Float {
        return lineCount > 0 ? Float(totalLineHitCount) / Float(lineCount) : 0.0
    }
    var branchRate:Float { return 0.0 }
    var complexity:Float { return 0.0 }

    init(path:String, lines:[String]) {
        self.path = path
        self.lines = lines
        var pathComponents = path.componentsSeparatedByString(ProfdataToCobertura.PathSeparator)
        if pathComponents.first == "" {
            pathComponents.removeFirst()
        }

        if pathComponents.isEmpty {
            self.filename = nil
        } else {
            self.filename = pathComponents.removeLast()
        }
        self.pathComponents = pathComponents
        processLines()
    }

    private var _totalLineHitCount = 0
    private var _lineHits:[(Int,Int)] = []

    private func processLines() {
        _totalLineHitCount = 0
        _lineHits = []
        for lineIndex in 0..<lines.count {
            let line = lines[lineIndex]
            let pieces = line.componentsSeparatedByString("|")
            let firstPiece = pieces[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            if let hit = Int(firstPiece) {
                _totalLineHitCount += (hit > 0) ? 1 : 0
                _lineHits.append((lineIndex,hit))
            }
        }
    }

    func appendXML(classesElement:NSXMLElement) {

// <class branch-rate="0.136363636364" complexity="0.0" filename="/Users/Shared/Jenkins/Home/jobs/ASDA/workspace/asda/main.m" line-rate="0.307692307692" name="main_m">

        let classElement = classesElement.addChildElementWithName("class")
        classElement.addAttributeWithName("branch-rate", value: "\(branchRate)")
        classElement.addAttributeWithName("complexity", value: "\(complexity)")
        classElement.addAttributeWithName("line-rate", value: "\(self.lineRate)")
        classElement.addAttributeWithName("filename", value: path)
        if let filename = filename {
            classElement.addAttributeWithName("name", value: filename)
        }

        let linesElement = classElement.addChildElementWithName("lines")
        for (lineIndex,lineHit) in lineHits {
            let lineElement = linesElement.addChildElementWithName("line")
            lineElement.addAttributeWithName("branch", value:"false")
            lineElement.addAttributeWithName("hits", value:"\(lineHit)")
            lineElement.addAttributeWithName("number", value:"\(lineIndex+1)")
        }
    }

}
