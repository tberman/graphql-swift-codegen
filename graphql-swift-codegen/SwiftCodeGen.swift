//
//  SwiftCodeGen.swift
//  graphql-swift-codegen
//
//  Copyright © 2015 Todd Berman. All rights reserved.
//

import Foundation

struct SwiftTypeReference {
    let typeName: String
    let optional: Bool
    let list: Bool
    
    var code: String {
        var c = typeName
        
        if list {
            c = "[" + c + "]"
        }
        
        if optional {
            c = c + "?"
        }
        
        return c
    }
}

class SwiftTypeBuilder {
    
    let name: String
    let kind: Kind
    let fields: [SwiftFieldBuilder]
    
    init(_ name: String, _ kind: Kind, _ fields: [SwiftFieldBuilder]) {
        self.name = name
        self.kind = kind
        self.fields = fields
    }
    
    var code: String {
        return
            "class \(name) {\n" +
                (fields.map { "    " + $0.code }).joinWithSeparator("\n") + "\n" +
            "}\n"
    }
    
    enum Kind {
        case Class
        case Protocol
        case Enum
    }
}

class SwiftFieldBuilder {
    let name: String
    let typeReference: SwiftTypeReference
    
    init(_ name: String, _ typeReference: SwiftTypeReference) {
        self.name = name
        self.typeReference = typeReference
    }
    
    var code: String {
        return "var \(name): \(typeReference.code)"
    }
}