import Foundation
import Alamofire
import Commander
import Mapper



public func graphQLDescriptionFrom(result: Alamofire.Result<Any>) -> Result<GraphQLTypeDescription>? {
    guard result.error == nil else {
        // got an error in getting the data, need to handle it
        print(result.error!)
        return .failure(result.error!)
    }
    
    // make sure we got JSON and it's a dictionary
    if let json = result.value as? NSDictionary  {
        // turn JSON in to Todo object
        if let todo = GraphQLTypeDescription.from( json)  {
             return .success(todo)
        }
    }
    return nil
}

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
