//
//  XMLExtensions.swift
//  ProfdataToCobertura
//
//  Created by Douglas Sjoquist on 1/7/16.
//  Copyright © 2016 Ivy Gulch. All rights reserved.
//

import Foundation

extension NSXMLElement {
    func addAttributeWithName(name:String, value:String) -> NSXMLNode {
        let attribute = NSXMLNode.attributeWithName(name, stringValue: value) as! NSXMLNode
        self.addAttribute(attribute)
        return attribute
    }

    func addChildElementWithName(name:String, value:String? = nil) -> NSXMLElement {
        var child:NSXMLElement!
        if let value = value {
            child = NSXMLNode.elementWithName(name, stringValue:value) as! NSXMLElement
        } else {
            child = NSXMLNode.elementWithName(name) as! NSXMLElement
        }
        self.addChild(child)
        return child
    }
}