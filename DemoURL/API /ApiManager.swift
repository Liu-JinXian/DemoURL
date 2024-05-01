//
//  ApiManager.swift
//  DemoURL
//
//  Created by 劉晉賢 on 2024/5/1.
//
import Foundation
import RxSwift
import Alamofire

class ApiManager {
    static let shared = ApiManager()
    
    private lazy var requestManager: Session = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        return Session(configuration: config)
    }()
    
    private let dispose = DisposeBag()
    
    func mangers<T: Decodable> (object: T.Type, method: HTTPMethod, appendUrl: String = "", url: String, parameters: [String: Any]? = nil, appendHeaders: [String: String]? = nil) -> Single<T?> {
        
        return Single.create { (single) ->  Disposable in
            let param = parameters ?? [String: Any]()
            let header: HTTPHeaders = self.getHttpHeader(method: method, appendHeaders: appendHeaders)
            let requestUrl: String = url
            let encode: ParameterEncoding = self.getEncodeWith(method: method)
            self.printRequest(requestUrl, header, param)
            
            self.requestManager.request(URL(string: requestUrl)!,
                                        method: method,
                                        parameters: param,
                                        encoding: encode,
                                        headers: header
            )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let model = try decoder.decode(T.self, from: data)
                        self.printResponse(requestUrl, data)
                        single(.success(model))
                    }catch {
                        print(error.localizedDescription)
                        single(.success(nil))
                    }
                case .failure(let error):
                    print("API ERROR -> \(error)")
                    single(.error(error))
                }
            }
            return Disposables.create()
        }
    }
    
    func getStructJson<T: Decodable> (object: T.Type, forResource: String) -> Single<T?> {
        
        let testBundle = Bundle.main
        
        // load mock json file
        let path = testBundle.path(forResource: forResource, ofType: "json")!
        
        do{
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            let model = try decoder.decode(T.self, from: jsonData)
            self.printResponse("Json", model)
            return Single.just(model)
        }catch {
            print("No save file")
        }
        
        //should not get in here
        return Single.error(NSError(domain: "getJSon", code: 0, userInfo: [:]))
    }
}

extension ApiManager {
    private func getHttpHeader(method: HTTPMethod, appendHeaders: [String: String]?) -> HTTPHeaders {
        var headers: HTTPHeaders = []
        
        switch method {
        case .get:
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        case .post:
            headers["Content-Type"] = "application/json"
        default:
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        }
        
        return headers
    }
    
    private func printRequest(_ requestUrl: String, _ headers: HTTPHeaders, _ params: [String: Any]) {
        print("-------------------------------------------------------")
        print("* 【呼叫】 The_requestUrl : \(requestUrl)")
        print("* 【呼叫】 Req∂uest_headers : ")
        headers.forEach({ header in
            print(header)
        })
        
        print("* 【呼叫】 Request_params : ")
        print(params)
        print(getPrettyParams(params) ?? "")
    }
    
    private func printResponse(_ requestUrl: String,_ value: (Any)){
        
        print("-------------------------------------------------------")
        print("* 【回應】 The_requestUrl : \(requestUrl)")
        print("* 【回應】 Response_value : ")
        //        if requestUrl.contains("Common/Zone") { return }
        print(getPrettyPrint(value))
    }
    
    private func getEncodeWith(method: HTTPMethod) -> ParameterEncoding {
        switch method {
        case .get:
            return URLEncoding.default
            
        case .post:
            return JSONEncoding.default
            
        default:
            return URLEncoding.default
        }
    }
    
    private func getPrettyParams(_ dict: [String: Any]) -> NSString? {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        return NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
    }
    
    private func getPrettyPrint(_ responseValue: Any) -> String {
        var string: String = ""
        if (responseValue is Data ) == false { return string }
        if let json = try? JSONSerialization.jsonObject(with: responseValue as! Data, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            string = (String(decoding: jsonData, as: UTF8.self))
        } else {
            print("json data malformed")
        }
        return string
    }
}
