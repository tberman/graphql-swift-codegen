import Foundation
import Alamofire
import Commander
import Unbox





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
    
    print("url:",url)
    buildRequest(url:url).responseJSON { response in
        print("Request: \(String(describing: response.request))")   // original url request
        print("Response: \(String(describing: response.response))") // http url response
        print("Result: \(response.result)")                         // response serialization result
        
        if let result = response.result.value {
            let json = result as! UnboxableDictionary
            print("JSON: \(json)") // serialized json response
            
            
            let  _ = try? Unboxer.performCustomUnboxing(dictionary: json, closure: { unboxer in
                do{
                    let qry  = try IntrospectionQueryResponse(unboxer:unboxer)
                    print("qry:",qry)
                }
                catch let error{
                    print("Error: incorrect response :",error)
                }
                exit(0)
            })
         
        }else{
            print("FAIL!!!")
        }
      
    }
   
    
       dispatchMain()


}.run()


