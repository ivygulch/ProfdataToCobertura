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
    if let (outputString, llvmCovArgs) = runner.getLLVMCovOutputWithCommandLineArgs(Process.arguments) {
        let summaryCoverage = outputString.parseLLVMCovOutput(llvmCovArgs)
        summaryCoverage.saveXML(llvmCovArgs)
    }
}

main()