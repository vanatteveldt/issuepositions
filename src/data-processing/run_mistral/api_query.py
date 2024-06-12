import requests

def query(prompt, headers, api_url):
    '''Querying the Huggingface inference API with the prompt and headers provided.

    Args:
        prompt (str): The prompt to query the model with through the API.
        headers (dict): The headers to be used in the API request.
                        should be in the format
                        {'Authorization': 'Bearer {YOUR-API-TOKEN}'}
        api_url (str): The URL of the model to query.
                       E.g. 'https://api-inference.huggingface.co/models/gpt2'
    
    Returns:
        dict: The JSON response from the API.
              Format: [{'generated_text': str}]
    '''
    payload = {'inputs': prompt}
    response = requests.post(api_url, headers=headers, json=payload)
    return response.json()