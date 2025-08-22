import SwiftUI
import Combine

class CameraViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var category: String = "Daily Entry"
    
    @Published var galleryImages: [String] = []
    
    // API Key for Runware
    private let apiKey = "YOUR_API_KEY"
    
    func generateImage(withImage image: UIImage, prompt: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            print("Failed to convert image to JPEG data")
            return
        }
        
        let base64String = imageData.base64EncodedString()
        
        // Payload for Runware API
        let task: [String: Any] = [
            "taskType": "imageInference",
            "model": "bytedance:4@1",
            "positivePrompt": prompt,
            "numberResults": 1,
            "outputType": ["dataURI", "URL"],
            "outputFormat": "JPEG",
            "CFGScale": 1,
            "includeCost": true,
            "referenceImages": [base64String],
            "outputQuality": 85
        ]
        
        let payload = [
            ["taskType": "authentication", "apiKey": apiKey], // optional if using headers
            task
        ]
        
        guard let url = URL(string: "https://api.runware.ai/v1") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("Error serializing payload:", error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Runware API error:", error)
                return
            }
            
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = (json["data"] as? [[String: Any]])?.filter({ $0["taskType"] as? String == "imageInference" }),
                   let firstResult = results.first,
                   let urlString = firstResult["imageURL"] as? String {
                    
                    DispatchQueue.main.async {
                        self.galleryImages.insert(urlString, at: 0)
                    }
                } else {
                    print("No results found or API returned error:", String(data: data, encoding: .utf8) ?? "")
                }
            } catch {
                print("Error parsing Runware response:", error)
            }
        }.resume()
    }
}
