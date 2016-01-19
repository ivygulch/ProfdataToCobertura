//
//  SummaryCoverage.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/5/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import Foundation

extension String {

    func parseLLVMCovOutput(llvmCovArguments:LLVMCovArguments) -> SummaryCoverage {
        let groupedOutput = NSString(string:self).componentsSeparatedByString("\n/") as [NSString]
        if llvmCovArguments.verbose {
            print("Processing \(groupedOutput.count) separate files")
        }
        var classes:[ClassCoverage] = []
        for group in groupedOutput {
            var groupLines = group.componentsSeparatedByString("\n") as [NSString]
            let first = groupLines[0]
            var path = (first.substringToIndex(1) == ProfdataToCobertura.PathSeparator) ? first as String : ProfdataToCobertura.PathSeparator + (first as String)
            if llvmCovArguments.verbose {
                print("Checking \(path)")
            }

            if let sourcePath = llvmCovArguments.sourcePath {
                if path.hasPrefix(sourcePath) {
                    if llvmCovArguments.verbose {
                        print("Processing \(path)")
                    }
                    var startIndex = path.startIndex
                    startIndex = startIndex.advancedBy(sourcePath.startIndex.distanceTo(sourcePath.endIndex)+1)
                    path = path.substringWithRange(Range(start:startIndex, end:path.endIndex.predecessor()))

                    groupLines.removeAtIndex(0) // remove path
                    classes.append(ClassCoverage(path:path, lines:groupLines as! [String], verbose:llvmCovArguments.verbose))
                }
            }
        }

        return SummaryCoverage(classes:classes)
    }
    
}

class SummaryCoverage {
    var packages:[PackageCoverage] = []

    var activeLineCount:Int {
        return packages.reduce(0) {$0 + $1.activeLineCount}
    }
    var totalLineHitCount:Int {
        return packages.reduce(0) {$0 + $1.totalLineHitCount}
    }
    var lineRate:Float {
        return activeLineCount > 0 ? Float(totalLineHitCount) / Float(activeLineCount) : 0.0
    }
    var branchRate:Float { return 0.0 }

    init(classes:[ClassCoverage]) {
        self.packages = PackageCoverage.toFlatPackages(classes)
    }

    func saveXML(args:LLVMCovArguments) {

// <coverage branch-rate="0.0342968677386" line-rate="0.0632624768946" timestamp="1444756676" version="gcovr 3.3-prerelease">

        let root = NSXMLElement(name: "coverage")
        root.addAttributeWithName("branch-rate", value: "\(branchRate)")
        root.addAttributeWithName("line-rate", value: "\(lineRate)")
        root.addAttributeWithName("timestamp", value: "\(NSDate.timeIntervalSinceReferenceDate())")
        root.addAttributeWithName("version", value: "ProfdataToCobertura-0.1-prerelease")

        let xml = NSXMLDocument(rootElement: root)
        xml.version = "1.0"
        let dtd = NSXMLDTD()
        dtd.name = "coverage"
        dtd.systemID = "http://cobertura.sourceforge.net/xml/coverage-03.dtd"
        xml.DTD = dtd

        if let sourcePath = args.sourcePath {
            let sourcesNode = root.addChildElementWithName("sources")
            sourcesNode.addChildElementWithName("source", value: sourcePath)
        }

        let packagesElement = root.addChildElementWithName("packages")
        for package in packages {
            package.appendXML(packagesElement)
        }

        let outputPath = args.outputPath ?? ProfdataToCobertura.DefaultOutputPath
        if let xmlData = xml.XMLStringWithOptions(NSXMLNodePrettyPrint).dataUsingEncoding(NSUTF8StringEncoding) {
            xmlData.writeToFile(outputPath, atomically: true)
            print("written to \(outputPath)")
        } else {
            print("could not write to \(outputPath)")
        }
    }

}
