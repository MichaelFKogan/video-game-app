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
        
        // Select prompt based on style
        let positivePrompt: String
        switch style {
        // Environment-focused styles
        case "Anime":
            positivePrompt = "Convert this image into a Studio Ghibli-style illustration. Keep all facial features, hair style and color, clothing, pose, and background exactly the same. Only apply Ghibli-style rendering: soft colors, whimsical shading, cinematic lighting, and hand-painted textures. Preserve proportions, perspective, and all character and environmental details exactly."
        case "Watercolor":
            positivePrompt = "Convert this image into a beautiful watercolor painting. Keep all facial features, hair style and color, clothing, pose, and background exactly the same. Only apply watercolor-style rendering: soft, flowing colors, gentle brush strokes, and translucent paint effects. Preserve proportions, perspective, and all character and environmental details exactly."
        case "Cyberpunk":
            positivePrompt = "Convert this image into a cyberpunk aesthetic. Keep all facial features, hair style and color, clothing, pose, and background exactly the same. Only apply cyberpunk-style rendering: neon lighting, futuristic color palette, digital glitch effects, and high-tech atmosphere. Preserve proportions, perspective, and all character and environmental details exactly."
        case "Cinematic Game Art":
            positivePrompt = "Convert this image to a stylized Grand Theft Auto game art. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is."
            
        // Face-focused styles (more detailed prompts for portraits)
        case "Portrait Anime":
            positivePrompt = "Convert this portrait into a Studio Ghibli-style character illustration. Enhance facial features with detailed anime-style rendering: large expressive eyes, soft skin textures, natural hair flow, and gentle facial proportions. Apply Ghibli-style lighting with warm, natural tones and subtle shadows. Preserve all facial features, hair style and color, clothing, and pose exactly as they are."
        case "Fantasy Portrait":
            positivePrompt = "Convert this portrait into a magical fantasy character illustration. Enhance facial features with ethereal lighting, mystical glow effects, and enchanted textures. Apply fantasy-style rendering with soft, magical colors, gentle shadows, and otherworldly atmosphere. Preserve all facial features, hair style and color, clothing, and pose exactly as they are."
        case "Cinematic Portrait":
            positivePrompt = "Convert this portrait into a Hollywood-style cinematic character shot. Enhance facial features with dramatic lighting, professional photography techniques, and cinematic color grading. Apply movie-style rendering with rich shadows, highlights, and professional portrait lighting. Preserve all facial features, hair style and color, clothing, and pose exactly as they are."
        case "Artistic Portrait":
            positivePrompt = "Convert this portrait into a classical artistic masterpiece. Enhance facial features with traditional painting techniques, artistic lighting, and sophisticated color palette. Apply classical portrait rendering with refined brushwork, elegant shadows, and timeless artistic style. Preserve all facial features, hair style and color, clothing, and pose exactly as they are."
            
        default:
            positivePrompt = "Convert this image to a stylized Grand Theft Auto game art. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is."
        }
        
        print("🎨 Using style: \(style) with prompt: \(positivePrompt)")
        
        // Build request payload
        let requestPayload: [[String: Any]] = [
            ["taskType": "authentication", "apiKey": apiKey],
            [
                "taskType": "imageInference",
                "taskUUID": UUID().uuidString,
                
                "model": "bytedance:4@1", // 👈 change if you want a different model
                "positivePrompt": positivePrompt,
                // 👇 FIXED: correct param name
                "referenceImages": [dataURI],
                "CFGScale": 1,
                "includeCost": true,

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
