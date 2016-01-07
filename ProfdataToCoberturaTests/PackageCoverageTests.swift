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
        let packageCoverage = PackageCoverage(pathComponents:[], files: [])
        XCTAssertEqual([], packageCoverage.pathComponents)
        XCTAssertEqual([], packageCoverage.files)
        XCTAssertEqual("", packageCoverage.path)
    }

    func testFlatGroup() {
        let fcA = FileCoverage(path: "Filename.A", lines: [])
        let fcB = FileCoverage(path: "Filename.B", lines: [])
        let fcC = FileCoverage(path: "Filename.C", lines: [])
        let fileCoverages = [fcA, fcB, fcC]
        let rootPackage = PackageCoverage(files:fileCoverages)

        XCTAssertEqual("", rootPackage.path)
        XCTAssertEqual([], rootPackage.pathComponents)
        XCTAssertEqual([], rootPackage.packages)
        XCTAssertEqual([fcA,fcB,fcC], rootPackage.files)
    }

    func testSingleGroupWithPathComponents() {
        let fcA = FileCoverage(path: "/a/b/Filename.A", lines: [])
        let fcB = FileCoverage(path: "/a/b/Filename.B", lines: [])
        let fcC = FileCoverage(path: "/a/b/Filename.C", lines: [])
        let fileCoverages = [fcA, fcB, fcC]
        let rootPackage = PackageCoverage(files:fileCoverages)

        XCTAssertEqual([], rootPackage.pathComponents)
        XCTAssertEqual([], rootPackage.files)
        if rootPackage.packages.count != 1 {
            XCTFail("Expected child package for 'a'")
            return
        }
        let packageA = rootPackage.packages[0]

        XCTAssertEqual(["a"], packageA.pathComponents)
        XCTAssertEqual([], packageA.files)
        if packageA.packages.count != 1 {
            XCTFail("Expected child package for 'b'")
            return
        }
        let packageB = packageA.packages[0]

        XCTAssertEqual(["a","b"], packageB.pathComponents)
        XCTAssertEqual([], packageB.packages)
        XCTAssertEqual([fcA,fcB,fcC], packageB.files)
    }

    func testMultipleGroupsWithPathComponents() {
        let fcA = FileCoverage(path: "Filename.A", lines: [])
        let fcB = FileCoverage(path: "/a/b/c/Filename.B", lines: [])
        let fcC = FileCoverage(path: "/d/Filename.C", lines: [])
        let fileCoverages = [fcA, fcB, fcC]
        let rootPackage = PackageCoverage(files:fileCoverages)

        XCTAssertEqual([], rootPackage.pathComponents)
        XCTAssertEqual([fcA], rootPackage.files)
        if rootPackage.packages.count != 2 {
            XCTFail("Expected child packages for 'a' & 'd'")
            return
        }
        let packageA = rootPackage.packages[0]
        let packageD = rootPackage.packages[1]

        XCTAssertEqual(["a"], packageA.pathComponents)
        XCTAssertEqual([], packageA.files)
        if packageA.packages.count != 1 {
            XCTFail("Expected child package for 'b'")
            return
        }
        let packageB = packageA.packages[0]

        XCTAssertEqual(["a","b"], packageB.pathComponents)
        XCTAssertEqual([], packageB.files)
        if packageB.packages.count != 1 {
            XCTFail("Expected child package for 'c'")
            return
        }
        let packageC = packageB.packages[0]

        XCTAssertEqual(["d"], packageD.pathComponents)
        XCTAssertEqual([], packageC.packages)
        XCTAssertEqual([fcC], packageD.files)
    }
    
}
