//
//  PromptLibrary.swift
//  Video Game App
//
//  Created by Mike K on 8/23/25.
//

// PromptLibrary.swift
import Foundation

enum PromptLibrary {
    // Stable/production prompts
    private static let map: [String: String] = [
        "Illustration": """
        Convert this image to a stylized game art similar to Grand Theft Auto. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style similar to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is.
        """,
        "Anime": """
        Become an anime image
        """
    ]

    // Fallback if style isn’t found
    private static let fallback = """
    Convert this image to a stylized game art similar to Grand Theft Auto. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style similar to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is.
    """

    /// Get the positive prompt for a style name.
    static func positivePrompt(for style: String) -> String {
        map[style] ?? fallback
    }

    // ⬇️ Keep all your extra testing variants here (not in the API file)
    // #if DEBUG
    // static let experimental: [String: [String]] = [
    //     "Anime": [
    //         "Convert this image into stylized anime art similar to Studio Ghibli. Preserve the exact composition...",
    //         "Convert this image into a Japanese Manga style illustration. Apply hand painted textures..."
    //     ],
    //     "Illustration Portrait": [
    //         "Convert this portrait to a cinematic illustration. Preserve identity..."
    //     ]
    // ]
    // #endif
}








//switch style {
//    
//case "Illustration":
//    positivePrompt = "Convert this image to a stylized game art similar to Grand Theft Auto. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style similar to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is."
//
////        case "Anime":
////            positivePrompt = "Convert this image into stylized anime art similar to Studio Ghibli. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style similar to Studio Ghibli. Do not add or remove any objects or people. Keep the scene exactly as-is."
//    
//case "Anime":
//    positivePrompt = "Become an anime image"
//
////            Convert this portrait to an anime style while preserving identity. Use natural facial proportions, expressive eyes, soft skin, and natural hair. Keep age, skin tone, hairstyle, clothing, pose, and lighting consistent. Maintain composition and perspective. Do not add or remove people, text, or objects.
//
//    
////        case "Anime":
////            positivePrompt =
////            "Convert this image into a Japanese Manga style illustration. Apply hand painted textures, soft shading, and warm lighting. Keep composition, perspective, subjects, and colors the same. Do not add or remove objects. If faces are present, do not enhance or restyle them."
//    
////        case "Illustration Portrait":
////            positivePrompt =
////            "Convert this portrait to a cinematic illustration. Preserve identity, age, skin tone, hairstyle, clothing, pose, and expression. Use professional portrait lighting with rich highlights and shadows and natural color grading. Keep composition and perspective unchanged. Do not add or remove people, text, or objects."
//    
////        case "Anime Portrait":
////            positivePrompt =
////            "Convert this portrait to an anime style while preserving identity. Use natural facial proportions, expressive eyes, soft skin, and natural hair. Keep age, skin tone, hairstyle, clothing, pose, and lighting consistent. Maintain composition and perspective. Do not add or remove people, text, or objects."
//
//default:
//    positivePrompt = "Convert this image to a stylized game art similar to Grand Theft Auto. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style similar to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is."
//}
//
////        switch style {
////        // Environment-focused styles
////        case "Anime":
////            positivePrompt = "Convert this image into a Studio Ghibli-style illustration. Keep all facial features, hair style and color, clothing, pose, and background exactly the same. Only apply Ghibli-style rendering: soft colors, whimsical shading, cinematic lighting, and hand-painted textures. Preserve proportions, perspective, and all character and environmental details exactly."
////        case "Cinematic Game Art":
////            positivePrompt = "Convert this image to a stylized Grand Theft Auto game art. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is."
////
////        // Face-focused styles (more detailed prompts for portraits)
////        case "Portrait Anime":
////            positivePrompt = "Convert this portrait into a Studio Ghibli-style character illustration. Enhance facial features with detailed anime-style rendering: large expressive eyes, soft skin textures, natural hair flow, and gentle facial proportions. Apply Ghibli-style lighting with warm, natural tones and subtle shadows. Preserve all facial features, hair style and color, clothing, and pose exactly as they are."
////        case "Cinematic Portrait":
////            positivePrompt = "Convert this portrait into a Hollywood-style cinematic character shot. Enhance facial features with dramatic lighting, professional photography techniques, and cinematic color grading. Apply movie-style rendering with rich shadows, highlights, and professional portrait lighting. Preserve all facial features, hair style and color, clothing, and pose exactly as they are."
////        default:
////            positivePrompt = "Convert this image to a stylized Grand Theft Auto game art. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is."
////        }
