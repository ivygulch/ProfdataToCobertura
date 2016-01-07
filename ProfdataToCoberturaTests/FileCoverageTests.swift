//
//  FileCoverageTests.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/6/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import XCTest
@testable import ProfdataToCobertura

class FileCoverageTests: XCTestCase {

    func testMultipleRelativePathComponent() {
        let fileCoverage = FileCoverage(path:"a/b/c", lines:[])
        XCTAssertEqual(["a","b"], fileCoverage.pathComponents)
        XCTAssertEqual("c", fileCoverage.filename)
    }

    func testMultipleFullPathComponent() {
        let fileCoverage = FileCoverage(path:"/a/b/c", lines:[])
        XCTAssertEqual(["a","b"], fileCoverage.pathComponents)
        XCTAssertEqual("c", fileCoverage.filename)
    }

    func testSingleRelativePathComponent() {
        let fileCoverage = FileCoverage(path:"a", lines:[])
        XCTAssertEqual([], fileCoverage.pathComponents)
        XCTAssertEqual("a", fileCoverage.filename)
    }

    func testSingleFullPathComponent() {
        let fileCoverage = FileCoverage(path:"/a", lines:[])
        XCTAssertEqual([], fileCoverage.pathComponents)
        XCTAssertEqual("a", fileCoverage.filename)
    }

    func testEmptyPathComponent() {
        let fileCoverage = FileCoverage(path:"", lines:[])
        XCTAssertEqual([], fileCoverage.pathComponents)
        XCTAssertNil(fileCoverage.filename)
    }

    func testSort() {
        let fc_a = FileCoverage(path:"/a", lines:[])
        let fc_a_b = FileCoverage(path:"/a/b", lines:[])
        let fc_a_b_c = FileCoverage(path:"/a/b/c", lines:[])
        let fc_d = FileCoverage(path:"/d", lines:[])
        let fc_d_e_f = FileCoverage(path:"/d/e/f", lines:[])
        let fileCoverages = [
            fc_d,
            fc_a_b,
            fc_a,
            fc_d_e_f,
            fc_a_b_c
        ]
        let sorted = fileCoverages.sort()
        XCTAssertEqual([fc_a,fc_a_b,fc_a_b_c,fc_d,fc_d_e_f], sorted)
    }

}
