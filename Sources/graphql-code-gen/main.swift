import Foundation
import Alamofire
import Commander
import Unbox


let introspectionQuery = "query IntrospectionQuery { __schema {     queryType { name }     mutationType { name }     subscriptionType { name }     types {         ...FullType     }     directives {         name         description         args {             ...InputValue         }         onOperation         onFragment         onField     } } }  fragment FullType on __Type {     kind     name     description     fields(includeDeprecated: true) {         name         description         args {             ...InputValue         }         type {             ...TypeRef         }         isDeprecated         deprecationReason     }     inputFields {         ...InputValue     }     interfaces {         ...TypeRef     }     enumValues(includeDeprecated: true) {         name         description         isDeprecated         deprecationReason     }     possibleTypes {         ...TypeRef     } }  fragment InputValue on __InputValue {     name     description     type { ...TypeRef }     defaultValue }  fragment TypeRef on __Type {     kind     name     ofType {     kind     name     ofType {     kind     name     ofType {     kind     name     }     }     } }"



command(
    Argument("url"),
    Option("path", ".", description: "Output path, default: ."),
    Option("username", "", description: "HTTP Basic auth username"),
    Option("password", "", description: "HTTP Basic auth password"),
    Option("bearer", "", description: "HTTP Bearer auth token, eg: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1N..."),
    Flag("v", description: "Add verbose output"),
    Flag("r", description: "Raw body (old GraphQL servers accept the query as a raw POST)")
) {
    (url: String, path: String, username: String, password: String, bearerToken: String, verbose: Bool, raw: Bool) in
    
    
    
    getKodeSmells().responseArray { (response: DataResponse<[GraphQLTypeDescription]>) in
        
        if let error = response.result.error as? UnboxedAlamofireError {
           print("debug:", response.result.value ?? "")
            print("error:",error)
        }
        print("response:",response)
    
    }
    dispatchMain()
    
    var headers: [String: String] = [:]
    
    if username != "" || password != "" {
        let encodedData = (username + ":" + password).data(using: String.Encoding.utf8)
        
        headers["Authorization"] = "Basic " + (encodedData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))!
    } else if bearerToken != "" {
        headers["Authorization"] = "Bearer \(bearerToken)"
    }
    
    let parameters = ["query": introspectionQuery]



    Alamofire.request(url,
                      method:.post,
                      parameters:parameters,
                      encoding: JSONEncoding.default).responseJSON { r in
            let test = r.result.value as? NSDictionary ?? [:]
            print("r:",r)
          
//
//
//            convertFromGraphQLToSwift(types: response.types.filter { $0.name?.hasPrefix("__") == false }).forEach { builder in
//                let outputFile = "\(path)/\(builder.name).swift"
//
//                let code = builder.code
//
//                if verbose {
//                    print(code)
//                }
//
//                do {
//                    try code.write(toFile: outputFile, atomically: false, encoding: String.Encoding.utf8)
//                } catch {
//                    print("Unable to write to \(outputFile)")
//                }
//            }
//
            exit(0)
        }
    
    dispatchMain()
}.run()
