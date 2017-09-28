import Foundation
import Unbox

// class to avoid having to Box ofType
class GraphQLTypeDescription: Unboxable {
    let kind: GraphQLTypeKind?
    let name: String?
    let description: String?
    let fields: [GraphQLFieldDescription]?
    let interfaces: [GraphQLTypeDescription]?
    let possibleTypes: [GraphQLTypeDescription]?
    let enumValues: [GraphQLEnumValueDescription]?
    let inputFields: [GraphQLInputFieldDescription]?
    let ofType: GraphQLTypeDescription?
    
    required public init(unboxer: Unboxer) throws {
        name =  unboxer.unbox(key:"name")
        description =  unboxer.unbox(key:"description")
        fields =  unboxer.unbox(key:"fields")
        interfaces =  unboxer.unbox(key:"interfaces")
        possibleTypes =  unboxer.unbox(key:"possibleTypes")
        enumValues =  unboxer.unbox(key:"enumValues")
        inputFields =  unboxer.unbox(key:"inputFields")
        ofType =  unboxer.unbox(key:"ofType")
         kind =  unboxer.unbox(key: "kind", formatter: GraphQLTypeKindFormatter())

    }
}

struct GraphQLFieldDescription: Unboxable {
    let name: String
    let description: String?
    let args: [GraphQLInputFieldDescription]?
    let type: GraphQLTypeDescription?
    let isDeprecated: Bool?
    let deprecationReason: String?
    
    init(unboxer: Unboxer) throws {
         name =  try unboxer.unbox(key:"name")
        description =  unboxer.unbox(key:"description")
        args =  unboxer.unbox(key:"args")
        type =   unboxer.unbox(key:"type")
        isDeprecated =   unboxer.unbox(key:"isDeprecated")
        deprecationReason =  unboxer.unbox(key:"deprecationReason")
    }
}

struct GraphQLEnumValueDescription: Unboxable {
    let name: String
    let description: String?
    let isDeprecated: Bool?
    let deprecationReason: String?
    
    init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(key:"name")
        description =  unboxer.unbox(key:"description")
        isDeprecated = unboxer.unbox(key:"isDeprecated")
        deprecationReason =  unboxer.unbox(key:"deprecationReason")
    }
}

struct GraphQLInputFieldDescription: Unboxable {
    let name: String
    let description: String?
    let type: GraphQLTypeDescription?
    let defaultValue: String?
    
    init(unboxer: Unboxer) throws {
         name = try unboxer.unbox(key:"name")
        description =  unboxer.unbox(key:"description")
         type = unboxer.unbox(key:"type")
        defaultValue =  unboxer.unbox(key:"defaultValue")
    }
}


enum GraphQLTypeKind: Int, UnboxableEnum {
    case scalar
    case object
    case interface
    case union
    case Enum
    case inputObject
    case list
    case nonnull
    
    
}


struct GraphQLTypeKindFormatter: UnboxFormatter {
    func format(unboxedValue: String) -> GraphQLTypeKind? {
        let components = unboxedValue.components(separatedBy: ":")
        
        guard components.count == 2 else {
            return nil
        }
        
        let identifier = components[0]
        
        guard let value = Int(components[1]) else {
            return nil
        }
        
        switch identifier {
        case "SCALAR":
            return .scalar
        default:
            return nil
        }
    }
}

struct IntrospectionQueryResponse: Unboxable {
    let types: [GraphQLTypeDescription]
    
    init(unboxer: Unboxer) throws {
        try types = unboxer.unbox(keyPath: "data.__schema.types")
    }
}

func getTypeReference(type: GraphQLTypeDescription) -> SwiftTypeReference {
    switch (type.kind) {
    case .scalar?:
        switch (type.name!) {
        case "ID":
            return SwiftTypeReference("String").wrapOptional()
        case "Boolean":
            return SwiftTypeReference("Bool").wrapOptional()
        default:
            return SwiftTypeReference(type.name!).wrapOptional()
        }
    case .list?:
        guard let innerType = type.ofType else {
            print("List type missing inner type")
            return SwiftTypeReference("INVALID_TYPE")
        }
        return SwiftTypeReference("Array", genericParameters: [getTypeReference(type: innerType)]).wrapOptional()
    case .nonnull?:
        guard let innerType = type.ofType else {
            print("NonNull type missing inner type")
            return SwiftTypeReference("INVALID_TYPE")
        }
        return getTypeReference(type: innerType).unwrapOptional()
    default:
        return SwiftTypeReference(type.name!).wrapOptional()
    }
}

func convertFromGraphQLToSwift(types: [GraphQLTypeDescription]) -> [SwiftTypeBuilder] {
    return types.flatMap { graphQLType in
        switch graphQLType.kind {
        case .object?, .interface?:
            guard let name = graphQLType.name else {
                print("Object/Interface type must have a name")
                return nil
            }
            
            guard let fields = graphQLType.fields else {
                print("Object/Interface type must have fields")
                return nil
            }
            
            let swiftFields: [SwiftMemberBuilder] = fields.map { f in
                return SwiftFieldBuilder(f.name, getTypeReference(type: f.type!))
            }
            
            let interfaceReferences = graphQLType.interfaces?.map { SwiftTypeReference($0.name!) } ?? []
            
            return SwiftTypeBuilder(name, graphQLType.kind == .object ? .Class : .Protocol, swiftFields, interfaceReferences)
        case .inputObject?:
            guard let name = graphQLType.name else {
                print("InputObject type must have a name")
                return nil
            }
            
            guard let fields = graphQLType.inputFields else {
                print("InputObject type must have inputFields")
                return nil
            }
            
            let swiftFields: [SwiftMemberBuilder] = fields.map { f in
                return SwiftFieldBuilder(f.name, getTypeReference(type: f.type!))
            }
            
            return SwiftTypeBuilder(name, .Class, swiftFields)
        case .Enum?:
            guard let name = graphQLType.name else {
                print("Enum type must have a name")
                return nil
            }
            
            guard let enumValues = graphQLType.enumValues else {
                print("Enum type must have enumValues")
                return nil
            }
            
            let swiftFields: [SwiftMemberBuilder] = enumValues.map { v in
                return SwiftEnumValueBuilder(v.name, v.name)
            }
            
            return SwiftTypeBuilder(name, .Enum, swiftFields, [SwiftTypeReference("String")])
        default:
            print("Unable to handle \(graphQLType.kind)")
            return nil
        }
    }
}

