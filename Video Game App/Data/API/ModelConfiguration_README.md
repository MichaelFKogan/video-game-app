# Model Configuration System

This system allows you to easily configure different AI models and parameters for different image styles in your app.

## How It Works

1. **ModelConfiguration.swift** - Contains all model configurations and parameters
2. **RunwareAPI.swift** - Updated to use the configuration system
3. **CameraButtonView.swift** - Updated to pass the selected style

## Adding a New Style

### Step 1: Add the style to your UI
In `CameraButtonView.swift`, add your new style to the `environmentStyles` array:

```swift
let environmentStyles = [
    ("Illustration", "$0.03", "🎮", "Painted, stylized"),
    ("Anime", "$0.03", "💫", "Bright, hand-drawn"),
    ("Pixel Art", "$0.03", "👾", "Retro, pixelated") // New style
]
```

### Step 2: Add the configuration
In `ModelConfiguration.swift`, add a new case to the `configuration(for:)` method:

```swift
static func configuration(for style: String) -> ModelConfiguration {
    switch style {
    case "Illustration":
        return illustrationConfiguration
    case "Anime":
        return animeConfiguration
    case "Pixel Art": // New case
        return pixelArtConfiguration
    default:
        return illustrationConfiguration
    }
}
```

### Step 3: Create the configuration
Add your new configuration:

```swift
private static let pixelArtConfiguration = ModelConfiguration(
    model: "bytedance:3@1", // Choose your model
    positivePrompt: """
    Your custom prompt here...
    """,
    cfgScale: 1.5, // Adjust CFG scale
    additionalParameters: [
        // Add any additional parameters
        // "steps": 30,
        // "sampler": "euler_a"
    ]
)
```

## Available Models

You can use different models by referencing them in your configurations:

```swift
// In AvailableModels enum:
static let bytedance4 = "bytedance:4@1"
static let bytedance3 = "bytedance:3@1"
// Add more models as needed
```

## Parameters You Can Configure

- **model**: The AI model to use (e.g., "bytedance:4@1")
- **positivePrompt**: The style prompt for the AI
- **cfgScale**: Controls how closely the AI follows the prompt (1.0-2.0)
- **additionalParameters**: Any other parameters specific to the model

## Example: Different Models for Different Styles

```swift
// Illustration style - uses bytedance:4@1
private static let illustrationConfiguration = ModelConfiguration(
    model: "bytedance:4@1",
    positivePrompt: "Convert to GTA-style art...",
    cfgScale: 1.0
)

// Anime style - uses bytedance:3@1 (different model)
private static let animeConfiguration = ModelConfiguration(
    model: "bytedance:3@1",
    positivePrompt: "Convert to Studio Ghibli style...",
    cfgScale: 1.2
)
```

## Testing Custom Prompts

The system also supports custom prompts through the UI. When a user enters a custom prompt, it uses a default configuration but with their custom prompt text.

## Benefits

1. **Separation of Concerns**: Model configurations are separate from API logic
2. **Easy to Add New Styles**: Just add a new configuration
3. **Different Models per Style**: Each style can use a different AI model
4. **Flexible Parameters**: Easy to adjust CFG scale and other parameters per style
5. **Maintainable**: All configurations in one place
