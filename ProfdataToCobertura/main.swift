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
        let summaryCoverage = outputString.parseLLVMCovOutput(args)
        summaryCoverage.saveXML(args)
    }
}

main()