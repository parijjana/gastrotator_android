# Privacy Policy for GastRotator

**Last Updated: April 6, 2026**

GastRotator ("the App") is a local-first recipe management tool designed to help users organize and extract recipe information from video content. This policy explains our commitment to your privacy and how we handle your data.

## 1. Data Collection and Usage
GastRotator is designed to respect user privacy by keeping data on-device.

*   **Recipe Collection:** All recipes you import, edit, or create are stored exclusively in a local database on your device (`sqflite`). We do not operate a central server, and we have no access to your recipe collection.
*   **API Keys:** If you provide a Gemini API Key for "AI Magic Import" features, it is stored securely using the Android Keystore system (`flutter_secure_storage`). This key is never transmitted to us or any third party, except for direct requests to Google's Generative AI services.
*   **Backups:** When you use the "Export" feature, a JSON backup file is created in your device's temporary storage. You maintain full control over where this file is shared or stored.

## 2. Third-Party Services
The App interacts with the following third-party services to provide core functionality:

*   **Google Gemini API:** When you request a "AI Magic Import," the video's transcript and metadata are sent to Google's Gemini AI to structure the recipe. This data is handled according to [Google's Generative AI Privacy Policy](https://support.google.com/gemini/answer/13594961).
*   **YouTube Metadata:** The App fetches publicly available video metadata and transcripts to help organize your recipes. We do not access your personal YouTube account or private data.

## 3. Transparency and Tracking
*   **No Analytics:** We do not use third-party analytics (like Google Analytics or Firebase) or tracking pixels.
*   **No Advertising:** The App does not contain advertisements or use advertising identifiers (AAID).
*   **No Data Sharing:** We do not sell or share any user data with third parties.

## 4. User Controls
You can delete any recipe or remove your Gemini API Key at any time through the App's settings. Deleting the App will remove all locally stored recipe data.

## 5. Contact and Reporting
For questions regarding this policy or to report offensive AI-generated content, please visit our GitHub Repository:
[https://github.com/parijjana/gastrotator_android](https://github.com/parijjana/gastrotator_android)

---
*GastRotator is an independent project dedicated to high-energy, high-privacy cooking.*
