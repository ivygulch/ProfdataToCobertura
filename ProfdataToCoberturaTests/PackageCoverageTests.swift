//
//  PackageCoverageTests.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/6/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import XCTest
@testable import ProfdataToCobertura

class PackageCoverageTests: XCTestCase {

    func testSimplePackage() {
        let packageCoverage = PackageCoverage(pathComponents:[], classes: [])
        XCTAssertEqual([], packageCoverage.pathComponents)
        XCTAssertEqual([], packageCoverage.classes)
        XCTAssertEqual("", packageCoverage.path)
    }

    func testSimpleGroup() {
        let ccA = ClassCoverage(path: "Filename.A", lines: [], verbose: false)
        let ccB = ClassCoverage(path: "Filename.B", lines: [], verbose: false)
        let ccC = ClassCoverage(path: "Filename.C", lines: [], verbose: false)
        let classCoverages = [ccA, ccB, ccC]
        let rootPackage = PackageCoverage(pathComponents: [], classes: classCoverages)

        XCTAssertEqual("", rootPackage.path)
        XCTAssertEqual([], rootPackage.pathComponents)
        XCTAssertEqual([], rootPackage.packages)
        XCTAssertEqual([ccA,ccB,ccC], rootPackage.classes)
    }

    func testSimpleResultsRolledUpCounts() {
        let linesA = [
            "       |    1|line 1 neutral",
            "      0|    2|line 2 not covered",
            "      1|    3|line 3 covered 1",
            "      2|    4|line 4 covered 2"
        ]
        let ccA = ClassCoverage(path:"/a", lines:linesA, verbose: false)
        let linesB = [
            "       |    1|line 1 neutral",
            "      0|    2|line 2 not covered",
            "      1|    3|line 3 covered 1",
            "      0|    4|line 4 not covered"
        ]
        let ccB = ClassCoverage(path:"/b", lines:linesB, verbose: false)

        let package = PackageCoverage(pathComponents: [], classes: [ccA,ccB])
        XCTAssertEqual(2,package.classes.count)
        XCTAssertEqual(ccA.activeLineCount+ccB.activeLineCount, package.activeLineCount)
        XCTAssertEqual(3, package.totalLineHitCount)
        XCTAssertEqual(0.5, package.lineRate)
    }

    func testMergedResultsRolledUpCounts() {
        let linesA1 = [
            "       |    1|line 1 neutral",
            "      0|    2|line 2 not covered",
            "      1|    3|line 3 covered 1"
        ]
        let ccA1 = ClassCoverage(path:"/a", lines:linesA1, verbose: false)
        let linesA2 = [
            "       |    1|line 1 neutral",
            "      1|    2|line 2 not covered",
            "      1|    3|line 3 covered 1"
        ]
        let ccA2 = ClassCoverage(path:"/a", lines:linesA2, verbose: false)
        let linesB = [
            "       |    1|line 1 neutral",
            "      0|    2|line 2 not covered",
            "      1|    3|line 3 covered 1"
        ]
        let ccB = ClassCoverage(path:"/b", lines:linesB, verbose: false)

        let package = PackageCoverage(pathComponents: [], classes: [ccA1,ccB,ccA2])
        XCTAssertEqual(2,package.classes.count)
        XCTAssertEqual(ccA1.activeLineCount+ccB.activeLineCount, package.activeLineCount)
        XCTAssertEqual(3, package.totalLineHitCount)
        XCTAssertEqual(0.75, package.lineRate)
    }
    
}
