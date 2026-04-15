# GastRotator (Android)

**AI-powered recipe manager for the kinetic kitchen.**

GastRotator is a local-first, privacy-centric Android application built with Flutter. It streamlines the process of organizing your favorite cooking videos by using Google Gemini AI to "read" transcripts and extract structured recipes, nutritional data, and cooking steps.

---

## Key Features (V1)

- **Magic YouTube Import:** Simply share a cooking video from YouTube. The app fetches the transcript and uses **Gemini AI** to generate a structured recipe.
- **Nutritional Intelligence:** Automatically estimates Total Calories, kcal/100g, and total dish weight in **SI Units (grams)**.
- **Local-First Architecture:** Your recipes, transcripts, and API keys stay on your device. Powered by **SQLite** and **Encrypted Shared Preferences**.
- **Kinetic Feast UI:** A bold, editorial-style interface designed for active cooking with asymmetric layouts and high-impact typography.
- **Smart Conversions:** Built-in volume-to-weight utility (e.g., automatically converting "1 tsp" to grams for consistent database entries).
- **Data Portability:** Full JSON Export/Import support for backing up your culinary collection.
- **System Logs & Sharing:** Built-in persistent logging with a 500-entry limit and easy log sharing for troubleshooting.

---

## Future Roadmap

### **v2: The Cognitive Kitchen (In Progress)**
| Feature | Description |
| :--- | :--- |
| **Dynamic AI Modules** | Local model storage manager and hybrid image widgets. |
| **Kinetic Weekly Planner** | Foundational zero-waste meal planning. |
| **The Vision Engine** | On-device CV for ingredient cropping and detection. |
| **Pantry-to-Plate** | Recipe suggestions based on stock photos. |
| **Iteration Tracking** | Versioning, ratings, and user notes for every cook. |
| **Legacy Digitizer** | OCR for digitizing handwritten family recipe cards. |

### **v3: Future Horizons**
- **Hands-Free Assistant:** Voice-controlled step-by-step cooking navigation.
- **Blog Fluff Eliminator:** Direct recipe extraction from food blog URLs (skipping the "story").
- **Visual Doneness Monitor:** AI analysis of pan color/texture to monitor cooking progress.

---

## Setup & Usage

1. **Gemini API Key:** To enable "AI Magic Import," you must provide your own API key. You can get a free one from [Google AI Studio](https://aistudio.google.com/).
2. **Importing:** Use the Android **Share** button on any YouTube video and select "GastRotator" to begin extraction.
3. **Privacy:** This app has **Zero Backend**. No data is collected, tracked, or sold.

---

## Privacy Policy
The official privacy policy can be viewed at:  
[https://github.com/parijjana/gastrotator_android/blob/main/docs/privacy_policy.html](https://github.com/parijjana/gastrotator_android/blob/main/docs/privacy_policy.html)

---
*Stay hungry, stay kinetic.*  
© 2026 GastRotator Project.
