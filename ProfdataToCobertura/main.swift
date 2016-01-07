//
//  main.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/5/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import Foundation

func main()  {
    let runner = Runner()
    if let (outputString, args) = runner.run() {
        let rootPackage = outputString.parseLLVMCovOutput(args)
//        let packageCoverage = PackageCoverage(fileCoverages:fileCoverages)
//        for fileCoverage in fileCoverages {
//            print("c=\(fileCoverage.lines.count), h=\(fileCoverage.hits), \(fileCoverage.path)")
//        }
        let fc = rootPackage.files[0]
        print(fc.lines.joinWithSeparator("\n"))
        print("lines=\(fc.lines.count)")
        print("hits=\(fc.hits)")
    }
}

main()