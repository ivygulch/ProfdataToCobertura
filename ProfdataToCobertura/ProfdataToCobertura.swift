//
//  ProfdataToCobertura.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/5/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import Foundation

struct LLVMCovArguments {
    let executablePath:String
    let profdataPath:String
    let sourcePath:String?
    let outputPath:String?
    let verbose:Bool

    var description: String {
        let sp = sourcePath ?? ""
        let op = outputPath ?? ""
        return "LLVMCovArguments"
            + "\n\texecutablePath=\(executablePath)"
            + "\n\tprofdataPath=\(profdataPath)"
            + "\n\tsourcePath=\(sp)"
            + "\n\toutputPath=\(op)"
            + "\n\tverbose=\(verbose)"
    }
}

enum Result<T> {
    case Success(T)
    case Error(ErrorType)
}

struct ProfdataToCobertura {
    static let PathSeparator = "/"
    static let DefaultOutputPath = "coverage.xml"
    static let ErrorDomain = "ProfdataToCobertura"
}

class Runner {

    func showSyntax() {
        print("ProfdataToCobertura <pathToAppBinary> <pathToProfdataFile> [-verbose] [-source <sourceRootPath>] [-output outputFilepath]")
        exit(1)
    }

    func parseCommandLine() -> LLVMCovArguments? {
        var errors:[String] = []
        var executablePath:String?
        var profdataPath:String?
        var sourcePath:String?
        var outputPath:String?
        var verbose = false
        var nextArg:((value:String)->Void)?
        var lastArg:String?
        var args = Process.arguments
        args.removeFirst()
        for arg in args {
            if nextArg != nil {
                if arg.hasPrefix("-") {
                    errors.append("Did not expect option \(arg) here")
                } else {
                    nextArg!(value:arg)
                }
                nextArg = nil
            } else if arg == "-source" {
                nextArg = {
                    anArg in
                    sourcePath = anArg
                }
            } else if arg == "-output" {
                nextArg = {
                    anArg in
                    outputPath = anArg
                }
            } else if arg == "-verbose" {
                verbose = true
            } else if executablePath == nil {
                executablePath = arg
            } else if profdataPath == nil {
                profdataPath = arg
            } else {
                errors.append("Unknown argument: \(arg)")
            }
            lastArg = arg
        }
        if nextArg != nil {
            errors.append("Missing value for \(lastArg)")
        }
        if errors.count > 0 {
            for error in errors {
                print(error)
            }
            return nil
        }
        guard let executablePath2 = executablePath else { return nil }
        guard let profdataPath2 = profdataPath else { return nil }
        return LLVMCovArguments(executablePath:executablePath2, profdataPath:profdataPath2, sourcePath:sourcePath, outputPath:outputPath, verbose:verbose)
    }

    func runLLVMCovWithArgs(args:LLVMCovArguments) -> Result<String> {
        let task = NSTask()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = [
            "llvm-cov",
            "show",
            args.executablePath,
            "-instr-profile=\(args.profdataPath)"
        ]

        let outputPipe = NSPipe()
        let errorPipe = NSPipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        if args.verbose {
            print("\(args.description)")
            print("xcrun \(task.arguments!.joinWithSeparator(" "))")
        }
        task.launch()

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if errorData.length > 0 {
            let errorString = NSString(data: errorData, encoding: NSUTF8StringEncoding)!
            let errors = errorString.componentsSeparatedByString("\n") as [String]
            let errorType = NSError(domain:ProfdataToCobertura.ErrorDomain, code:-1, userInfo: ["errors":errors])
            return Result.Error(errorType)
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = NSString(data: outputData, encoding: NSUTF8StringEncoding) as! String
        if args.verbose {
            print("success with \(outputString.characters.count) of output")
        }
        return Result.Success(outputString)
    }

    func run() -> (String, LLVMCovArguments)? {
        if let llvmCovArgs = parseCommandLine() {
            let result = runLLVMCovWithArgs(llvmCovArgs)
            switch result {
            case .Success(let outputString):
                return (outputString,llvmCovArgs)
            case .Error(let error):
                if let errors = (error as NSError).userInfo["errors"] as? [String] where errors.count > 0 {
                    for error in errors {
                        print(error)
                    }
                } else {
                    print("An error occured: \(error)")
                }
            }
        }
        showSyntax()
        return nil
    }

}
