//
//  APIClient.swift
//  NetworkManager
//
//  Created by aman.gupta on 30/07/25.
//

import Foundation

//MARK: 🧩 API Helper
public class APIClient : @unchecked Sendable {
    
    public static let shared = APIClient()
    public var isDebugMode : Bool = false
    private let session: URLSession
    
    private init(session: URLSession = .shared) {
        _ = NetworkReachability.sharedInstance
        self.session = session
    }
    
    //MARK: FOR API REQUEST (GET, POST, PUT, PATCH, DELETE)
    public func request<T: Codable>(
        url: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        parameters: [String:Any]? = nil
    ) async -> Result<FlexibleResponse<T>, Error> {
            if NetworkReachability.sharedInstance.isConnected {
                do {
                    //Check URL
                    guard let url = URL(string: url) else {
                        throw APIError.invalidURL
                    }
                    
                    //Create URL Request
                    var request = URLRequest(url: url)
                    request.httpMethod = method.rawValue
                    
                    if let body = parameters {
                        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
                        request.addValue("application/json", forHTTPHeaderField: "Accept")
                        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                    }
                    
                    //Adding Headers if any
                    headers?.forEach { key, value in
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if self.isDebugMode {
                        if let json = try? JSONSerialization.jsonObject(with: data),
                           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                           let jsonString = String(data: prettyData, encoding: .utf8) {
                            
                            /** API REQUEST AND RESPONSE **/
                            self.printRequest(request, jsonString)
                        }
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.cancelled
                    }
                    
                    //Handling Status Code
                    switch httpResponse.statusCode {
                    case 200...299:
                        
                        //Typed Model Decodable
                        if let model = try? JSONDecoder().decode(T.self, from: data) {
                            return .success(.typed(model))
                        }
                        
                        // Fallback: Try decoding into [String: Any]
                        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                           let dict = json as? [String: Any] {
                            return .success(.raw(dict))
                        }
                        
                        //Invalid Json
                        return .failure(APIError.decodingFailed(NSError(domain: "Invalid JSON", code: 0)))
                    case 401:
                        throw APIError.unauthorized
                    case 403:
                        throw APIError.forbidden
                    case 404:
                        throw APIError.notFound
                    case 500...599:
                        throw APIError.serverError(statusCode: httpResponse.statusCode)
                    default:
                        throw APIError.unknownStatusCode(statusCode: httpResponse.statusCode)
                    }
                } catch let error as APIError {
                    //Catch all API errors
                    return .failure(error)
                } catch {
                    //Catch all other error types (like URLError, DecodingError)
                    return .failure(error)
                }
            }  else {
                return .failure(APIError.noInternet)
            }
        }
    
}

//MARK: 🧩 Multipart Upload Helper
extension APIClient {
    
    func createMultipartBody(
        boundary:String,
        fileDataModel: [MediaUploadModel],
        fileName:String, //For image: image.jpg, For Video: videoUrl.lastPathComponent
        mimeType: String,
        parameters: [String: Any]?
    ) -> Data {
        var body = Data()
        // Add parameters
        parameters?.forEach { key, value in
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8))
            body.append(Data("\(value)\r\n".utf8))
        }

        // Add file
        for fileData in fileDataModel {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(fileData.fileName)\"; filename=\"\(fileName)\"\r\n".utf8))
            body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
            body.append(fileData.mediaData)
            body.append(Data("\r\n".utf8))
        }
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }
    
    
    //MARK: 🧠 Helper to Detect MIME Type
    public func mimeType(for fileName: String) -> String {
        if fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg") {
            return "image/jpeg"
        } else if fileName.hasSuffix(".png") {
            return "image/png"
        } else if fileName.hasSuffix(".mp4") {
            return "video/mp4"
        }
        return "application/octet-stream"
    }
    
    public func uploadMedia<T: Decodable>(
            url: String,
            fileDataModel: [MediaUploadModel],
            fileName:String, //For image: image.jpg, For Video: videoUrl.lastPathComponent
            mimeType: String,
            headers: [String: String]? = nil,
            parameters: [String: Any]? = nil
    ) async -> Result<FlexibleResponse<T>, Error> {
        if NetworkReachability.sharedInstance.isConnected {
            guard let url = URL(string: url) else {
                return .failure(APIError.invalidURL)
            }
            
            let boundary = UUID().uuidString
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            //Adding Headers if any
            headers?.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            // Set headers
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Create the HTTP body
            request.httpBody = createMultipartBody(
                boundary: boundary,
                fileDataModel: fileDataModel,
                fileName: fileName,
                mimeType: mimeType,
                parameters: parameters
            )
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if self.isDebugMode {
                    if let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let jsonString = String(data: prettyData, encoding: .utf8) {
                        
                        /** API REQUEST AND RESPONSE **/
                        self.printRequest(request, jsonString)
                    }
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.cancelled
                }

                //Handling Status Code
                switch httpResponse.statusCode {
                case 200...299:
                    
                    //Typed Model Decodable
                    if let model = try? JSONDecoder().decode(T.self, from: data) {
                        return .success(.typed(model))
                    }
                    
                    // Fallback: Try decoding into [String: Any]
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                       let dict = json as? [String: Any] {
                        return .success(.raw(dict))
                    }
                    
                    //Invalid Json
                    return .failure(APIError.decodingFailed(NSError(domain: "Invalid JSON", code: 0)))
                case 401:
                    throw APIError.unauthorized
                case 403:
                    throw APIError.forbidden
                case 404:
                    throw APIError.notFound
                case 500...599:
                    throw APIError.serverError(statusCode: httpResponse.statusCode)
                default:
                    throw APIError.unknownStatusCode(statusCode: httpResponse.statusCode)
                }
            } catch let error as APIError {
                //Catch all API errors
                return .failure(error)
            } catch {
                //Catch all other error types (like URLError, DecodingError)
                return .failure(error)
            }
        } else {
            return .failure(APIError.noInternet)
        }
    }
}


//MARK: 🧩 Support Functions
extension APIClient {
    
    //MARK: REQUEST PRINTABLE
    func printRequest(_ request: URLRequest, _ response:String) {
        print("📤 REQUEST ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓")
        
        if let method = request.httpMethod {
            print("🔸 Method: \(method)")
        }
        
        if let url = request.url {
            print("🌐 URL: \(url.absoluteString)")
        }
        
        if let headers = request.allHTTPHeaderFields {
            print("📦 Headers:")
            for (key, value) in headers {
                print("   → \(key): \(value)")
            }
        }
        
        if let body = request.httpBody {
            if let json = try? JSONSerialization.jsonObject(with: body, options: []),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let bodyString = String(data: pretty, encoding: .utf8) {
                print("📝 Body:\n\(bodyString)")
            } else if let bodyString = String(data: body, encoding: .utf8) {
                print("📝 Body (raw):\n\(bodyString)")
            } else {
                print("📝 Body: (non-printable binary)")
            }
        } else {
            print("📝 Body: nil")
        }
        print("✅ Response : \n", response)
        print("📤 END REQUEST ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑\n")
    }
    
}
