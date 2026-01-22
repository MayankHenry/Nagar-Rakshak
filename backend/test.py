from google import genai
import os
from dotenv import load_dotenv

# 1. Load the secret variables from .env
load_dotenv()

# 2. Get the key safely
API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY:
    print("❌ Error: Could not find API key in .env file")
else:
    print("🔑 Key found! Connecting...")
    
    # 3. Connect as usual
    client = genai.Client(api_key=API_KEY)
    
    try:
        response = client.models.generate_content(
            model="gemini-flash-latest",
            contents="Say 'Security Check Passed' if you can hear me."
        )
        print("✅ SUCCESS: " + response.text)
    except Exception as e:
        print("❌ API ERROR: " + str(e))