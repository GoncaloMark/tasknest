import os
import time
import functools
import logging
import requests
from jose import jwk, jwt
from jose.utils import base64url_decode

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Global cache for JWKS and configuration
_JWKS_CACHE = {
    'keys': None,
    'last_updated': 0
}

_CONFIG_CACHE = {
    'user_pool_id': None,
    'app_client_id': None,
    'last_updated': 0
}

def cached_property(func):
    """Decorator to create a cached property with configurable expiration."""
    cache_name = f'_{func.__name__}_cache'

    @functools.wraps(func)
    def wrapper(self):
        if not hasattr(self, cache_name) or time.time() - getattr(self, f'{cache_name}_timestamp', 0) > 3600:
            setattr(self, cache_name, func(self))
            setattr(self, f'{cache_name}_timestamp', time.time())
        return getattr(self, cache_name)
    
    return property(wrapper)

class CognitoAuthorizer:
    def __init__(self):
        # Use environment variables directly
        self.region = os.environ.get('COGNITO_REGION', 'us-east-1')
        self.user_pool_id = os.environ['COGNITO_USER_POOL_ID']
        self.app_client_id = os.environ['COGNITO_APP_CLIENT_ID']

    def get_config(self):
        """Retrieve configuration from environment variables."""
        current_time = time.time()
        
        # Check if cache is valid
        if (_CONFIG_CACHE['user_pool_id'] and 
            current_time - _CONFIG_CACHE['last_updated'] < 3600):
            logger.info("Returning cached configuration")
            return {
                'user_pool_id': _CONFIG_CACHE['user_pool_id'],
                'app_client_id': _CONFIG_CACHE['app_client_id']
            }

        # Update global cache
        _CONFIG_CACHE['user_pool_id'] = self.user_pool_id
        _CONFIG_CACHE['app_client_id'] = self.app_client_id
        _CONFIG_CACHE['last_updated'] = current_time

        logger.info(f"Retrieved configuration from environment variables")
        return {
            'user_pool_id': self.user_pool_id,
            'app_client_id': self.app_client_id
        }

    def get_public_keys(self):
        """Fetch and cache JWKS with intelligent caching."""
        current_time = time.time()

        # Check if cached keys are still valid (1 hour cache)
        if (_JWKS_CACHE['keys'] and 
            current_time - _JWKS_CACHE['last_updated'] < 3600):
            logger.info("Returning cached JWKS keys")
            return _JWKS_CACHE['keys']

        cognito_url = f'https://cognito-idp.{self.region}.amazonaws.com/{self.user_pool_id}'
        keys_url = f'{cognito_url}/.well-known/jwks.json'

        try:
            response = requests.get(keys_url)
            response.raise_for_status()
            keys = {key['kid']: key for key in response.json()['keys']}

            # Update global cache
            _JWKS_CACHE['keys'] = keys
            _JWKS_CACHE['last_updated'] = current_time

            logger.info(f"Retrieved {len(keys)} JWKS keys")
            return keys
        except Exception as e:
            logger.error(f"JWKS retrieval error: {e}")
            return _JWKS_CACHE.get('keys', {})

    def verify_token(self, token):
        """Comprehensive token verification."""
        config = self.get_config()
        public_keys = self.get_public_keys()

        try:
            # Unverified header extraction
            headers = jwt.get_unverified_headers(token)
            kid = headers['kid']

            if kid not in public_keys:
                logger.warning(f"Invalid key ID: {kid}")
                raise ValueError('Invalid key ID')

            # Get the public key
            public_key = jwk.construct(public_keys[kid])

            # Signature verification
            message, encoded_signature = token.rsplit('.', 1)
            decoded_signature = base64url_decode(encoded_signature.encode('utf-8'))

            if not public_key.verify(message.encode('utf-8'), decoded_signature):
                logger.warning("Token signature verification failed")
                raise ValueError('Invalid signature')

            # Claims verification
            claims = jwt.get_unverified_claims(token)
            
            # Time-based checks
            current_time = time.time()
            if current_time > claims['exp']:
                logger.warning("Token has expired")
                raise ValueError('Token expired')

            # Audience and issuer checks
            if claims.get('aud') != config['app_client_id']:
                logger.warning(f"Invalid audience: {claims.get('aud')}")
                raise ValueError('Invalid audience')

            cognito_url = f'https://cognito-idp.{self.region}.amazonaws.com/{config["user_pool_id"]}'
            if claims.get('iss') != cognito_url:
                logger.warning(f"Invalid issuer: {claims.get('iss')}")
                raise ValueError('Invalid issuer')

            logger.info(f"Token verified for user: {claims.get('sub')}")
            return claims

        except Exception as e:
            logger.error(f"Token verification error: {e}")
            return None

def handler(event, context):
    """Lambda handler with performance optimizations."""
    try:
        # Extract token from cookies
        cookies = event.get('cookies', [])
        cookie_str = '; '.join(cookies) if isinstance(cookies, list) else cookies
        
        # Token extraction logic
        token = None
        for cookie in cookie_str.split('; '):
            if cookie.startswith('id_token='):
                token = cookie.split('=')[1]
                break

        if not token:
            logger.warning("No token found in cookies")
            return generate_policy('anonymous', 'Deny', event['routeArn'])

        # Perform verification
        authorizer = CognitoAuthorizer()
        claims = authorizer.verify_token(token)

        if not claims:
            logger.warning("Token verification failed")
            return generate_policy('unauthorized', 'Deny', event['routeArn'])

        # Generate allow policy with user context
        logger.info(f"Authorizing user: {claims['sub']}")
        return generate_policy(
            claims['sub'], 
            'Allow', 
            event['routeArn'],
            {
                'userId': claims['sub'],
                'email': claims.get('email', ''),
            }
        )

    except Exception as e:
        logger.error(f"Authorization error: {e}")
        return generate_policy('error', 'Deny', event['routeArn'])

def generate_policy(principal_id, effect, resource, context=None):
    """Generate IAM policy document."""
    logger.info(f"Generating policy for principal: {principal_id}, effect: {effect}")
    policy = {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [{
                'Action': 'execute-api:Invoke',
                'Effect': effect,
                'Resource': resource
            }]
        }
    }
    
    if context:
        policy['context'] = context
    
    return policy