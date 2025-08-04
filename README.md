# NetworkManager

A lightweight Swift Package for handling API requests.

## 🚀 Features

- Simple API Client interface
- Support for GET, POST, PUT, DELETE
- Handles JSON encoding/decoding
- Configurable headers and parameters
- Lightweight and dependency-free

## 📦 Installation (Swift Package Manager)

### Xcode
1. Open your Xcode project
2. Go to `File > Add Packages`
3. Enter the repository URL:

https://github.com/your-username/NetworkManager.git

4. Select the version/range and add the package.

### Manual (Package.swift)

If you’re using `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/NetworkManager.git", from: "1.0.0")
]
```

## 🚀 Helper Class

Add the following file in your code and named `NetworkManagerHelper.swift`


```swift
import Foundation
import NetworkManager
import Combine

class NetworkManagerHelper {
    
    //Shared Object
    static let shared = NetworkManagerHelper()
    private init() { }
    
    //MARK: Published variables
    @Published var isInternetConnected : Bool = false
    var cancellabne : [AnyCancellable] = []
    
    //MARK: Check if internet is connected or not everytime once network is changed.
    func checkInternetConnected() {
        NetworkReachability.sharedInstance.$isConnected
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink(receiveValue: { isConnected in
                self.isInternetConnected = isConnected
                print(isConnected ? "🟢 Connected" : "🔴 Disconnected")
            })
            .store(in: &cancellabne)
    }

    //MARK: Enable Debug Mode for API CALL
    func enableDebugMode(_ enable:Bool) {
        //To Enable Debugging: Pass true
        APIClient.shared.isDebugMode = enable
    }
    
    //MARK: API Request For Codaable Model
    func requestAPI<T:Codable>(url: String, method:HTTPMethod, headers:[String:String]? = nil, parameters: [String:Any]? = nil) async -> T? {
        let result: Result<FlexibleResponse<T>, Error>? = await APIClient.shared.request(url: url, method: method, headers: headers, parameters: parameters)
        switch result {
        case .success(.typed(let response)):
            print("Typed: ", response)
            return response
        case .success(.raw(let dict)):
            print("Raw JSON: ", dict)
            return nil
        case .failure(let error) :
            self.errorHandler(error)
            return nil
        default :
            print("UNKNOWN")
            return nil
        }
    }
    
    //MARK: API Request For Media
    func requestMediaUplaodAPI<T:Codable>(url: String, fileDataModel:[MediaUploadModel], fileName: String, mimeType: String, headers:[String:String]? = nil, parameters: [String:Any]? = nil) async -> T? {
        let result: Result<FlexibleResponse<T>, Error>? = await APIClient.shared.uploadMedia(url: url, fileDataModel: fileDataModel, fileName: fileName, mimeType: mimeType, headers: headers, parameters: parameters)
        switch result {
        case .success(.typed(let response)):
            print("Typed: ", response)
            return response
        case .success(.raw(let dict)):
            print("Raw JSON: ", dict)
            return nil
        case .failure(let error) :
            self.errorHandler(error)
            return nil
        default :
            print("UNKNOWN")
            return nil
        }
    }
    
    //MARK: Error Handler
    func errorHandler(_ error : Error) {
        if let error = error as? APIError {
            switch error {
            case .invalidURL:
                print("THE URL PROVIDED IS INVALID")
            case .requestFailed(let error):
                print("REQUEST FAILED WITH ERROR: \(error.localizedDescription)")
            case .noData:
                print("NO DATA WAS RECEIVED FROM SERVER")
            case .decodingFailed(let error):
                print("FAILED TO DECODE RESPONSE. ERROR: \(error.localizedDescription)")
            case .unauthorized:
                print("UNAUTHORIZED ACCESS. PLEASE LOGIN IN AGAIN")
            case .forbidden:
                print("YOU DO NOT PERMISSION TO ACCESS THE RESOURCES")
            case .notFound:
                print("THE REQUESTED RESOURCES WAS NOT FOUND")
            case .serverError(statusCode: let statusCode):
                print("SERVER ERROR WITH STATUS CODE: \(statusCode)")
            case .unknownStatusCode(statusCode: let statusCode):
                print("RECEIVE UNKNOWN STATUS CODE: \(statusCode)")
            case .timeout:
                print("THE REQUEST TIMED OUT")
            case .noInternet:
                print("NO INTERNET CONNECTION")
            case .cancelled:
                print("REQUEST IS CANCELLED")
            default:
                print("DEFAULT")
            }
        } else {
            print("UNKNOWN")
        }
    }
    
}
```

## 🚀 Usage Class

        Task {
            guard let result : ResponseModel = await helper.requestAPI(url: "URL", method: .get) else { return }
            print("Result: ", result)
        }
