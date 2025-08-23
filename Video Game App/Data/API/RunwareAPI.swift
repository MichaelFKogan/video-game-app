//
//  RunwareAPI.swift
//  Video Game App
//
//  Created by Mike K on 8/17/25.
//

import Foundation
import UIKit

struct RunwareResponse: Codable {
    
    struct DataItem: Codable {
        let taskType: String
        let taskUUID: String
        let imageUUID: String?
        let imageURL: String?
        let cost: Double?
    }
    struct APIError: Codable {
        let code: String
        let message: String
    }
    let data: [DataItem]?
    let errors: [APIError]?
}


class RunwareAPI {
    private let apiKey = "ULNV1WkcDIUf48rxv7GQwTxUz4wckbWr" // 🔑 put your real key here
    
    func sendImageToRunware(image: UIImage, style: String = "Pixel Art", galleryVM: GalleryViewModel? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        print("🚀 Sending image to Runware API...") // 👈 show API call started
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert UIImage to Data"])))
            return
        }
        
        let base64String = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64String)"
        
        // Get model configuration for the selected style
        let config = ModelConfigurationLibrary.configuration(for: style)
        
        print("🎨 Using style: \(style)")
        print("🤖 Model: \(config.model)")
        print("📝 Prompt: \(config.positivePrompt)")
        print("⚙️ CFG Scale: \(config.cfgScale)")
        
        // Build request payload with configuration
        var inferencePayload: [String: Any] = [
            "taskType": "imageInference",
            "taskUUID": UUID().uuidString,
            "model": config.model,
            "positivePrompt": config.positivePrompt,
            "referenceImages": [dataURI],
            "CFGScale": config.cfgScale,
            "includeCost": true
        ]
        
        // Add any additional parameters from configuration
        for (key, value) in config.additionalParameters {
            inferencePayload[key] = value
        }
        
        let requestPayload: [[String: Any]] = [
            ["taskType": "authentication", "apiKey": apiKey],
            inferencePayload
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestPayload) else {
            completion(.failure(NSError(domain: "JSONError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not encode JSON"])))
            return
        }
        
        var request = URLRequest(url: URL(string: "https://api.runware.ai/v1")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -3, userInfo: nil)))
                return
            }
            
            // 👇 Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📩 Runware raw response:\n\(jsonString)")
            }
            
            do {
                let decoded = try JSONDecoder().decode(RunwareResponse.self, from: data)

                if let item = decoded.data?.first {
                    if let cost = item.cost {
                        let asDollars = String(format: "%.4f", cost)
                        print("💵 Runware cost: $\(asDollars)")
                    }

                    if let url = item.imageURL {
                        DispatchQueue.main.async {
                            galleryVM?.addNewImage(url)
                        }
                        completion(.success(url))
                        return
                    }
                }

                if let apiError = decoded.errors?.first {
                    completion(.failure(NSError(domain: "RunwareError", code: -4, userInfo: [NSLocalizedDescriptionKey: apiError.message])))
                } else {
                    completion(.failure(NSError(domain: "RunwareError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])))
                }
            } catch {
                print("❌ JSON decode failed: \(error)")
                completion(.failure(error))
            }

        }.resume()
    }
    
    // MARK: - Alternative method for custom configurations
    func sendImageToRunwareWithConfig(image: UIImage, config: ModelConfiguration, galleryVM: GalleryViewModel? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        print("🚀 Sending image to Runware API with custom config...")
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert UIImage to Data"])))
            return
        }
        
        let base64String = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64String)"
        
        print("🤖 Model: \(config.model)")
        print("📝 Prompt: \(config.positivePrompt)")
        print("⚙️ CFG Scale: \(config.cfgScale)")
        
        // Build request payload with custom configuration
        var inferencePayload: [String: Any] = [
            "taskType": "imageInference",
            "taskUUID": UUID().uuidString,
            "model": config.model,
            "positivePrompt": config.positivePrompt,
            "referenceImages": [dataURI],
            "CFGScale": config.cfgScale,
            "includeCost": true
        ]
        
        // Add any additional parameters from configuration
        for (key, value) in config.additionalParameters {
            inferencePayload[key] = value
        }
        
        let requestPayload: [[String: Any]] = [
            ["taskType": "authentication", "apiKey": apiKey],
            inferencePayload
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestPayload) else {
            completion(.failure(NSError(domain: "JSONError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not encode JSON"])))
            return
        }
        
        var request = URLRequest(url: URL(string: "https://api.runware.ai/v1")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -3, userInfo: nil)))
                return
            }
            
            // Print raw response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📩 Runware raw response:\n\(jsonString)")
            }
            
            do {
                let decoded = try JSONDecoder().decode(RunwareResponse.self, from: data)

                if let item = decoded.data?.first {
                    if let cost = item.cost {
                        let asDollars = String(format: "%.4f", cost)
                        print("💵 Runware cost: $\(asDollars)")
                    }

                    if let url = item.imageURL {
                        DispatchQueue.main.async {
                            galleryVM?.addNewImage(url)
                        }
                        completion(.success(url))
                        return
                    }
                }

                if let apiError = decoded.errors?.first {
                    completion(.failure(NSError(domain: "RunwareError", code: -4, userInfo: [NSLocalizedDescriptionKey: apiError.message])))
                } else {
                    completion(.failure(NSError(domain: "RunwareError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])))
                }
            } catch {
                print("❌ JSON decode failed: \(error)")
                completion(.failure(error))
            }

        }.resume()
    }
}
