import json
import os

def generate_stub():
    # In a full implementation, this hits USDA and Open Food Facts API.
    # For now, we generate a high-quality stub for testing.
    items = [
        {"id": "1", "name": "Ful Medames", "calories": 344, "protein": 26.1, "carbs": 58.3, "fat": 1.5, "isFastingCompliant": True},
        {"id": "2", "name": "Chicken Breast", "calories": 165, "protein": 31.0, "carbs": 0.0, "fat": 3.6, "isFastingCompliant": False},
        {"id": "3", "name": "White Rice", "calories": 130, "protein": 2.7, "carbs": 28.0, "fat": 0.3, "isFastingCompliant": True},
    ]
    
    os.makedirs('assets', exist_ok=True)
    with open('assets/ingredients_seed.json', 'w') as f:
        json.dump(items, f, indent=2)
    print("Generated ingredients_seed.json")

if __name__ == '__main__':
    generate_stub()
