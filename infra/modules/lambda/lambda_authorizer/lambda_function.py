import os
import jwt
import json
import requests
from jwt.algorithms import RSAAlgorithm

def lambda_handler(event, context):
    try:
        cookie_header = event['headers'].get('cookie', '')
        if not cookie_header:
            raise Exception("No cookies found in the request")

        cookies = {cookie.split('=')[0].strip(): cookie.split('=')[1].strip() for cookie in cookie_header.split(';')}
        token = cookies.get('id_token') 
        if not token:
            raise Exception("Auth token not found in cookies")

        user_claims = validate_jwt(token)
        
        effect = 'Allow'
        method_arn = event['methodArn']
        principal_id = user_claims['sub'] 
        
        policy_document = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": method_arn
                }
            ]
        }
        
        return {
            "principalId": principal_id,
            "policyDocument": policy_document,
            "context": {
                "username": user_claims.get('username', ''),
                "email": user_claims.get('email', '')
            }
        }
    except Exception as e:
        print(f"Authorization error: {e}")
        raise Exception("Unauthorized")

def validate_jwt(token):
    region = os.environ['COGNITO_REGION'] 
    user_pool_id = os.environ['COGNITO_USER_POOL_ID'] 
    app_client_id = os.environ['COGNITO_APP_CLIENT_ID'] 

    # Fetch JWKS (JSON Web Key Set)
    jwks_url = f"https://cognito-idp.{region}.amazonaws.com/{user_pool_id}/.well-known/jwks.json"
    response = requests.get(jwks_url)
    response.raise_for_status()
    jwks = response.json()

    unverified_header = jwt.get_unverified_header(token)

    rsa_key = {}
    for key in jwks['keys']:
        if key['kid'] == unverified_header['kid']:
            rsa_key = {
                "kty": key['kty'],
                "kid": key['kid'],
                "use": key['use'],
                "n": key['n'],
                "e": key['e']
            }
            break

    if not rsa_key:
        raise Exception("RSA key not found")

    try:
        payload = jwt.decode(
            token,
            RSAAlgorithm.from_jwk(json.dumps(rsa_key)),
            algorithms=['RS256'],
            audience=app_client_id, 
            issuer=f"https://cognito-idp.{region}.amazonaws.com/{user_pool_id}" 
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise Exception("Token has expired")
    except jwt.InvalidTokenError as e:
        raise Exception(f"Invalid token: {e}")
