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
    let verbose:Bool
    let path: String
    let pathComponents:[String]
    let filename:String?

    var lines:[String] { return _lines }
    var rawLineCount:Int { return _lines.count }
    var activeLineCount:Int { return lineHits.count }
    var totalLineHitCount:Int { return _totalLineHitCount }
    var lineHits:[(Int,Int)] { return _lineHits }
    var lineRate:Float {
        return activeLineCount > 0 ? Float(totalLineHitCount) / Float(activeLineCount) : 0.0
    }
    var branchRate:Float { return 0.0 }
    var complexity:Float { return 0.0 }

    init(path:String, lines:[String], verbose:Bool) {
        self.verbose = verbose
        self.path = path
        _lines = lines
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

    func merge(other:ClassCoverage) -> Bool {
        if rawLineCount != other.rawLineCount {
            return false
        }
        for index in 0..<rawLineCount {
            let parsedLine = ParsedLine(_lines[index])
            let parsedOtherLine = ParsedLine(other.lines[index])

            let newHitCount = sum([parsedLine.hitCount,parsedOtherLine.hitCount])
            _lines[index] = parsedLine.lineWithHitCount(newHitCount)

        }
        processLines()
        return true
    }

    private func sum(values:[Int?]) -> Int? {
        var result:Int?
        for value in values {
            if let value = value {
                if result == nil {
                    result = value
                } else {
                    result! += value
                }
            }
        }
        return result
    }

    private var _totalLineHitCount = 0
    private var _lines:[String] = []
    private var _lineHits:[(Int,Int)] = []

    private func processLines() {
        var totalHits = 0
        _totalLineHitCount = 0
        _lineHits = []
        for lineIndex in 0..<_lines.count {
            let parsedLine = ParsedLine(_lines[lineIndex])
            if let hitCount = parsedLine.hitCount {
                totalHits += hitCount
                _totalLineHitCount += (hitCount > 0) ? 1 : 0
                _lineHits.append((lineIndex,hitCount))
            }
        }
        if verbose {
            print("Class: \(path)")
            let fn = filename ?? ""
            print("\tfilename=\(fn)")
            print("\tlines=\(lines.count), executable=\(_lineHits.count), hits=\(_totalLineHitCount), misses=\(_lineHits.count - _totalLineHitCount)")
            print("\ttotal hits=\(totalHits)")
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

private struct ParsedLine {
    static let HitColumnWidth = 7
    static let ColumnSeparator = "|"

    let hitCountColumn:String
    let hitCount:Int?
    let lineNumberColumn:String
    let lineNumber:Int
    let codeLine:String

    init(_ line:String) {
        var pieces = line.componentsSeparatedByString(ParsedLine.ColumnSeparator)
        hitCountColumn = (pieces.count > 0) ? pieces.removeFirst() : ""
        lineNumberColumn = (pieces.count > 0) ? pieces.removeFirst() : ""

        hitCount = Int(hitCountColumn.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        lineNumber = Int(lineNumberColumn.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())) ?? 0

        codeLine = (pieces.count > 0) ? pieces.joinWithSeparator(ParsedLine.ColumnSeparator) : ""
    }

    func lineWithHitCount(newHitCount:Int?) -> String {
        let newHitColumnStr = (newHitCount == nil) ? "" : "\(newHitCount!)"
        let newHitCountColumn = newHitColumnStr.stringByPaddingToLength(ParsedLine.HitColumnWidth, withString: " ", startingAtIndex: 0)
        return [newHitCountColumn,lineNumberColumn,codeLine].joinWithSeparator(ParsedLine.ColumnSeparator)
    }
}