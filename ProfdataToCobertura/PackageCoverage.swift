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
    let files:[FileCoverage]
    var packages:[PackageCoverage] = []
    var path:String {
        return pathComponents.joinWithSeparator(ProfdataToCobertura.PathSeparator)
    }

    init(pathComponents:[String], files:[FileCoverage]) {
        self.pathComponents = pathComponents
        self.files = files
    }

    init(files:[FileCoverage]) {
        let rootPackage = PackageCoverage.toPackageTree(files)
        self.pathComponents = rootPackage.pathComponents
        self.files = rootPackage.files
        self.packages = rootPackage.packages
    }

    private class func toPackageTree(files:[FileCoverage]) -> PackageCoverage {
        var flatPackages = PackageCoverage.toFlatPackages(files)
        if flatPackages.count == 0 {
            return PackageCoverage(pathComponents: [], files: []) // no files
        }

        // insert any empty packages from root of "" to first package in list
        while flatPackages[0].pathComponents != [] {
            var parentPathComponents = flatPackages[0].pathComponents
            parentPathComponents.removeLast()
            flatPackages.insert(PackageCoverage(pathComponents:parentPathComponents, files:[]), atIndex:0)
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
                let package = PackageCoverage(pathComponents:currentPathComponent, files:[])
                currentPackage.packages.append(package)
                currentPackage = package
            }
        }
        currentPackage.packages.append(child)
    }

    private class func toFlatPackages(files:[FileCoverage]) -> [PackageCoverage] {
        var filesXref:[String:[FileCoverage]] = [:]
        var filePackageNames:[String] = []
        for file in files {
            let filePackagePath = file.pathComponents.joinWithSeparator(ProfdataToCobertura.PathSeparator)
            if var packageFiles = filesXref[filePackagePath] {
                packageFiles.append(file)
                filesXref[filePackagePath] = packageFiles
            } else {
                filePackageNames.append(filePackagePath)
                filesXref[filePackagePath] = [file]
            }
        }

        var result:[PackageCoverage] = []
        for filePackageName in filePackageNames {
            let packageFiles = filesXref[filePackageName]!
            let firstFile = packageFiles.first!
            result.append(PackageCoverage(pathComponents:firstFile.pathComponents, files:packageFiles))
        }

        return result
    }

    func debug(margin:String) {
        print("\(margin)p=\(path), fc=\(files.count)")
        for file in files {
            print("\(margin)      file=\(file.path)")
        }
        for child in packages {
            child.debug(margin+"  ")
        }
    }

}
