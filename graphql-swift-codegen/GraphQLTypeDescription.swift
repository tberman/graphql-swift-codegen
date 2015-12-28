//
//  GraphQLTypeDescription.swift
//  graphql-swift-codegen
//
//  Copyright © 2015 Todd Berman. All rights reserved.
//

import Foundation
import Mapper

// class to avoid having to Box ofType
final class GraphQLTypeDescription: Mappable {
    let kind: GraphQLTypeKind
    let name: String?
    let description: String?
    let fields: [GraphQLFieldDescription]?
    let interfaces: [GraphQLTypeDescription]?
    let possibleTypes: [GraphQLTypeDescription]?
    let enumValues: [GraphQLEnumValueDescription]?
    let inputFields: [GraphQLInputFieldDescription]?
    let ofType: GraphQLTypeDescription?
    
    required init(map: Mapper) throws {
        // This should be try kind = map.from("kind") but working around http://www.openradar.me/23472747
        kind = map.optionalFrom("kind") ?? .Scalar
        name = map.optionalFrom("name")
        description = map.optionalFrom("description")
        fields = map.optionalFrom("fields")
        interfaces = map.optionalFrom("interfaces")
        possibleTypes = map.optionalFrom("possibleTypes")
        enumValues = map.optionalFrom("enumValues")
        inputFields = map.optionalFrom("inputFields")
        ofType = map.optionalFrom("ofType")
    }
}

struct GraphQLFieldDescription: Mappable {
    let name: String
    let description: String?
    let args: [GraphQLInputFieldDescription]
    let type: GraphQLTypeDescription
    let isDeprecated: Bool
    let deprecationReason: String?
    
    init(map: Mapper) throws {
        try name = map.from("name")
        description = map.optionalFrom("description")
        try args = map.from("args")
        try type = map.from("type")
        try isDeprecated = map.from("isDeprecated")
        deprecationReason = map.optionalFrom("deprecationReason")
    }
}

struct GraphQLEnumValueDescription: Mappable {
    let name: String
    let description: String?
    let isDeprecated: Bool
    let deprecationReason: String?
    
    init(map: Mapper) throws {
        try name = map.from("name")
        description = map.optionalFrom("description")
        try isDeprecated = map.from("isDeprecated")
        deprecationReason = map.optionalFrom("deprecationReason")
    }
}

struct GraphQLInputFieldDescription: Mappable {
    let name: String
    let description: String?
    let type: GraphQLTypeDescription
    let defaultValue: String?
    
    init(map: Mapper) throws {
        try name = map.from("name")
        description = map.optionalFrom("description")
        try type = map.from("type")
        defaultValue = map.optionalFrom("defaultValue")
    }
}


enum GraphQLTypeKind: String {
    case Scalar = "SCALAR"
    case Object = "OBJECT"
    case Interface = "INTERFACE"
    case Union = "UNION"
    case Enum = "ENUM"
    case InputObject = "INPUT_OBJECT"
    case List = "LIST"
    case NonNull = "NON_NULL"
}