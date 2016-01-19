//
//  ProfdataToCobertura.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/5/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import Foundation

enum RunMode {
    case Invalid
    case LLVMCov
    case InputFile
}

struct LLVMCovArguments {
    let binaryPath:String?
    let profdataPath:String?
    let inputFilePath:String?
    let sourcePath:String?
    let outputPath:String?
    let verbose:Bool

    var runMode:RunMode {
        get {
            let haveLLVMCovParameters = (binaryPath != nil) && (profdataPath != nil)
            let haveInputFileParameters = (inputFilePath != nil)
            if haveLLVMCovParameters == haveInputFileParameters {
                return .Invalid
            } else if haveLLVMCovParameters {
                return .LLVMCov
            } else {
                return .InputFile
            }
        }
    }

    var description: String {
        return "LLVMCovArguments"
            + "\n\trunMode=\(runMode)"
            + "\n\tbinaryPath=\(binaryPath ?? "")"
            + "\n\tprofdataPath=\(profdataPath ?? "")"
            + "\n\tsourcePath=\(sourcePath ?? "")"
            + "\n\toutputPath=\(outputPath ?? "")"
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

    typealias NextArgFunction = (value:String) -> Void

    func showSyntax() {
        print("ProfdataToCobertura [-inputFile pathToLLVMCovOutput] [-llvm-cov <pathToAppBinary> <pathToProfdataFile>] [-verbose] [-source <sourceRootPath>] [-output outputFilepath]")
        print("   either '-inputFile' or '-llvm-cov' option is required, but not both")
        exit(1)
    }

    func parseCommandLineArgs(originalArgs:[String]) -> LLVMCovArguments? {
        var args = originalArgs
        args.removeFirst()

        var errors:[String] = []
        var binaryPath:String?
        var profdataPath:String?
        var inputFilePath:String?
        var sourcePath:String?
        var outputPath:String?
        var verbose = false
        var nextArgs:[NextArgFunction] = []
        var lastArg:String?

        for arg in args {
            if nextArgs.count > 0 {
                if arg.hasPrefix("-") {
                    errors.append("Did not expect option \(arg) here")
                    nextArgs = []
                } else {
                    let nextArg = nextArgs.removeFirst()
                    nextArg(value:arg)
                }
            } else if arg == "-llvm-cov" {
                nextArgs = []
                nextArgs.append({ anArg in binaryPath = anArg })
                nextArgs.append({ anArg in profdataPath = anArg })
            } else if arg == "-inputFile" {
                nextArgs = []
                nextArgs.append({ anArg in inputFilePath = anArg })
            } else if arg == "-source" {
                nextArgs = []
                nextArgs.append({ anArg in sourcePath = anArg })
            } else if arg == "-output" {
                nextArgs = []
                nextArgs.append({ anArg in outputPath = anArg })
            } else if arg == "-verbose" {
                verbose = true
            } else {
                errors.append("Unknown argument: \(arg)")
            }
            lastArg = arg
        }
        if nextArgs.count > 0 {
            errors.append("Missing value\(nextArgs.count > 1 ? "s" : "") after \(lastArg)")
        }
        if errors.count > 0 {
            for error in errors {
                print(error)
            }
            return nil
        }
        let result = LLVMCovArguments(binaryPath:binaryPath, profdataPath:profdataPath, inputFilePath:inputFilePath, sourcePath:sourcePath, outputPath:outputPath, verbose:verbose)
        if verbose {
            print("Current directory=\(NSFileManager.defaultManager().currentDirectoryPath)")
            print(result.description)
        }
        return result
    }

    func runLLVMCovWithBinary(binaryPath:String, profdataPath:String, verbose:Bool) -> Result<String> {
        let task = NSTask()
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = [
            "llvm-cov",
            "show",
            binaryPath,
            "-instr-profile",
            profdataPath
        ]

        let outputPipe = NSPipe()
        let errorPipe = NSPipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        if verbose {
            print("Launch: xcrun \(task.arguments!.joinWithSeparator(" "))")
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
        if verbose {
            print("Success with \(outputString.characters.count) of output")
        }
        return Result.Success(outputString)
    }

    func getLLVMCovOutputWithCommandLineArgs(args:[String]) -> (String, LLVMCovArguments)? {
        if let llvmCovArgs = parseCommandLineArgs(args) {

            switch (llvmCovArgs.runMode) {
            case .Invalid:
                print("Invalid run mode")
            case .LLVMCov:
                let result = runLLVMCovWithBinary(llvmCovArgs.binaryPath!, profdataPath: llvmCovArgs.profdataPath!, verbose: llvmCovArgs.verbose)
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
            case .InputFile:
                if let data = NSData(contentsOfFile: llvmCovArgs.inputFilePath!) {
                    if let outputString = NSString(data:data, encoding: NSUTF8StringEncoding) as? String {
                        return (outputString,llvmCovArgs)
                    }
                }
                print("Could not read inputFile: \(llvmCovArgs.inputFilePath!)")
            }
        }
        showSyntax()
        return nil
    }
    
}
