//
//  PackageCoverage.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/5/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import Foundation

func ==(lhs: PackageCoverage, rhs: PackageCoverage) -> Bool {
    return (lhs.pathComponents == rhs.pathComponents)
}

func <(lhs: PackageCoverage, rhs: PackageCoverage) -> Bool {
    let lhsCount = lhs.pathComponents.count
    let rhsCount = rhs.pathComponents.count
    let count = min(lhsCount,rhsCount)
    for index in 0..<count {
        let lhsPathComponent = lhs.pathComponents[index]
        let rhsPathComponent = rhs.pathComponents[index]
        if lhsPathComponent != rhsPathComponent {
            return lhsPathComponent < rhsPathComponent
        }
    }
    return lhsCount < rhsCount
}

class PackageCoverage: Comparable {
    let pathComponents:[String]
    let classes:[ClassCoverage]
    var packages:[PackageCoverage] = []
    var path:String {
        return pathComponents.joinWithSeparator(ProfdataToCobertura.PathSeparator)
    }

    var lineCount:Int {
        return classes.reduce(0) {$0 + $1.lineCount} +  packages.reduce(0) {$0 + $1.lineCount}
    }
    var totalLineHitCount:Int {
        return classes.reduce(0) {$0 + $1.totalLineHitCount} +  packages.reduce(0) {$0 + $1.totalLineHitCount}
    }
    var lineRate:Float {
        return lineCount > 0 ? Float(totalLineHitCount) / Float(lineCount) : 0.0
    }
    var branchRate:Float { return 0.0 }
    var complexity:Float { return 0.0 }

    init(pathComponents:[String], classes:[ClassCoverage]) {
        self.pathComponents = pathComponents
        self.classes = classes
    }

    class func toPackageTree(classes:[ClassCoverage]) -> PackageCoverage {
        var flatPackages = PackageCoverage.toFlatPackages(classes)
        if flatPackages.count == 0 {
            return PackageCoverage(pathComponents: [], classes: []) // no classes
        }

        // insert any empty packages from root of "" to first package in list
        while flatPackages[0].pathComponents != [] {
            var parentPathComponents = flatPackages[0].pathComponents
            parentPathComponents.removeLast()
            flatPackages.insert(PackageCoverage(pathComponents:parentPathComponents, classes:[]), atIndex:0)
        }

        var rootPackage:PackageCoverage?

        for package in flatPackages {
            if let rootPackage = rootPackage {
                rootPackage.insertChildInTree(package)
            } else {
                rootPackage = package
            }
        }

        return rootPackage!
    }

    private func insertChildInTree(child:PackageCoverage) {
        if pathComponents != [] {
            print("Error: insertChildInTree only valid for root package")
            return
        }

        var parentPathComponents = child.pathComponents
        parentPathComponents.removeLast()

        var currentPackage = self
        var currentPathComponent:[String] = currentPackage.pathComponents
        for pathComponent in parentPathComponents {
            currentPathComponent.append(pathComponent)
            let matchingChildren = currentPackage.packages.filter { $0.pathComponents == currentPathComponent }
            if let package = matchingChildren.first {
                currentPackage = package
            } else {
                let package = PackageCoverage(pathComponents:currentPathComponent, classes:[])
                currentPackage.packages.append(package)
                currentPackage = package
            }
        }
        currentPackage.packages.append(child)
    }

    class func toFlatPackages(classes:[ClassCoverage]) -> [PackageCoverage] {
        var classesXref:[String:[ClassCoverage]] = [:]
        var filePackageNames:[String] = []
        for file in classes {
            let filePackagePath = file.pathComponents.joinWithSeparator(ProfdataToCobertura.PathSeparator)
            if var packageClasses = classesXref[filePackagePath] {
                packageClasses.append(file)
                classesXref[filePackagePath] = packageClasses
            } else {
                filePackageNames.append(filePackagePath)
                classesXref[filePackagePath] = [file]
            }
        }

        var result:[PackageCoverage] = []
        for filePackageName in filePackageNames {
            let packageClasses = classesXref[filePackageName]!
            let firstFile = packageClasses.first!
            result.append(PackageCoverage(pathComponents:firstFile.pathComponents, classes:packageClasses))
        }

        return result
    }

    func appendXML(packagesElement:NSXMLElement) {

// <package branch-rate="0.136363636364" complexity="0.0" line-rate="0.307692307692" name=".Users.Shared.Jenkins.Home.jobs.ASDA.workspace.asda">

        let packageElement = packagesElement.addChildElementWithName("package")
        packageElement.addAttributeWithName("branch-rate", value: "\(branchRate)")
        packageElement.addAttributeWithName("complexity", value: "\(complexity)")
        packageElement.addAttributeWithName("line-rate", value: "\(lineRate)")
        packageElement.addAttributeWithName("name", value: "\(path)")

        if self.classes.count > 0 {
            let classesElement = packageElement.addChildElementWithName("classes")
            for clazz in self.classes {
                clazz.appendXML(classesElement)
            }
        }
    }

}
