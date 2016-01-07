//
//  FileCoverage.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/5/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import Foundation

extension String {

    func parseLLVMCovOutput(llvmCovArguments:LLVMCovArguments) -> PackageCoverage {
        let groupedOutput = NSString(string:self).componentsSeparatedByString("\n/") as [NSString]
        var files:[FileCoverage] = []
        for group in groupedOutput {
            var groupLines = group.componentsSeparatedByString("\n") as [NSString]
            let first = groupLines[0]
            var path = (first.substringToIndex(1) == ProfdataToCobertura.PathSeparator) ? first as String : ProfdataToCobertura.PathSeparator + (first as String)

            if let sourcePath = llvmCovArguments.sourcePath {
                if path.hasPrefix(sourcePath) {
                    path = path.substringWithRange(Range(start:sourcePath.endIndex, end:path.endIndex.predecessor()))

                    groupLines.removeAtIndex(0) // remove path
                    files.append(FileCoverage(path:path, lines:groupLines as! [String]))
                }
            }
        }

        return PackageCoverage(files:files)
    }

}

func ==(lhs: FileCoverage, rhs: FileCoverage) -> Bool {
    return (lhs.path == rhs.path) && (lhs.lines == rhs.lines)
}

func <(lhs: FileCoverage, rhs: FileCoverage) -> Bool {
    return (lhs.path < rhs.path)
}

class FileCoverage: Comparable {
    let path: String
    let pathComponents:[String]
    let filename:String?
    let lines: [String]

    var hits:Int { return _hits }

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

    private var _hits = 0

    private func processLines() {
        _hits = 0
        for line in lines {
            let pieces = line.componentsSeparatedByString("|")
            if pieces.count > 0 {
                let firstPiece = pieces[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                _hits += Int(firstPiece) ?? 0
            }
        }

    }

}
