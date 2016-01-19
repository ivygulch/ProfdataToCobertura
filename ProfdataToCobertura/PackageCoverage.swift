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

    var activeLineCount:Int {
        return classes.reduce(0) {$0 + $1.activeLineCount} +  packages.reduce(0) {$0 + $1.activeLineCount}
    }
    var totalLineHitCount:Int {
        return classes.reduce(0) {$0 + $1.totalLineHitCount} +  packages.reduce(0) {$0 + $1.totalLineHitCount}
    }
    var lineRate:Float {
        return activeLineCount > 0 ? Float(totalLineHitCount) / Float(activeLineCount) : 0.0
    }
    var branchRate:Float { return 0.0 }
    var complexity:Float { return 0.0 }

    init(pathComponents:[String], classes:[ClassCoverage]) {
        self.pathComponents = pathComponents

        var result:[ClassCoverage] = []
        var classXref:[String:ClassCoverage] = [:]
        for originalClass in classes {
            if let existingClass = classXref[originalClass.path] {
                existingClass.merge(originalClass)
            } else {
                result.append(originalClass)
                classXref[originalClass.path] = originalClass
            }
        }
        self.classes = result
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
