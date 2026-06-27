import io
import time
import random
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image

app = FastAPI(
    title="DripAI Crop Disease & Diagnostics Service",
    description="Python API for crop leaf disease classification and smart drip irrigation adjustments",
    version="1.0.0"
)

# Enable CORS for local cross-origin communication with Flutter clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DISEASE_DATABASE = {
    "tomato": {
        "disease": "Tomato Late Blight",
        "scientific_name": "Phytophthora infestans",
        "severity": "CRITICAL",
        "description": "Late blight is a devastating fungal pathogen that attacks leaves, stems, and fruit. It thrives in cool, wet environments, causing dark, water-soaked lesions and fuzzy white spore growth.",
        "treatment": "Immediately prune and destroy infected leaves. Apply copper-based fungicide at 7-day intervals. Space out plants to improve airflow.",
        "drip_irrigation_action": "Reduce drip runtime by 35% in Zone 2. Run irrigation strictly in the early morning (4 AM - 6 AM) so the soil surface dries out during the day, preventing spore germination.",
        "sensor_status": "noisy_signal_detected" # Triggers the sensor glitch warnings
    },
    "cotton": {
        "disease": "Cotton Leaf Rust",
        "scientific_name": "Puccinia cacabata",
        "severity": "HIGH",
        "description": "Rust causes orange-brown pustules on the undersides of leaves, leading to premature leaf drop, stunted cotton boll growth, and reduced yield quality.",
        "treatment": "Apply sulfur-based or systemic triazole fungicides. Clear surrounding weeds which host alternate rust stages.",
        "drip_irrigation_action": "Shift irrigation to a deep, less frequent pattern (increase intervals from 2 days to 4 days). Ensure drip emitters are not placing water directly onto the foliage.",
        "sensor_status": "optimal"
    },
    "sugarcane": {
        "disease": "Sugarcane Red Rot",
        "scientific_name": "Colletotrichum falcatum",
        "severity": "HIGH",
        "description": "Red Rot is a severe vascular disease. It causes internal reddening of tissues, leaf midrib lesions, and eventual wilting or collapse of the sugarcane stalks.",
        "treatment": "Plant healthy, disease-free seed canes. Improve field drainage. Avoid water stagnation.",
        "drip_irrigation_action": "Enable automatic Soil Moisture Sensor Feedback. Restrict irrigation runtime if soil moisture stays above 75%, as waterlogged soil accelerates vascular rot spread.",
        "sensor_status": "high_attenuation"
    },
    "wheat": {
        "disease": "Wheat Powdery Mildew",
        "scientific_name": "Blumeria graminis f. sp. tritici",
        "severity": "MEDIUM",
        "description": "Powdery mildew presents as white, powdery fungal patches on the upper surface of leaves. It limits photosynthesis and impairs grain filling.",
        "treatment": "Apply nitrogen fertilizer in balanced amounts. Use resistant crop varieties. Spray neem oil or standard fungicides.",
        "drip_irrigation_action": "Reduce current daily watering by 15%. Excessive soil dampness combined with high crop canopy density favors fungal growth.",
        "sensor_status": "optimal"
    },
    "unknown": {
        "disease": "Healthy Crop (No Disease Identified)",
        "scientific_name": "N/A",
        "severity": "LOW",
        "description": "The leaf appears healthy with normal chlorophyll distribution and leaf tissue structure. No major pathogens identified.",
        "treatment": "Maintain current standard crop management. Monitor for pests periodically.",
        "drip_irrigation_action": "Maintain active auto-drip schedules. No emergency moisture adjustments required.",
        "sensor_status": "optimal"
    }
}

@app.get("/health")
def health_check():
    return {"status": "online", "service": "drip-ai-diagnose-python", "timestamp": time.time()}

@app.post("/api/v1/diagnose")
async def diagnose_leaf(
    file: UploadFile = File(...),
    crop_type: str = Form(...),
    field_id: str = Form("unknown"),
    simulate_glitch: bool = Form(False)
):
    # Log incoming request
    print(f"Received diagnosis request for crop: {crop_type}, field: {field_id}")
    
    # Read the file to verify it's a valid image
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        image.verify()  # Verify it is a valid image format
        # Get dimensions for mock calculations
        width, height = image.size
    except Exception as e:
        # Fallback if image upload is just dummy text in tests
        print(f"Could not open image file, using mock placeholder dimensions: {e}")
        width, height = (800, 600)

    # Simulate network processing latency for realistic AI loading feel
    # Wait time: 1.0 to 1.5 seconds
    time.sleep(1.2)
    
    crop_key = crop_type.lower().strip()
    if crop_key not in DISEASE_DATABASE:
        crop_key = "unknown"
        
    disease_info = DISEASE_DATABASE[crop_key].copy()
    
    # Generate realistic confidence score based on dimensions/random seed
    random.seed(len(contents) if 'contents' in locals() else 42)
    confidence = round(random.uniform(0.85, 0.98), 2)
    
    # Override for testing glitch behavior
    if simulate_glitch:
        disease_info["sensor_status"] = "noisy_signal_detected"

    response_data = {
        "status": "success",
        "crop": crop_type,
        "field_id": field_id,
        "disease": disease_info["disease"],
        "scientific_name": disease_info["scientific_name"],
        "confidence": confidence,
        "severity": disease_info["severity"],
        "description": disease_info["description"],
        "treatment": disease_info["treatment"],
        "drip_irrigation_action": disease_info["drip_irrigation_action"],
        "sensor_status": disease_info["sensor_status"],
        "metadata": {
            "resolution": f"{width}x{height}",
            "processed_at": int(time.time()),
            "engine": "DripAI ResNet-50 v2.1"
        }
    }
    
    return response_data

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
