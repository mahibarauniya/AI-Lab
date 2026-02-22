"""
Simple AI Agent - Connects to Claude LLM and MCP Server

This agent is designed to be easy to understand for new developers.
It has three main parts:
1. Load environment variables (API keys)
2. Connect to Claude LLM
3. Get tools from MCP server and use them (optional)

For new developers:
- LLM = Large Language Model (Claude in this case)
- MCP = Model Context Protocol (a standard way to expose tools to LLMs)
- Tools = Functions the LLM can call (like getting country info, currency rates, etc.)
"""

import os
import json
from anthropic import Anthropic
from dotenv import load_dotenv

# MCP imports are optional - only needed if using MCP server
try:
    from mcp import ClientSession, StdioServerParameters
    from mcp.client.stdio import stdio_client
    MCP_AVAILABLE = True
except ImportError:
    MCP_AVAILABLE = False
    print("⚠ MCP not available. Install with: pip install mcp")


# ============================================================================
# STEP 1: Load Configuration from Environment Variables
# ============================================================================

def load_config():
    """Load API keys and settings from .env file."""
    # Look for .env file in the private folder (one level up)
    base_dir = os.path.dirname(__file__)
    private_env_dir = os.path.abspath(os.path.join(base_dir, "..", "..", "donotcheckin-personalkeyinfo"))
    dotenv_path = os.path.join(private_env_dir, ".env")
    
    if os.path.exists(dotenv_path):
        load_dotenv(dotenv_path)
        print(f"✓ Loaded configuration from: {dotenv_path}")
    else:
        load_dotenv()
        print("⚠ Using default .env location")
    
    # Get the API key and model name
    api_key = os.environ.get("LLM_API_KEY")
    if not api_key:
        raise ValueError("LLM_API_KEY not found in .env file!")
    
    model = os.environ.get("LLM_MODEL", "claude-sonnet-4-20250514")
    
    return api_key, model


# ============================================================================
# STEP 2: Initialize Connection to Claude LLM
# ============================================================================

def create_llm_client(api_key):
    """Create a client to communicate with Claude LLM."""
    return Anthropic(api_key=api_key)


# ============================================================================
# STEP 3: Connect to MCP Server and Get Available Tools
# ============================================================================

async def get_tools_from_mcp_server():
    """
    Connect to the MCP server and get the list of available tools.
    
    The MCP server runs as a separate process and exposes tools that
    the LLM can use to answer questions.
    """
    # Path to the MCP server script
    server_path = os.path.join(os.path.dirname(__file__), "..", "mcp_server", "server.py")
    
    # Configure how to start the MCP server
    server_params = StdioServerParameters(
        command="python",
        args=[server_path],
        env=None
    )
    
    # Connect to the server and get tools
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # Get the list of tools from the server
            tools_response = await session.list_tools()
            
            # Convert MCP tools to Claude-compatible format
            tools = []
            for tool in tools_response.tools:
                tools.append({
                    "name": tool.name,
                    "description": tool.description,
                    "input_schema": tool.inputSchema
                })
            
            return tools, session


# ============================================================================
# STEP 4: Run the Agent (Talk to User)
# ============================================================================

def run_agent_conversation(llm_client, model, tools, user_message, tool_handler=None):
    """
    Main agent loop: Send user message to LLM, handle tool calls, return answer.
    
    Args:
        llm_client: The Anthropic client instance
        model: Model name to use
        tools: List of tool definitions
        user_message: The user's question
        tool_handler: Function to execute tools (optional)
    
    How it works:
    1. Send user question to Claude
    2. Claude decides if it needs to use tools
    3. If yes, we execute the tools and send results back to Claude
    4. Claude uses tool results to formulate final answer
    5. Return answer to user
    """
    # Start conversation with user's message
    messages = [{"role": "user", "content": user_message}]
    
    print(f"\n{'='*70}")
    print(f"User: {user_message}")
    print(f"{'='*70}\n")
    
    # System prompt tells Claude what it can do (LIMITED TO 2 TOOLS ONLY)
    system_prompt = """You are a helpful AI assistant with access to ONLY 2 country and currency tools:

1. get_currency_by_country - Find what currency a country uses
2. get_exchange_rate - Get current exchange rate for a currency (relative to USD)
please don't use any other tools or functions.
focus on only those tools available to you.
Use these tools to answer questions about:
- What currency a country uses
- Current exchange rates

Be concise, clear, and helpful in your responses."""
    
    # Agent loop - keep going until we have a final answer
    max_iterations = 10
    for iteration in range(max_iterations):
        
        # Send message to Claude
        response = llm_client.messages.create(
            model=model,
            max_tokens=4096,
            system=system_prompt,
            tools=tools,
            messages=messages
        )
        
        # Add Claude's response to conversation history
        messages.append({
            "role": "assistant",
            "content": response.content
        })
        
        # Check if Claude is done (no tools needed)
        if response.stop_reason == "end_turn":
            # Extract the text response
            final_answer = ""
            for block in response.content:
                if hasattr(block, "text"):
                    final_answer += block.text
            
            print(f"🤖 Assistant: {final_answer}\n")
            print(f"{'='*70}\n")
            return final_answer
        
        # Claude wants to use tools
        if response.stop_reason == "tool_use":
            tool_results = []
            
            # Execute each tool Claude requested
            for block in response.content:
                if block.type == "tool_use":
                    tool_name = block.name
                    tool_input = block.input
                    
                    print(f"🔧 Using tool: {tool_name}")
                    print(f"   Input: {json.dumps(tool_input, indent=2)}")
                    
                    # Execute the tool using the provided handler
                    if tool_handler:
                        result = tool_handler(tool_name, tool_input)
                    else:
                        result = {"note": "No tool handler provided"}
                    
                    print(f"   ✓ Done\n")
                    
                    # Add tool result to send back to Claude
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": result if isinstance(result, str) else json.dumps(result)
                    })
            
            # Send tool results back to Claude
            messages.append({
                "role": "user",
                "content": tool_results
            })
    
    return "Conversation limit reached."


# ============================================================================
# STEP 5: Interactive Chat Mode
# ============================================================================

def interactive_mode():
    """
    Start an interactive chat session with the agent.
    User can type questions and get answers.
    """
    # Load configuration
    api_key, model = load_config()
    
    # Connect to Claude LLM
    llm_client = create_llm_client(api_key)
    
    print(f"\n{'='*70}")
    print("🤖 AI Agent - Country & Currency Assistant")
    print(f"{'='*70}")
    print(f"Model: {model}")
    print(f"{'='*70}")
    print("\nType your question or 'quit' to exit.\n")
    
    # For this simplified version, we'll use a basic set of tools
    # In production, you'd get these from the MCP server
    tools = []
    
    # Chat loop
    while True:
        try:
            user_input = input("You: ").strip()
            
            if not user_input:
                continue
            
            if user_input.lower() in ['quit', 'exit', 'goodbye']:
                print("\n👋 Goodbye!\n")
                break
            
            # Get response from agent
            run_agent_conversation(llm_client, model, tools, user_input)
            
        except KeyboardInterrupt:
            print("\n\n👋 Goodbye!\n")
            break
        except Exception as e:
            print(f"\n❌ Error: {str(e)}\n")


# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    """
    When you run this file directly, it starts the interactive chat mode.
    
    To use this agent:
    1. Make sure your .env file has LLM_API_KEY set
    2. Make sure the MCP server is set up in ../mcp_server/server.py
    3. Run: python agent.py
    4. Start asking questions!
    """
    interactive_mode()
