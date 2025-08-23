//
//  ModelConfiguration.swift
//  Video Game App
//
//  Created by Mike K on 8/17/25.
//

import Foundation

// MARK: - Model Configuration Structure
struct ModelConfiguration {
    let model: String
    let positivePrompt: String
    let cfgScale: Double
    let additionalParameters: [String: Any]
    
    init(
        model: String,
        positivePrompt: String,
        cfgScale: Double = 1.0,
        additionalParameters: [String: Any] = [:]
    ) {
        self.model = model
        self.positivePrompt = positivePrompt
        self.cfgScale = cfgScale
        self.additionalParameters = additionalParameters
    }
}

// MARK: - Model Configuration Library
enum ModelConfigurationLibrary {
    
    // MARK: - Style Configurations
    static func configuration(for style: String) -> ModelConfiguration {
        switch style {
        case "Illustration":
            return illustrationConfiguration
        case "Anime":
            return animeConfiguration
        case "Pixel Art":
            return pixelArtConfiguration
        default:
            return illustrationConfiguration // fallback
        }
    }
    
    // MARK: - Individual Configurations
    
    /// Illustration style configuration
    private static let illustrationConfiguration = ModelConfiguration(
        model: "bytedance:4@1",
        positivePrompt: """
        Convert this image to a stylized game art similar to Grand Theft Auto. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style similar to GTA: cinematic lighting, slightly desaturated colors, stylized textures. Do not add or remove any objects or people. Keep the scene exactly as-is.
        """,
        cfgScale: 1.0,
        additionalParameters: [:]
            // Add any additional parameters specific to Illustration style
            // "parameterName": "value"
    )
    
    /// Anime style configuration
    private static let animeConfiguration = ModelConfiguration(
        model: "bytedance:3@1", // Using a different model for anime style
        positivePrompt: """
        Convert this image into stylized anime art similar to Studio Ghibli. Preserve the exact composition, existing subjects, background, proportions, and perspective. Only change the rendering style similar to Studio Ghibli: soft colors, whimsical shading, cinematic lighting, and hand-painted textures. Do not add or remove any objects or people. Keep the scene exactly as-is.
        """,
        cfgScale: 1.2, // Slightly higher CFG for more stylized results
        additionalParameters: [:]
            // Add any additional parameters specific to Anime style
            // "parameterName": "value"
    )
    
    // MARK: - Additional Style Configurations (for future use)
    
    /// Portrait Anime configuration (if you want to add it later)
    static let portraitAnimeConfiguration = ModelConfiguration(
        model: "bytedance:4@1", // You can use a different model for portraits
        positivePrompt: """
        Convert this portrait into a Studio Ghibli-style character illustration. Enhance facial features with detailed anime-style rendering: large expressive eyes, soft skin textures, natural hair flow, and gentle facial proportions. Apply Ghibli-style lighting with warm, natural tones and subtle shadows. Preserve all facial features, hair style and color, clothing, and pose exactly as they are.
        """,
        cfgScale: 1.1,
        additionalParameters: [:]
            // Portrait-specific parameters
    )
    
    /// Cinematic Portrait configuration
    static let cinematicPortraitConfiguration = ModelConfiguration(
        model: "bytedance:4@1",
        positivePrompt: """
        Convert this portrait into a Hollywood-style cinematic character shot. Enhance facial features with dramatic lighting, professional photography techniques, and cinematic color grading. Apply movie-style rendering with rich shadows, highlights, and professional portrait lighting. Preserve all facial features, hair style and color, clothing, and pose exactly as they are.
        """,
        cfgScale: 1.0,
        additionalParameters: [:]
            // Cinematic-specific parameters
    )
    
    /// Pixel Art configuration (example of using a different model)
    private static let pixelArtConfiguration = ModelConfiguration(
        model: "bytedance:3@1", // Different model for pixel art
        positivePrompt: """
        Convert this image into a retro pixel art style. Use limited color palette, sharp pixel edges, and classic 8-bit or 16-bit video game aesthetics. Preserve the composition and subjects but render everything in a pixelated style with clear, distinct pixels. Do not add or remove objects.
        """,
        cfgScale: 1.5, // Higher CFG for more stylized pixel art
        additionalParameters: [:]
            // Pixel art specific parameters could go here
            // "steps": 30,
            // "sampler": "euler_a"
    )
}

// MARK: - Available Models Reference
enum AvailableModels {
    // Bytedance models
    static let bytedance4 = "bytedance:4@1"
    static let bytedance3 = "bytedance:3@1"
    
    // Add other models as needed
    // static let stableDiffusionXL = "stability-ai:stable-diffusion-xl-1024-v1-0"
    // static let midjourney = "midjourney:latest"
    
    // Example of how to add more models:
    // static let openjourney = "prompthero:openjourney"
    // static let anythingV3 = "cjwbw:anything-v3.0"
    // static let dreamShaper = "lykon:dream-shaper"
    
    // You can add more models here and reference them in configurations
}
