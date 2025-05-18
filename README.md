# ProseKey AI

## App Store
[![Download on the App Store](https://img.shields.io/badge/App%20Store-Download-blue?logo=apple)](https://apps.apple.com/us/app/prosekey-ai/id6741180175)

## TestFlight Beta
[![TestFlight Beta](https://img.shields.io/badge/TestFlight-Join_Beta-blue?logo=apple)](https://testflight.apple.com/join/QCr2T8SY)

## Overview

**ProseKey AI** is an iOS third-party keyboard designed to help users improve their writing on the go. Whether you need to proofread a sentence, rewrite text for clarity, generate summaries, or even convert text into a table, this keyboard provides quick AI-assisted features at your fingertips. It supports Custom Instructions that you can define in the app and use in the keyboard. You can choose from multiple writing options, and the tool will either correct, refine, or transform your text using various AI models. AI Providers: Gemini, Mistral, and OpenAI API.

> **Important:** ProseKey AI is **BYOK (Bring Your Own Key)**. You must provide your own API keys to use AI functions. The app includes guides to help you obtain them.

The Windows/Linux versions are developed by Jesai Tarun (@theJayTea). The macOS version is developed by me. 

![Keyboard Flow](Images/keyboard.png)  
*Keyboard Flow with the tools*

### Keyboard Features

- Real-time text transformations:
  - Proofreading & grammar checks
  - Style adjustments (professional/friendly/concise)
  - Summarization & table generation
- Cloud AI providers:
  - Google Gemini
  - OpenAI GPT
  - Mistral
  - Anthropic 
  - OpenRouter
- Custom command system for adding your own commands to use in the keyboard!
- Clipboard integration

![App Interface](Images/appflow.png)  
*You can use the app to select AI Provider, define custom commands or edit current ones.*

## Future Plans

- Make the keyboard more stable
- Add Landscape Support
- Add iPad Support
- Other Languages
- **Subscription Option:** Allow users to use an AI model in the app without needing to get their own API key.

### Features Planned but Not Possible (Yet)

1. **Voice Input in the Keyboard:**  
   I attempted to add speech-to-text using Apple’s API, but Apple does not allow voice input in third-party keyboards. (Microsoft SwiftKey uses Microsoft’s own online voice input system, not Apple’s and it is not offline/on-device.)

2. **Local Models:**  
   I worked on integrating MLX models for a fully offline experience (no API keys needed), but iOS imposes strict RAM limits on third-party keyboards. Even a 0.5B local model causes the keyboard to crash due to memory constraints.

## Credits
- As previously said this project wouldn't be possible without the original WritingTools Project by Jesai Tarun @theJayTea. (https://github.com/theJayTea/WritingTools)
- Suggestions and ideas of @Joaov41 made this project much better and more functional. Specifically they helped me with adding automatic text detection (under 200 characters) to the app.