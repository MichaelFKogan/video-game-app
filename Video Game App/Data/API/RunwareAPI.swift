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
    
//    func sendImageToRunware(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        func sendImageToRunware(image: UIImage, galleryVM: GalleryViewModel? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        print("🚀 Sending image to Runware API...") // 👈 show API call started
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert UIImage to Data"])))
            return
        }
        
        let base64String = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64String)"
        
        // Build request payload
        let requestPayload: [[String: Any]] = [
            ["taskType": "authentication", "apiKey": apiKey],
            [
                "taskType": "imageInference",
                "taskUUID": UUID().uuidString,
                
                "model": "bytedance:4@1", // 👈 change if you want a different model
                
                "positivePrompt": "Convert this image to a stylized Grand Theft Auto game art. Keep all facial features, hair style and color, clothing, pose, and background exactly the same. Only transform the rendering style to GTA: cinematic lighting, slightly desaturated colors, and stylized textures typical of GTA art. Preserve proportions, perspective, and all character details exactly.",
                
//                "positivePrompt": "Convert this image into a Studio Ghibli-style illustration. Keep all facial features, hair style and color, clothing, pose, and background exactly the same. Only apply Ghibli-style rendering: soft colors, whimsical shading, cinematic lighting, and hand-painted textures. Preserve proportions, perspective, and all character and environmental details exactly.",
                
                // 👇 FIXED: correct param name
                "referenceImages": [dataURI],
                
                "cfgScale": 1,

            ]
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
                if let url = decoded.data?.first?.imageURL {
                   DispatchQueue.main.async {
                       galleryVM?.addNewImage(url) // automatically update and persist
                   }
                   completion(.success(url))
               } else if let apiError = decoded.errors?.first {
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
