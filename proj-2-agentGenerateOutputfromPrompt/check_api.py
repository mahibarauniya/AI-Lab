import requests
import json

# Check the live API
response = requests.get("https://open.er-api.com/v6/latest/USD")
data = response.json()

print("=" * 50)
print("Live API Response from open.er-api.com")
print("=" * 50)
print(f"Base Currency: {data.get('base_code')}")
print(f"Last Updated: {data.get('time_last_update_utc')}")
print(f"\nINR Exchange Rate: {data.get('rates', {}).get('INR')}")
print("=" * 50)
