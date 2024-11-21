import os
import requests
from jose import jwt, jwk

def lambda_handler(event, context):
    try:
        # Extract cookies
        print(event['headers'])
        cookie_header = event['headers'].get('cookie', '')
        if not cookie_header:
            raise Exception("No cookies found in the request")

        cookies = {cookie.split('=')[0].strip(): cookie.split('=')[1].strip() for cookie in cookie_header.split(';')}
        print("COOKIES: ", cookies)
        
        token = cookies.get('id_token') 
        if not token:
            raise Exception("Auth token not found in cookies")

        print("TOKEN: ", token)

        user_claims = validate_jwt(token)

        print(event)
        
        effect = 'Allow'
        method_arn = event['routeArn']
        principal_id = user_claims['sub'] 
        
        # Generate policy document
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
                "userId": principal_id,
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

    jwks_url = f"https://cognito-idp.{region}.amazonaws.com/{user_pool_id}/.well-known/jwks.json"
    response = requests.get(jwks_url)
    response.raise_for_status()
    jwks = response.json()

    unverified_header = jwt.get_unverified_header(token)

    rsa_key = next((key for key in jwks['keys'] if key['kid'] == unverified_header['kid']), None)
    if not rsa_key:
        raise Exception("RSA key not found")

    public_key = jwk.construct(rsa_key)

    try:
        options={
            'verify_at_hash': False 
        }
        payload = jwt.decode(
            token,
            public_key,
            algorithms=['RS256'],
            audience=app_client_id,
            issuer=f"https://cognito-idp.{region}.amazonaws.com/{user_pool_id}",
            options=options
        )

        return payload
    except jwt.ExpiredSignatureError:
        raise Exception("Token has expired")
    except jwt.JWTClaimsError as e:
        raise Exception(f"Invalid token claims: {e}")
    except jwt.JWTError as e:
        raise Exception(f"Invalid token: {e}")
