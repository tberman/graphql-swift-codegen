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

func getTypeReference(type: GraphQLTypeDescription) -> SwiftTypeReference {
    switch (type.kind) {
    case .Scalar:
        switch (type.name!) {
        case "ID":
            return SwiftTypeReference("String").wrapOptional()
        case "Boolean":
            return SwiftTypeReference("Bool").wrapOptional()
        default:
            return SwiftTypeReference(type.name!).wrapOptional()
        }
    case .List:
        guard let innerType = type.ofType else {
            print("List type missing inner type")
            return SwiftTypeReference("INVALID_TYPE")
        }
        return SwiftTypeReference("Array", genericParameters: [getTypeReference(type: innerType)]).wrapOptional()
    case .NonNull:
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
        case .Object, .Interface:
            guard let name = graphQLType.name else {
                print("Object/Interface type must have a name")
                return nil
            }
            
            guard let fields = graphQLType.fields else {
                print("Object/Interface type must have fields")
                return nil
            }
            
            let swiftFields: [SwiftMemberBuilder] = fields.map { f in
                return SwiftFieldBuilder(f.name, getTypeReference(type: f.type))
            }
            
            let interfaceReferences = graphQLType.interfaces?.map { SwiftTypeReference($0.name!) } ?? []

            return SwiftTypeBuilder(name, graphQLType.kind == .Object ? .Class : .Protocol, swiftFields, interfaceReferences)
        case .InputObject:
            guard let name = graphQLType.name else {
                print("InputObject type must have a name")
                return nil
            }
            
            guard let fields = graphQLType.inputFields else {
                print("InputObject type must have inputFields")
                return nil
            }
            
            let swiftFields: [SwiftMemberBuilder] = fields.map { f in
                return SwiftFieldBuilder(f.name, getTypeReference(type: f.type))
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
                return SwiftEnumValueBuilder(v.name, v.name)
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
    Option("bearer", "", description: "HTTP Bearer auth token, eg: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1N..."),
    Flag("v", description: "Add verbose output"),
    Flag("r", description: "Raw body (old GraphQL servers accept the query as a raw POST)")
) { (url: String, path: String, username: String, password: String, bearerToken: String, verbose: Bool, raw: Bool) in
    var headers: [String: String] = [:]
    
    if username != "" || password != "" {
        let encodedData = (username + ":" + password).data(using: String.Encoding.utf8)
        
        headers["Authorization"] = "Basic " + (encodedData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))!
    } else if bearerToken != "" {
        headers["Authorization"] = "Bearer \(bearerToken)"
    }
    
    let parameters = ["query": introspectionQuery]
//
//    var rawBodyEncoder: ParameterEncoding = .custom({ (convertible, params) in
//        var mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
//        mutableRequest.HTTPBody = introspectionQuery.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
//        return (mutableRequest, nil)
//    })
//
    Alamofire.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString), headers: nil)
        .validate().responseJSON { r in
            let test = r.result.value as? NSDictionary ?? [:]
            guard let response = IntrospectionQueryResponse.from(test) else {
                print("Error: incorrect response")
                
                if verbose {
                    print(r)
                }
                
                exit(0)
            }
            
            convertFromGraphQLToSwift(types: response.types.filter { $0.name?.hasPrefix("__") == false }).forEach { builder in
                let outputFile = "\(path)/\(builder.name).swift"
                
                let code = builder.code
                
                if verbose {
                    print(code)
                }
                
                do {
                    try code.write(toFile: outputFile, atomically: false, encoding: String.Encoding.utf8)
                } catch {
                    print("Unable to write to \(outputFile)")
                }
            }
            
            exit(0)
        }
    
    dispatchMain()
}.run()
