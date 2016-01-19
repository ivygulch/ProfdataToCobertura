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

    func testFlatGroup() {
        let fcA = ClassCoverage(path: "Filename.A", lines: [], verbose:false)
        let fcB = ClassCoverage(path: "Filename.B", lines: [], verbose:false)
        let fcC = ClassCoverage(path: "Filename.C", lines: [], verbose:false)
        let classCoverages = [fcA, fcB, fcC]
        let rootPackage = PackageCoverage.toPackageTree(classCoverages)

        XCTAssertEqual("", rootPackage.path)
        XCTAssertEqual([], rootPackage.pathComponents)
        XCTAssertEqual([], rootPackage.packages)
        XCTAssertEqual([fcA,fcB,fcC], rootPackage.classes)
    }

    func testSingleGroupWithPathComponents() {
        let fcA = ClassCoverage(path: "/a/b/Filename.A", lines: [], verbose:false)
        let fcB = ClassCoverage(path: "/a/b/Filename.B", lines: [], verbose:false)
        let fcC = ClassCoverage(path: "/a/b/Filename.C", lines: [], verbose:false)
        let classCoverages = [fcA, fcB, fcC]
        let rootPackage = PackageCoverage.toPackageTree(classCoverages)

        XCTAssertEqual([], rootPackage.pathComponents)
        XCTAssertEqual([], rootPackage.classes)
        if rootPackage.packages.count != 1 {
            XCTFail("Expected child package for 'a'")
            return
        }
        let packageA = rootPackage.packages[0]

        XCTAssertEqual(["a"], packageA.pathComponents)
        XCTAssertEqual([], packageA.classes)
        if packageA.packages.count != 1 {
            XCTFail("Expected child package for 'b'")
            return
        }
        let packageB = packageA.packages[0]

        XCTAssertEqual(["a","b"], packageB.pathComponents)
        XCTAssertEqual([], packageB.packages)
        XCTAssertEqual([fcA,fcB,fcC], packageB.classes)
    }

    func testMultipleGroupsWithPathComponents() {
        let fcA = ClassCoverage(path: "Filename.A", lines: [], verbose:false)
        let fcB = ClassCoverage(path: "/a/b/c/Filename.B", lines: [], verbose:false)
        let fcC = ClassCoverage(path: "/d/Filename.C", lines: [], verbose:false)
        let classCoverages = [fcA, fcB, fcC]
        let rootPackage = PackageCoverage.toPackageTree(classCoverages)

        XCTAssertEqual([], rootPackage.pathComponents)
        XCTAssertEqual([fcA], rootPackage.classes)
        if rootPackage.packages.count != 2 {
            XCTFail("Expected child packages for 'a' & 'd'")
            return
        }
        let packageA = rootPackage.packages[0]
        let packageD = rootPackage.packages[1]

        XCTAssertEqual(["a"], packageA.pathComponents)
        XCTAssertEqual([], packageA.classes)
        if packageA.packages.count != 1 {
            XCTFail("Expected child package for 'b'")
            return
        }
        let packageB = packageA.packages[0]

        XCTAssertEqual(["a","b"], packageB.pathComponents)
        XCTAssertEqual([], packageB.classes)
        if packageB.packages.count != 1 {
            XCTFail("Expected child package for 'c'")
            return
        }
        let packageC = packageB.packages[0]

        XCTAssertEqual(["d"], packageD.pathComponents)
        XCTAssertEqual([], packageC.packages)
        XCTAssertEqual([fcC], packageD.classes)
    }
    
}
