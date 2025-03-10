import pandas as pd

def process_csv(file_path):
    """
    Process a CSV file and return a list of records.
    
    Args:
        file_path (str): Path to the CSV file
        
    Returns:
        list: List of dictionaries representing each row in the CSV
    """
    # Use a chunked approach to handle large files with minimal memory usage
    chunk_size = 1000
    all_records = []
    
    # Process the CSV in chunks
    for chunk in pd.read_csv(file_path, chunksize=chunk_size):
        # Convert each chunk to a list of dictionaries and add to our records list
        # Use orient='records' to get a list of dictionaries
        records = chunk.to_dict(orient='records')
        
        # Clean and transform data if needed
        for record in records:
            # Replace NaN values with None (which becomes null in JSON)
            for key, value in record.items():
                if pd.isna(value):
                    record[key] = None
        
        all_records.extend(records)
    
    return all_records