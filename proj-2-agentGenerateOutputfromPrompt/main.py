"""
Main Entry Point for AI Agent Application

This file is the starting point of the application. It:
1. Loads environment variables (.env file)
2. Takes user input (question)
3. Calls the AI agent to process the input
4. Receives the final result
5. Writes the result to an output file

For new developers:
- This is where the application starts
- Keep this file simple and focused on the main flow
- Complex logic should be in other modules (agent, tools, etc.)
"""

import os
import json
import csv
from datetime import datetime
from dotenv import load_dotenv
from agent.agent import load_config, create_llm_client, run_agent_conversation
from tools.currency_rates_tool import CurrencyRatesTool
from tools.country_currency_tool import CountryCurrencyTool


# ============================================================================
# STEP 1: Load Environment Variables
# ============================================================================

def setup_environment():
    """Load configuration from .env file."""
    # Look for .env file in the private folder
    base_dir = os.path.dirname(__file__)
    private_env_dir = os.path.abspath(os.path.join(base_dir, "..", "donotcheckin-personalkeyinfo"))
    dotenv_path = os.path.join(private_env_dir, ".env")
    
    if os.path.exists(dotenv_path):
        load_dotenv(dotenv_path)
        print(f"✓ Loaded environment from: {dotenv_path}")
    else:
        load_dotenv()
        print("⚠ Using default .env location")
    
    # Get configuration
    api_key = os.environ.get("LLM_API_KEY")
    if not api_key:
        raise ValueError("LLM_API_KEY not found in .env file!")
    
    model = os.environ.get("LLM_MODEL", "claude-sonnet-4-20250514")
    
    return api_key, model


# ============================================================================
# STEP 2: Take User Input
# ============================================================================

def get_user_input():
    """Get question/input from the user."""
    print("\n" + "="*70)
    print("🤖 AI Agent - Country & Currency Assistant (2 Tools Available)")
    print("="*70)
    print("\nWhat would you like to know?")
    print("Examples:")
    print("  - What currency does India use?")
    print("  - What is the exchange rate for EUR?")
    print("  - What is the exchange rate for Japanese Yen?")
    print("\n")
    
    user_input = input("Your question: ").strip()
    
    if not user_input:
        print("⚠ No input provided. Exiting.")
        return None
    
    return user_input


# ============================================================================
# STEP 3: Run Agent (Process the Input)
# ============================================================================

def run_agent(user_input, llm_client, model):
    """
    Process user input through the AI agent.
    
    Args:
        user_input: The user's question
        llm_client: The Claude LLM client
        model: The model name to use
        
    Returns:
        The agent's response
    """
    print("\n🔄 Processing your request...\n")
    
    # Initialize tool instances
    currency_rates_tool = CurrencyRatesTool()
    country_currency_tool = CountryCurrencyTool()
    
    # Define tools schema for Claude
    tools = [
        {
            "name": "get_currency_by_country",
            "description": "Get the official currency used by a specific country. Returns currency name and code.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "country": {
                        "type": "string",
                        "description": "The country name (e.g., 'India', 'United States', 'Japan')"
                    }
                },
                "required": ["country"]
            }
        },
        {
            "name": "get_exchange_rate",
            "description": "Get the current live exchange rate for a specific currency relative to USD from the public API.",
            "input_schema": {
                "type": "object",
                "properties": {
                    "currency": {
                        "type": "string",
                        "description": "The currency code (e.g., 'EUR', 'INR', 'GBP', 'JPY')"
                    }
                },
                "required": ["currency"]
            }
        }
    ]
    
    # Define tool handler function
    def tool_handler(tool_name, tool_input):
        """Execute the requested tool and return results."""
        try:
            if tool_name == "get_currency_by_country":
                country = tool_input.get("country", "")
                result = country_currency_tool.get_by_country_name(country)
                if result:
                    return f"The currency of {country} is {result.get('currency_name', 'Unknown')} ({result.get('currency_code', 'N/A')})."
                else:
                    return f"Could not find currency information for '{country}'. Please check the country name."
            
            elif tool_name == "get_exchange_rate":
                currency_code = tool_input.get("currency", "").upper()
                result = currency_rates_tool.get_rate(currency_code)
                if result and 'rate' in result:
                    rate = result['rate']
                    base = result.get('base', 'USD')
                    timestamp = result.get('timestamp', 'Unknown')
                    return f"The current exchange rate for {currency_code} (Indian Rupee) is 1 {base} = {rate} {currency_code}."
                else:
                    return f"Could not fetch exchange rate for '{currency_code}'. Please check the currency code."
            
            else:
                return f"Unknown tool: {tool_name}"
        
        except Exception as e:
            return f"Error executing {tool_name}: {str(e)}"
    
    # Call the agent conversation function with tools and handler
    result = run_agent_conversation(llm_client, model, tools, user_input, tool_handler)
    
    return result


# ============================================================================
# STEP 4: Write Result to Output File
# ============================================================================

def create_filename_from_input(user_input, max_length=25):
    """
    Create a concise, relevant filename from user input.
    Removes common stop words and keeps only key terms.
    
    Args:
        user_input: The user's question/prompt
        max_length: Maximum length of the filename part
        
    Returns:
        A sanitized, concise filename string
    """
    # Common stop words to remove
    stop_words = {'what', 'is', 'the', 'a', 'an', 'are', 'how', 'can', 'do', 'does', 
                  'did', 'will', 'would', 'should', 'could', 'in', 'on', 'at', 'to',
                  'for', 'of', 'with', 'from', 'by', 'about', 'as', 'into', 'through',
                  'was', 'were', 'been', 'be', 'have', 'has', 'had', 'this', 'that',
                  'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
                  'me', 'my', 'your', 'his', 'her', 'its', 'our', 'their', 'get',
                  'give', 'tell', 'show', 'find', 'list', 'all', 'some', 'any'}
    
    # Convert to lowercase and split into words
    words = user_input.lower().split()
    
    # Filter out stop words and keep meaningful words
    key_words = [w for w in words if w not in stop_words and len(w) > 2]
    
    # If no key words, fall back to first few words
    if not key_words:
        key_words = words[:3]
    
    # Join key words (limit to first 3-4 key words)
    safe_name = '_'.join(key_words[:4])
    
    # Remove special characters, keep only alphanumeric and underscores
    safe_name = ''.join(c if c.isalnum() or c == '_' else '' for c in safe_name)
    
    # Truncate to max length
    if len(safe_name) > max_length:
        safe_name = safe_name[:max_length]
    
    # Remove trailing underscores
    safe_name = safe_name.rstrip('_')
    
    # If empty after sanitization, use a default name
    if not safe_name:
        safe_name = "query"
    
    return safe_name


def extract_relevant_data(result, user_input):
    """
    Extract only relevant data from the agent's response based on the query type.
    
    Args:
        result: The agent's full response
        user_input: The user's original question
        
    Returns:
        Dictionary with structured relevant data
    """
    import re
    
    # Initialize data structure
    data = {
        'country': '',
        'currency_code': '',
        'currency_name': '',
        'exchange_rate': '',
        'base_currency': 'USD'
    }
    
    # Skip XML/function call sections
    lines = []
    for line in result.split('\n'):
        if not any(tag in line for tag in ['<function', '<invoke', '<parameter', '</function', '</invoke']):
            lines.append(line)
    clean_text = '\n'.join(lines)
    
    # Extract currency code (3 uppercase letters)
    currency_codes = re.findall(r'\b[A-Z]{3}\b', clean_text)
    if currency_codes:
        # Filter out common non-currency words
        valid_codes = [code for code in currency_codes if code not in ['USD', 'THE', 'AND', 'FOR']]
        if valid_codes:
            data['currency_code'] = valid_codes[0]
    
    # Extract country name (look for common patterns)
    country_match = re.search(r'(India|Japan|China|United States|Germany|France|UK|Canada|Australia|Brazil|Mexico|Russia|South Korea|Indonesia|Turkey|Saudi Arabia|Thailand|Philippines|Vietnam|Malaysia|Singapore|Bangladesh|Egypt|Pakistan|Nigeria|Argentina|Colombia|Chile|Peru|Poland|Ukraine|Romania|Netherlands|Belgium|Sweden|Norway|Denmark|Finland|Ireland|Switzerland|Austria|Portugal|Greece|Czech Republic|Hungary|New Zealand)', clean_text, re.IGNORECASE)
    if country_match:
        data['country'] = country_match.group(1)
    
    # Extract exchange rate (number with optional decimal)
    # Patterns ordered from most specific to least specific
    rate_patterns = [
        r'=\s*([0-9]+\.?[0-9]+)\s*INR',  # Matches "= 84.12 INR"
        r'1\s+USD\s*=\s*([0-9]+\.?[0-9]+)',  # Matches "1 USD = 84.12"
        r'rate[:\s]+[0-9]+\s+USD\s*=\s*([0-9]+\.?[0-9]+)',  # Matches "rate: 1 USD = 84.12"
        r'([0-9]+\.?[0-9]+)\s+(?:INR|Rupee|Yen|EUR|GBP)',  # Matches "84.12 INR"
        r'"rate":\s*([0-9]+\.?[0-9]+)',  # Matches JSON format "rate": 84.12
    ]
    for pattern in rate_patterns:
        rate_match = re.search(pattern, clean_text, re.IGNORECASE)
        if rate_match:
            data['exchange_rate'] = rate_match.group(1)
            break
    
    # Extract currency name (look for common currency names)
    currency_names = re.findall(r'\b(Rupee|Yen|Dollar|Euro|Pound|Yuan|Peso|Real|Won|Baht|Ringgit|Dong)\b', clean_text, re.IGNORECASE)
    if currency_names:
        data['currency_name'] = currency_names[0].capitalize()
    
    return data


def save_result_to_file(user_input, result):
    """
    Save the conversation result to a CSV file with only relevant data.
    The filename is based on the user's question for easy identification.
    
    Args:
        user_input: The user's original question
        result: The agent's response
    """
    # Create output directory if it doesn't exist
    output_dir = os.path.join(os.path.dirname(__file__), "output")
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate filename with descriptive name from user input + timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename_base = create_filename_from_input(user_input)
    output_file = os.path.join(output_dir, f"{filename_base}_{timestamp}.csv")
    
    # Extract relevant data from response
    data = extract_relevant_data(result, user_input)
    
    # Prepare CSV with relevant data only
    csv_data = [
        ["timestamp", "question", "country", "currency_code", "currency_name", "exchange_rate", "base_currency"],
        [
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            user_input,
            data['country'],
            data['currency_code'],
            data['currency_name'],
            data['exchange_rate'],
            data['base_currency']
        ]
    ]
    
    # Write to CSV file
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(csv_data)
    
    print(f"\n✓ Result saved to: {output_file}")
    
    return output_file


# ============================================================================
# Main Execution Flow
# ============================================================================

def main():
    """
    Main execution flow of the application.
    
    This function orchestrates the entire process:
    1. Setup environment
    2. Get user input
    3. Run agent
    4. Save result
    """
    try:
        # STEP 1: Load environment variables
        print("\n📋 Setting up environment...")
        api_key, model = setup_environment()
        
        # Create LLM client
        llm_client = create_llm_client(api_key)
        print(f"✓ Connected to Claude ({model})")
        
        # STEP 2: Get user input
        user_input = get_user_input()
        
        if not user_input:
            return
        
        # STEP 3: Run agent and get result
        result = run_agent(user_input, llm_client, model)
        
        # STEP 4: Save result to output file
        output_file = save_result_to_file(user_input, result)
        
        print("\n" + "="*70)
        print("✅ Process completed successfully!")
        print("="*70 + "\n")
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}\n")
        
        # Save error to output file in CSV format
        output_dir = os.path.join(os.path.dirname(__file__), "output")
        os.makedirs(output_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        error_file = os.path.join(output_dir, f"error_{timestamp}.csv")
        
        # Prepare error data as CSV with same structure as success case
        csv_data = [
            ["timestamp", "question", "country", "currency_code", "currency_name", "exchange_rate", "base_currency", "error"],
            [
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                locals().get('user_input', 'N/A'),
                '',
                '',
                '',
                '',
                '',
                str(e)
            ]
        ]
        
        with open(error_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.writer(f)
            writer.writerows(csv_data)
        
        print(f"Error details saved to: {error_file}\n")


# ============================================================================
# Entry Point
# ============================================================================

if __name__ == "__main__":
    """
    This is the entry point when you run: python main.py
    
    The application will:
    1. Load your .env configuration
    2. Ask for your question
    3. Process it through the AI agent
    4. Save the result to the output/ folder
    """
    main()
