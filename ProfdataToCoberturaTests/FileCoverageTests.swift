//
//  ClassCoverageTests.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/6/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import XCTest
@testable import ProfdataToCobertura

class ClassCoverageTests: XCTestCase {

    func testMultipleRelativePathComponent() {
        let classCoverage = ClassCoverage(path:"a/b/c", lines:[], verbose: false)
        XCTAssertEqual("a/b/c", classCoverage.path)
        XCTAssertEqual(["a","b"], classCoverage.pathComponents)
        XCTAssertEqual("c", classCoverage.filename)
    }

    func testMultipleFullPathComponent() {
        let classCoverage = ClassCoverage(path:"/a/b/c", lines:[], verbose: false)
        XCTAssertEqual("/a/b/c", classCoverage.path)
        XCTAssertEqual(["a","b"], classCoverage.pathComponents)
        XCTAssertEqual("c", classCoverage.filename)
    }

    func testSingleRelativePathComponent() {
        let classCoverage = ClassCoverage(path:"a", lines:[], verbose: false)
        XCTAssertEqual("a", classCoverage.path)
        XCTAssertEqual([], classCoverage.pathComponents)
        XCTAssertEqual("a", classCoverage.filename)
    }

    func testSingleFullPathComponent() {
        let classCoverage = ClassCoverage(path:"/a", lines:[], verbose: false)
        XCTAssertEqual("/a", classCoverage.path)
        XCTAssertEqual([], classCoverage.pathComponents)
        XCTAssertEqual("a", classCoverage.filename)
    }

    func testEmptyPathComponent() {
        let classCoverage = ClassCoverage(path:"", lines:[], verbose: false)
        XCTAssertEqual([], classCoverage.pathComponents)
        XCTAssertNil(classCoverage.filename)
    }

    func testSort() {
        let cc_a = ClassCoverage(path:"/a", lines:[], verbose: false)
        let cc_a_b = ClassCoverage(path:"/a/b", lines:[], verbose: false)
        let cc_a_b_c = ClassCoverage(path:"/a/b/c", lines:[], verbose: false)
        let cc_d = ClassCoverage(path:"/d", lines:[], verbose: false)
        let cc_d_e_f = ClassCoverage(path:"/d/e/f", lines:[], verbose: false)
        let classCoverages = [
            cc_d,
            cc_a_b,
            cc_a,
            cc_d_e_f,
            cc_a_b_c
        ]
        let sorted = classCoverages.sort()
        XCTAssertEqual([cc_a,cc_a_b,cc_a_b_c,cc_d,cc_d_e_f], sorted)
    }

    func testLineHits() {
        let lines = [
            "       |    1|line 1 neutral",
            "       |    2|line 2 neutral",
            "      1|    3|line 3 covered 1",
            "      2|    4|line 4 covered 2",
            "       |    5|line 5 neutral",
            "      0|    6|line 6 not covered",
            "       |    7|line 7 neutral",
            "      3|    8|line 8 covered 3",
            "      0|    9|line 9 not covered"
        ]
        let cc = ClassCoverage(path:"/a", lines:lines, verbose: false)
        let expectedHits = [(2,1),(3,2),(5,0),(7,3),(8,0)]

        XCTAssertEqual(5, cc.lineHits.count)
        XCTAssertEqual(cc.activeLineCount, cc.lineHits.count)
        XCTAssertEqual(3, cc.totalLineHitCount)
        XCTAssertEqual(0.6, cc.lineRate)

        for index in 0..<expectedHits.count {
            let (expectedHitLine,expectedHitCount) = expectedHits[index]
            let (actualHitLine,actualHitCount) = cc.lineHits[index]
            XCTAssertEqual(expectedHitLine,actualHitLine)
            XCTAssertEqual(expectedHitCount,actualHitCount)
        }
    }

}
