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
        let classCoverage = ClassCoverage(path:"a/b/c", lines:[], verbose:false)
        XCTAssertEqual("a/b/c", classCoverage.path)
        XCTAssertEqual(["a","b"], classCoverage.pathComponents)
        XCTAssertEqual("c", classCoverage.filename)
    }

    func testMultipleFullPathComponent() {
        let classCoverage = ClassCoverage(path:"/a/b/c", lines:[], verbose:false)
        XCTAssertEqual("/a/b/c", classCoverage.path)
        XCTAssertEqual(["a","b"], classCoverage.pathComponents)
        XCTAssertEqual("c", classCoverage.filename)
    }

    func testSingleRelativePathComponent() {
        let classCoverage = ClassCoverage(path:"a", lines:[], verbose:false)
        XCTAssertEqual("a", classCoverage.path)
        XCTAssertEqual([], classCoverage.pathComponents)
        XCTAssertEqual("a", classCoverage.filename)
    }

    func testSingleFullPathComponent() {
        let classCoverage = ClassCoverage(path:"/a", lines:[], verbose:false)
        XCTAssertEqual("/a", classCoverage.path)
        XCTAssertEqual([], classCoverage.pathComponents)
        XCTAssertEqual("a", classCoverage.filename)
    }

    func testEmptyPathComponent() {
        let classCoverage = ClassCoverage(path:"", lines:[], verbose:false)
        XCTAssertEqual([], classCoverage.pathComponents)
        XCTAssertNil(classCoverage.filename)
    }

    func testSort() {
        let fc_a = ClassCoverage(path:"/a", lines:[], verbose:false)
        let fc_a_b = ClassCoverage(path:"/a/b", lines:[], verbose:false)
        let fc_a_b_c = ClassCoverage(path:"/a/b/c", lines:[], verbose:false)
        let fc_d = ClassCoverage(path:"/d", lines:[], verbose:false)
        let fc_d_e_f = ClassCoverage(path:"/d/e/f", lines:[], verbose:false)
        let classCoverages = [
            fc_d,
            fc_a_b,
            fc_a,
            fc_d_e_f,
            fc_a_b_c
        ]
        let sorted = classCoverages.sort()
        XCTAssertEqual([fc_a,fc_a_b,fc_a_b_c,fc_d,fc_d_e_f], sorted)
    }

}
