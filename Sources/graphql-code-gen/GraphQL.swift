import Foundation
import Alamofire
import Commander
import Mapper



public func getKodeSmells() -> DataRequest{
    

    let introspectionQuery = "query IntrospectionQuery { __schema {     queryType { name }     mutationType { name }     subscriptionType { name }     types {         ...FullType     }     directives {         name         description         args {             ...InputValue         }         onOperation         onFragment         onField     } } }  fragment FullType on __Type {     kind     name     description     fields(includeDeprecated: true) {         name         description         args {             ...InputValue         }         type {             ...TypeRef         }         isDeprecated         deprecationReason     }     inputFields {         ...InputValue     }     interfaces {         ...TypeRef     }     enumValues(includeDeprecated: true) {         name         description         isDeprecated         deprecationReason     }     possibleTypes {         ...TypeRef     } }  fragment InputValue on __InputValue {     name     description     type { ...TypeRef }     defaultValue }  fragment TypeRef on __Type {     kind     name     ofType {     kind     name     ofType {     kind     name     ofType {     kind     name     }     }     } }"
    
    
    let parameters: Parameters = [
        "query": introspectionQuery
    ]
    
    
    return Alamofire
        .request("https://search-api-wwe-mock.bamgrid.com/svc/search/v2/graphql",
                 method:.post,
                 parameters:parameters,
                 encoding: JSONEncoding.default)
    
}
