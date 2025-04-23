"""
Fetches real-time weather data for a list of cities from the Weatherstack API and loads it
into a Snowflake warehouse. The list of cities is read from a YAML config file.
All credentials are securely loaded from GitHub Secrets (via environment variables).
"""

import os
import requests
import pandas as pd
import urllib.parse
import yaml
from sqlalchemy import create_engine, text
from snowflake.sqlalchemy import URL

# ---------- Load Credentials from GitHub Secrets ----------
# These values are securely injected by GitHub Actions using repository secrets.
API_KEY = os.environ["API_KEY"]

SNOWFLAKE_USER = os.environ["SNOWFLAKE_USER"]
SNOWFLAKE_PASSWORD = urllib.parse.quote_plus(os.environ["SNOWFLAKE_PASSWORD"])
SNOWFLAKE_ACCOUNT = os.environ["SNOWFLAKE_ACCOUNT"]
SNOWFLAKE_WAREHOUSE = os.environ["SNOWFLAKE_WAREHOUSE"]
SNOWFLAKE_DATABASE = os.environ["SNOWFLAKE_DATABASE"]
SNOWFLAKE_SCHEMA = os.environ["SNOWFLAKE_SCHEMA"]
SNOWFLAKE_TABLE = os.environ["SNOWFLAKE_TABLE"]

# ---------- Config Loaders ----------
def load_yaml_config(path: str) -> list:
    """
    Loads a list of city names from a YAML configuration file.
    This helps separate data logic from code logic.

    Args:
        path (str): Path to the YAML file.

    Returns:
        list: List of city names.
    """
    with open(path, "r") as file:
        config = yaml.safe_load(file)
    return config["cities"]

# ---------- Snowflake Engine ----------
def get_db_engine():
    """
    Creates and returns a SQLAlchemy engine configured for Snowflake.

    Returns:
        sqlalchemy.Engine: A SQLAlchemy connection engine for Snowflake.
    """
    connection_url = URL(
        account=SNOWFLAKE_ACCOUNT,
        user=SNOWFLAKE_USER,
        password=SNOWFLAKE_PASSWORD,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA,
        warehouse=SNOWFLAKE_WAREHOUSE,
    )
    return create_engine(connection_url)

# ---------- Weather Logic ----------
def fetch_weather_data(city: str, api_key: str) -> dict:
    """
    Makes a GET request to the Weatherstack API to fetch current weather data
    for a specific city.

    Args:
        city (str): City name for which to fetch weather.
        api_key (str): API key for Weatherstack.

    Returns:
        dict: JSON response from the API.

    Raises:
        Exception: If the API call fails or returns an error.
    """
    url = f"http://api.weatherstack.com/current?access_key={api_key}&query={urllib.parse.quote_plus(city)}"
    response = requests.get(url)
    data = response.json()

    if not data.get("success", True):
        raise Exception(f"API error for {city}: {data.get('error', {}).get('info', 'Unknown')}")
    return data

def normalize_weather_data(data: dict) -> pd.DataFrame:
    """
    Flattens and cleans the nested JSON structure from Weatherstack into
    a pandas DataFrame, making it ready for Snowflake ingestion.

    Args:
        data (dict): Raw weather JSON response.

    Returns:
        pd.DataFrame: Flattened weather data.
    """
    df = pd.json_normalize(data)
    df.columns = df.columns.str.replace(r"\.", "_", regex=True)
    return df

def ensure_schema_exists(engine, schema: str):
    """
    Ensures the schema exists in Snowflake. If not, it creates it.

    Args:
        engine (sqlalchemy.Engine): Snowflake connection engine.
        schema (str): Schema name to validate or create.
    """
    with engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema}"))

def insert_data(engine, df: pd.DataFrame, schema: str, table: str):
    """
    Appends the weather DataFrame to the target Snowflake table.

    Args:
        engine (sqlalchemy.Engine): Snowflake connection engine.
        df (pd.DataFrame): Weather data to insert.
        schema (str): Target schema name.
        table (str): Target table name.
    """
    df.to_sql(table, engine, schema=schema, if_exists="append", index=False)
    print(f"✅ Inserted into {schema}.{table}")

# ---------- Main Workflow ----------
def main(api_key: str, cities: list, schema: str, table: str):
    """
    Coordinates the end-to-end flow: from API requests for each city, to
    normalization, and loading into Snowflake.

    Args:
        api_key (str): Weatherstack API key.
        cities (list): List of cities to process.
        schema (str): Snowflake schema to insert into.
        table (str): Snowflake table name.
    """
    try:
        engine = get_db_engine()
        ensure_schema_exists(engine, schema)

        for city in cities:
            print(f"\n📡 Fetching weather data for {city}...")
            raw_data = fetch_weather_data(city, api_key)

            print("🧪 Normalizing...")
            df = normalize_weather_data(raw_data)

            print("📥 Inserting into Snowflake...")
            insert_data(engine, df, schema, table)

    except Exception as e:
        print(f"❌ Error occurred: {e}")

# ---------- Run ----------
if __name__ == "__main__":
    # Define the path to your city configuration YAML file
    config_path = os.path.join(os.environ["GITHUB_WORKSPACE"], "api_data_load", "api_config.yaml")
    
    # Load city names from config
    cities = load_yaml_config(config_path)
    
    # Run the ETL pipeline
    main(API_KEY, cities, SNOWFLAKE_SCHEMA, SNOWFLAKE_TABLE)
