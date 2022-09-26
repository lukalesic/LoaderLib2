//
//  Loader.swift
//  LoaderPrototype5
//
//  Created by Luka Lešić on 15.09.2022..
//

import Foundation
import SwiftUI
import Dispatch


private enum ImageStatus {
    case inProgress(Task<UIImage, Error>)
    case fetched(UIImage)
    case failure(Error)
}

enum InternetError: Error {
    case noInternet
    case invalidServerResponse
    
    var description: String? {
        switch self {
        case .noInternet:
             return NSLocalizedString("No Internet connection available.", comment: "")
        case .invalidServerResponse:
             return NSLocalizedString("Invalid server response.", comment: "")
        }
    }
}

actor Loader{
    
   private var images: [URLRequest: ImageStatus] = [:]
    let imageCache = NSCache<AnyObject, AnyObject>()
    let session: URLSession = .shared
    
    let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        return queue
    }()

    @Published private(set) var error: InternetError?
    @Published var hasError = false
    @Published var networkAlertShown = false
    
    public func loadImage(url: URL) async throws -> UIImage {
        let request = URLRequest(url: url)
        return try await loadImage(request)
    }
    
 
    public func loadImage(_ request: URLRequest) async throws -> UIImage {
        switch images[request] {
        case .fetched(let image):
            self.imageCache.setObject(image, forKey: request as AnyObject)
            return image

        case .inProgress(let task):
            return try await task.value

        case .failure(let error):
            throw error

        case nil:
            let task: Task<UIImage, Error> = Task {
                try await withCheckedThrowingContinuation { continuation in
                    let operation = ImageRequestOperation(session: session, request: request) { [weak self] result in
                        DispatchQueue.main.async {
                            switch result {
                            case .failure(let error):
                                continuation.resume(throwing: error)

                            case .success(let image):
                                continuation.resume(returning: image)
                            }
                        }
                    }

                    queue.addOperation(operation)
                }
            }

            images[request] = .inProgress(task)

            return try await task.value
        }
    }
    
  
    class ImageRequestOperation: DataRequestOperation {
        init(session: URLSession, request: URLRequest, completionHandler: @escaping (Result<UIImage, Error>) -> Void) {
            super.init(session: session, request: request) { result in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async { completionHandler(.failure(error))
                        let image = UIImage(systemName: "wifi.exclamationmark")!
                    }

                case .success(let data):
                    guard let image = UIImage(data: data) else {
                        DispatchQueue.main.async { completionHandler(.failure(URLError(.badServerResponse))) }
                        return
                    }
                    DispatchQueue.main.async { completionHandler(.success(image)) }
                }
            }
        }
    }

    class DataRequestOperation: AsynchronousOperation {
        private var task: URLSessionDataTask!

        init(session: URLSession, request: URLRequest, completionHandler: @escaping (Result<Data, Error>) -> Void) {
            super.init()

            task = session.dataTask(with: request) { data, response, error in
                guard
                    let data = data,
                    let response = response as? HTTPURLResponse,
                    200 ..< 300 ~= response.statusCode
                else {
                    completionHandler(.failure(error ?? URLError(.badServerResponse)))
                    return
                }

                completionHandler(.success(data))

                self.finish()
            }
        }

        override func main() {
            task.resume()
        }

        override func cancel() {
            super.cancel()

            task.cancel()
        }
    }
    
    class AsynchronousOperation: Operation {
        enum OperationState: Int {
            case ready
            case executing
            case finished
        }

        @Atomic var state: OperationState = .ready {
            willSet {
                willChangeValue(forKey: #keyPath(isExecuting))
                willChangeValue(forKey: #keyPath(isFinished))
            }

            didSet {
                didChangeValue(forKey: #keyPath(isFinished))
                didChangeValue(forKey: #keyPath(isExecuting))
            }
        }

        override var isReady: Bool        { state == .ready && super.isReady }
        override var isExecuting: Bool    { state == .executing }
        override var isFinished: Bool     { state == .finished }
        override var isAsynchronous: Bool { true }

        override func start() {
            if isCancelled {
                state = .finished
                return
            }

            state = .executing

            main()
        }


        override func main() {
            assertionFailure("The `main` method should be overridden in concrete subclasses of this abstract class.")
        }

        func finish() {
            state = .finished
        }
    }

    
    @propertyWrapper
    struct Atomic<T> {
        var _wrappedValue: T
        let lock = NSLock()

        var wrappedValue: T {
            get { synchronized { _wrappedValue } }
            set { synchronized { _wrappedValue = newValue } }
        }

        init(wrappedValue: T) {
            _wrappedValue = wrappedValue
        }

        func synchronized<T>(block: () throws -> T) rethrows -> T {
            lock.lock()
            defer { lock.unlock() }
            return try block()
        }
    }
}

