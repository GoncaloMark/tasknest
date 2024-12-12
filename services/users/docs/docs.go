// Package docs Code generated by swaggo/swag. DO NOT EDIT
package docs

import "github.com/swaggo/swag"

const docTemplate = `{
    "schemes": {{ marshal .Schemes }},
    "swagger": "2.0",
    "info": {
        "description": "{{escape .Description}}",
        "title": "{{.Title}}",
        "contact": {},
        "version": "{{.Version}}"
    },
    "host": "{{.Host}}",
    "basePath": "{{.BasePath}}",
    "paths": {
        "/auth/callback": {
            "get": {
                "description": "Handles the callback from Cognito after authentication.",
                "tags": [
                    "authentication"
                ],
                "summary": "Cognito Callback",
                "parameters": [
                    {
                        "type": "string",
                        "description": "Authorization code",
                        "name": "code",
                        "in": "query",
                        "required": true
                    }
                ],
                "responses": {
                    "302": {
                        "description": "Redirects to the frontend URL after successful login."
                    },
                    "400": {
                        "description": "Authorization code missing",
                        "schema": {
                            "type": "string"
                        }
                    },
                    "500": {
                        "description": "Internal server error",
                        "schema": {
                            "type": "string"
                        }
                    }
                }
            }
        },
        "/auth/check": {
            "get": {
                "description": "Checks if the user is authenticated based on the ID token in cookies.",
                "tags": [
                    "authentication"
                ],
                "summary": "Authentication Check",
                "responses": {
                    "200": {
                        "description": "OK",
                        "schema": {
                            "type": "object",
                            "additionalProperties": true
                        }
                    },
                    "401": {
                        "description": "Unauthorized",
                        "schema": {
                            "type": "object",
                            "additionalProperties": true
                        }
                    }
                }
            }
        },
        "/auth/logout": {
            "get": {
                "description": "Logs out the user by clearing authentication cookies.",
                "tags": [
                    "authentication"
                ],
                "summary": "Logout Callback",
                "responses": {
                    "302": {
                        "description": "Redirects to the frontend URL after successful logout."
                    }
                }
            }
        },
        "/auth/refresh": {
            "post": {
                "description": "Refreshes the ID token using the refresh token stored in cookies.",
                "tags": [
                    "authentication"
                ],
                "summary": "Token Refresh",
                "responses": {
                    "200": {
                        "description": "Token refreshed successfully!",
                        "schema": {
                            "type": "string"
                        }
                    },
                    "401": {
                        "description": "Refresh token missing or invalid",
                        "schema": {
                            "type": "string"
                        }
                    }
                }
            }
        },
        "/health": {
            "get": {
                "description": "Returns the health status of the API.",
                "tags": [
                    "health"
                ],
                "summary": "Health Check",
                "responses": {
                    "200": {
                        "description": "OK",
                        "schema": {
                            "type": "string"
                        }
                    }
                }
            }
        }
    }
}`

// SwaggerInfo holds exported Swagger Info so clients can modify it
var SwaggerInfo = &swag.Spec{
	Version:          "1.0",
	Host:             "",
	BasePath:         "/api",
	Schemes:          []string{},
	Title:            "User Management API",
	Description:      "API for managing Users",
	InfoInstanceName: "swagger",
	SwaggerTemplate:  docTemplate,
	LeftDelim:        "{{",
	RightDelim:       "}}",
}

func init() {
	swag.Register(SwaggerInfo.InstanceName(), SwaggerInfo)
}
