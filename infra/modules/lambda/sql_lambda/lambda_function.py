import json
import os
import boto3
import psycopg2
from psycopg2 import sql

def get_db_credentials(secret_name, region_name):
    """Retrieve username and password from Secrets Manager."""
    client = boto3.client("secretsmanager", region_name=region_name)
    response = client.get_secret_value(SecretId=secret_name)
    secret = json.loads(response["SecretString"])
    return secret["username"], secret["password"]

def get_ssm_parameter(parameter_name, region_name):
    """Retrieve parameter value from SSM Parameter Store."""
    client = boto3.client("ssm", region_name=region_name)
    response = client.get_parameter(Name=parameter_name, WithDecryption=True)
    return response["Parameter"]["Value"]

def execute_sql_script(connection, script_path):
    """Read and execute SQL script."""
    with open(script_path, 'r') as f:
        sql_script = f.read()
    with connection.cursor() as cursor:
        cursor.execute(sql.SQL(sql_script))
    connection.commit()

def lambda_handler(event, context):
    script_path = "/var/task/init.sql"
    secret_name = os.environ["DB_SECRET_NAME"]
    region_name = os.environ["REGION"] 

    # Retrieve credentials and parameters
    username, password = get_db_credentials(secret_name, region_name)
    host = get_ssm_parameter("rds_endpoint", region_name)
    dbname = get_ssm_parameter("db_name", region_name)

    # Connect to the PostgreSQL database
    connection = None
    try:
        connection = psycopg2.connect(
            user=username,
            password=password,
            host=host.split(":")[0],
            port="5432",
            database=dbname
        )
        # Execute the SQL script
        execute_sql_script(connection, script_path)
    except Exception as e:
        print(f"Error executing SQL script: {e}")
        raise
    finally:
        if connection:
            connection.close()

    print("SUCCESS")
    return {"statusCode": 200, "body": json.dumps("Database initialized successfully")}
