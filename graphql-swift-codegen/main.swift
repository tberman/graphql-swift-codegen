//
//  main.swift
//  graphql-swift-codegen
//
//  Copyright © 2015 Todd Berman. All rights reserved.
//

import Foundation
import Alamofire
import Commander
import Mapper

let introspectionQuery = "query IntrospectionQuery { __schema { queryType { name } mutationType { name } types { ...FullType } directives { name description args { ...InputValue } onOperation onFragment onField } } } fragment FullType on __Type { kind name description fields { name description args { ...InputValue } type { ...TypeRef } isDeprecated deprecationReason } inputFields { ...InputValue } interfaces { ...TypeRef } enumValues { name description isDeprecated deprecationReason } possibleTypes { ...TypeRef } } fragment InputValue on __InputValue { name description type { ...TypeRef } defaultValue } fragment TypeRef on __Type { kind name ofType { kind name ofType { kind name ofType { kind name } } } }"

struct IntrospectionQueryResponse: Mappable {
    let types: [GraphQLTypeDescription]
    
    init(map: Mapper) throws {
        try types = map.from("data.__schema.types")
    }
}

private func wrapOptional(ref: SwiftTypeReference) -> SwiftTypeReference {
    return SwiftTypeReference("Optional", genericParameters: [ref])
}

private func unwrapOptional(ref: SwiftTypeReference) -> SwiftTypeReference {
    if ref.typeName == "Optional" {
        return ref.genericParameters[0]
    }
    
    return ref
}

func getTypeReference(type: GraphQLTypeDescription) -> SwiftTypeReference {
    switch (type.kind) {
    case .Scalar:
        switch (type.name!) {
        case "ID":
            return wrapOptional(SwiftTypeReference("String"))
        case "Boolean":
            return wrapOptional(SwiftTypeReference("Bool"))
        default:
            return wrapOptional(SwiftTypeReference(type.name!))
        }
    case .List:
        return wrapOptional(SwiftTypeReference("Array", genericParameters: [getTypeReference(type.ofType!)]))
    case .NonNull:
        return unwrapOptional(getTypeReference(type.ofType!))
    default:
        return wrapOptional(SwiftTypeReference(type.name!))
    }
}

func convertFromGraphQLToSwift(types: [GraphQLTypeDescription]) -> [SwiftTypeBuilder] {
    return types.flatMap { graphQLType in
        switch graphQLType.kind {
        case .Object:
            guard let name = graphQLType.name else {
                print("Object type must have a name")
                return nil
            }
            
            guard let fields = graphQLType.fields else {
                print("Object type must have fields")
                return nil
            }
            
            let swiftFields: [SwiftMemberBuilder] = fields.map { f in
                return SwiftFieldBuilder(f.name, getTypeReference(f.type))
            }

            return SwiftTypeBuilder(name, .Class, swiftFields)
        case .Enum:
            guard let name = graphQLType.name else {
                print("Enum type must have a name")
                return nil
            }
            
            guard let enumValues = graphQLType.enumValues else {
                print("Enum type must have enumValues")
                return nil
            }
            
            let swiftFields: [SwiftMemberBuilder] = enumValues.map { v in
                return SwiftEnumValueBuilder(v.name.lowercaseString.capitalizedString, v.name)
            }
            
            return SwiftTypeBuilder(name, .Enum, swiftFields, [SwiftTypeReference("String")])
        default:
            print("Unable to handle \(graphQLType.kind)")
            return nil
        }
    }
}

command(
    Argument("url"),
    Option("path", ".", description: "Output path, default: ."),
    Option("username", "", description: "HTTP Basic auth username"),
    Option("password", "", description: "HTTP Basic auth password"),
    Flag("v", description: "Add verbose output"),
    Flag("r", description: "Raw body (old GraphQL servers accept the query as a raw POST)")
) { (url: String, path: String, username: String, password: String, verbose: Bool, raw: Bool) in
    var headers: [String: String] = [:]
    
    if username != "" || password != "" {
        let encodedData = (username + ":" + password).dataUsingEncoding(NSUTF8StringEncoding)
        
        headers["Authorization"] = "Basic " + (encodedData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))!
    }
    
    var parameters = ["query": introspectionQuery]
    
    var rawBodyEncoder: ParameterEncoding = .Custom({ (convertible, params) in
        var mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
        mutableRequest.HTTPBody = introspectionQuery.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        return (mutableRequest, nil)
    })
    
    Alamofire.request(.POST, url, parameters: parameters, headers: headers, encoding: raw ? rawBodyEncoder : .URL)
        .responseJSON { r in
            guard let response = IntrospectionQueryResponse.from(r.result.value as? [String: AnyObject] ?? [:]) else {
                print("Error: incorrect response")
                
                if verbose {
                    print(r)
                }
                
                exit(0)
            }
            
            convertFromGraphQLToSwift(response.types.filter { $0.name?.hasPrefix("__") == false }).forEach { builder in
                let outputFile = "\(path)/\(builder.name).swift"
                
                let code = builder.code
                
                if verbose {
                    print(code)
                }
                
                do {
                    try code.writeToFile(outputFile, atomically: false, encoding: NSUTF8StringEncoding)
                } catch {
                    print("Unable to write to \(outputFile)")
                }
            }
            
            exit(0)
        }
    
    dispatch_main()
}.run()