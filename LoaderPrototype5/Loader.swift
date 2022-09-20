//
//  Loader.swift
//  LoaderPrototype5
//
//  Created by Luka Lešić on 15.09.2022..
//

import Foundation
import SwiftUI

private enum ImageStatus {
      case inProgress(Task<UIImage, Error>)
      case fetched(UIImage)
      case failed(Error)
  }

enum InternetError: Error {
    case noInternet
    case invalidServerResponse
}

actor Loader{
    private var images: [URLRequest: ImageStatus] = [:]
    let queue = DispatchQueue.global(qos: .background)
    let semaphore = DispatchSemaphore(value: 3)
    let imageCache = NSCache<AnyObject, AnyObject>()
    //var error = false
    
    public func loadImage(url: URL) async throws -> UIImage {
        let request = URLRequest(url: url)
        return try await loadImage(request)
    }
    
    public func loadImage(_ urlRequest: URLRequest) async throws -> UIImage {
        if let status = images[urlRequest]{
            switch status{
            case .fetched(let image):
                        return image
            case .inProgress(let task):
                        return try await task.value
            case .failed(_): images.removeValue(forKey: urlRequest)
            }
        }
        
     
        let task: Task<UIImage, Error> = Task {
            do {
                let (imageData, response) = try await URLSession.shared.data(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 else {
                    throw InternetError.invalidServerResponse
                  }
                
                guard let image = UIImage(data: imageData) else {
                    throw InternetError.noInternet
                }
                return image
          
            } catch {
                throw InternetError.noInternet
            }
        }
        
                
        do{
            images[urlRequest] = .inProgress(task)
            var image = try await task.value
            if let imageFromCache = imageCache.object(forKey: urlRequest as AnyObject) as? UIImage {
                image = imageFromCache
                return image
            }
            images[urlRequest] = .fetched(image)
            //storing image in cache
            imageCache.setObject(image, forKey: urlRequest as AnyObject)
            return image
        }
        catch InternetError.noInternet{
            print("Error displaying images")
            let image = UIImage(systemName: "wifi.exclamationmark")!
            return image
        }
         
    }
}
