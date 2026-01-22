from fastapi import FastAPI, UploadFile, File
import google.generativeai as genai
from PIL import Image
import io
import os
import json 
from dotenv import load_dotenv
import uvicorn

# 1. Load variables
load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")

# 2. Configure AI
genai.configure(api_key=API_KEY)

# Use the standard stable model
model = genai.GenerativeModel('gemini-flash-latest') 

app = FastAPI()

@app.get("/")
def home():
    return {"message": "NagarRakshak Brain is Active!"}

@app.post("/analyze")
async def analyze_image(file: UploadFile = File(...)):
    try:
        # Read image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))

        print("📸 Image received. Analyzing...")
        
        # Analyze with strict formatting instructions
        response = model.generate_content([
            "Analyze this image for civic issues (potholes, garbage, waterlogging). "
            "Return ONLY a raw JSON string like this: {\"issue\": \"pothole\", \"severity\": \"high\"}. "
            "If clean, return {\"issue\": \"none\", \"severity\": \"none\"}. "
            "Do not use Markdown formatting.", 
            image
        ])
        
        # CLEANUP: Remove backticks if Gemini adds them
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        
        # Convert text to a real Python Dictionary
        data = json.loads(clean_text)
        
        print(f"✅ Analysis complete: {data}")
        return data # Send pure JSON object to phone
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return {"issue": "Error", "severity": "Unknown"}

if __name__ == "__main__":
    # Host 0.0.0.0 is crucial for the phone to connect
    uvicorn.run(app, host="0.0.0.0", port=5000)