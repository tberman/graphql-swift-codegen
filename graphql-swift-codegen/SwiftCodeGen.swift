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
    let members: [SwiftMemberBuilder]
    let inheritedTypes: [SwiftTypeReference]
    
    convenience init(_ name: String, _ kind: Kind, _ members: [SwiftMemberBuilder]) {
        self.init(name, kind, members, [])
    }
    
    init (_ name: String, _ kind: Kind, _ members: [SwiftMemberBuilder], _ inheritedTypes: [SwiftTypeReference]) {
        self.name = name
        self.kind = kind
        self.members = members
        self.inheritedTypes = inheritedTypes
    }
    
    var code: String {
        let typeDeclaration = "\(kind.rawValue) \(name)" +
            (inheritedTypes.count > 0 ? ": " + (inheritedTypes.map { $0.code }.joinWithSeparator(",")) : "")
        
        return
            "\(typeDeclaration) {\n" +
                (members.map { "    " + $0.code }).joinWithSeparator("\n") + "\n" +
            "}\n"
    }
    
    enum Kind: String {
        case Class = "class"
        case Protocol = "protocol"
        case Enum = "enum"
    }
}

protocol SwiftMemberBuilder {
    var code: String { get }
}

class SwiftFieldBuilder: SwiftMemberBuilder {
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

class SwiftEnumValueBuilder: SwiftMemberBuilder {
    let name: String
    let value: String
    
    init(_ name: String, _ value: String) {
        self.name = name
        self.value = value
    }
    
    var code: String {
        return "case \(name) = \"\(value)\""
    }
}