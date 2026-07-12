const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

/**
 * Swagger/OpenAPI Documentation Configuration
 * Provides interactive API documentation at /api-docs
 */

const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'VeggieFresh API Documentation',
            version: '1.0.0',
            description: 'Comprehensive API documentation for VeggieFresh - A vegetable marketplace platform',
            contact: {
                name: 'VeggieFresh Team',
                email: 'support@veggiefresh.com'
            },
            license: {
                name: 'MIT',
                url: 'https://opensource.org/licenses/MIT'
            }
        },
        servers: [
            {
                url: 'http://localhost:3000',
                description: 'Development server'
            },
            {
                url: 'https://api.veggiefresh.com',
                description: 'Production server'
            }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'Enter your JWT token'
                }
            },
            schemas: {
                Error: {
                    type: 'object',
                    properties: {
                        success: {
                            type: 'boolean',
                            example: false
                        },
                        error: {
                            type: 'string',
                            example: 'Error message'
                        }
                    }
                },
                Success: {
                    type: 'object',
                    properties: {
                        success: {
                            type: 'boolean',
                            example: true
                        },
                        data: {
                            type: 'object'
                        }
                    }
                },
                Product: {
                    type: 'object',
                    properties: {
                        _id: {
                            type: 'string',
                            example: '507f1f77bcf86cd799439011'
                        },
                        name: {
                            type: 'string',
                            example: 'Fresh Tomatoes'
                        },
                        category: {
                            type: 'string',
                            example: 'Vegetables'
                        },
                        price: {
                            type: 'number',
                            example: 40
                        },
                        unit: {
                            type: 'string',
                            example: 'kg'
                        },
                        image: {
                            type: 'string',
                            example: 'https://example.com/tomato.jpg'
                        },
                        description: {
                            type: 'string',
                            example: 'Fresh organic tomatoes'
                        },
                        inStock: {
                            type: 'boolean',
                            example: true
                        }
                    }
                },
                CartItem: {
                    type: 'object',
                    properties: {
                        productId: {
                            type: 'string',
                            example: '507f1f77bcf86cd799439011'
                        },
                        quantity: {
                            type: 'number',
                            example: 2
                        },
                        price: {
                            type: 'number',
                            example: 40
                        }
                    }
                },
                Order: {
                    type: 'object',
                    properties: {
                        _id: {
                            type: 'string',
                            example: '507f1f77bcf86cd799439011'
                        },
                        userId: {
                            type: 'string',
                            example: '507f1f77bcf86cd799439011'
                        },
                        items: {
                            type: 'array',
                            items: {
                                $ref: '#/components/schemas/CartItem'
                            }
                        },
                        total: {
                            type: 'number',
                            example: 280
                        },
                        status: {
                            type: 'string',
                            enum: ['placed', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'],
                            example: 'confirmed'
                        },
                        createdAt: {
                            type: 'string',
                            format: 'date-time'
                        }
                    }
                },
                Address: {
                    type: 'object',
                    required: ['line1', 'city', 'state', 'pincode'],
                    properties: {
                        line1: {
                            type: 'string',
                            example: 'Flat 101, Building A'
                        },
                        line2: {
                            type: 'string',
                            example: 'Sector 5'
                        },
                        landmark: {
                            type: 'string',
                            example: 'Near City Mall'
                        },
                        city: {
                            type: 'string',
                            example: 'Mumbai'
                        },
                        state: {
                            type: 'string',
                            example: 'Maharashtra'
                        },
                        pincode: {
                            type: 'string',
                            example: '400001'
                        }
                    }
                }
            },
            responses: {
                UnauthorizedError: {
                    description: 'Authentication token is missing or invalid',
                    content: {
                        'application/json': {
                            schema: {
                                $ref: '#/components/schemas/Error'
                            }
                        }
                    }
                },
                NotFoundError: {
                    description: 'Resource not found',
                    content: {
                        'application/json': {
                            schema: {
                                $ref: '#/components/schemas/Error'
                            }
                        }
                    }
                },
                ValidationError: {
                    description: 'Validation error',
                    content: {
                        'application/json': {
                            schema: {
                                $ref: '#/components/schemas/Error'
                            }
                        }
                    }
                },
                RateLimitError: {
                    description: 'Rate limit exceeded',
                    content: {
                        'application/json': {
                            schema: {
                                type: 'object',
                                properties: {
                                    success: {
                                        type: 'boolean',
                                        example: false
                                    },
                                    error: {
                                        type: 'string',
                                        example: 'Too many requests from this IP, please try again later.'
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        security: [
            {
                bearerAuth: []
            }
        ],
        tags: [
            {
                name: 'Authentication',
                description: 'User authentication and authorization'
            },
            {
                name: 'Products',
                description: 'Product catalog operations'
            },
            {
                name: 'Categories',
                description: 'Product categories'
            },
            {
                name: 'Cart',
                description: 'Shopping cart operations'
            },
            {
                name: 'Checkout',
                description: 'Order checkout and payment'
            },
            {
                name: 'Orders',
                description: 'Order management'
            },
            {
                name: 'Profile',
                description: 'User profile management'
            },
            {
                name: 'Health',
                description: 'API health check'
            }
        ]
    },
    apis: [
        './src/routes/*.js',
        './src/controllers/*.js',
        './src/models/*.js'
    ]
};

const swaggerSpec = swaggerJsdoc(options);

/**
 * Setup Swagger documentation
 * @param {Object} app - Express app instance
 */
function setupSwagger(app) {
    // Swagger UI options
    const swaggerUiOptions = {
        explorer: true,
        customCss: '.swagger-ui .topbar { display: none }',
        customSiteTitle: 'VeggieFresh API Documentation',
        swaggerOptions: {
            persistAuthorization: true,
            displayRequestDuration: true,
            filter: true,
            syntaxHighlight: {
                activate: true,
                theme: 'monokai'
            }
        }
    };

    // Serve Swagger UI
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, swaggerUiOptions));

    // Serve Swagger JSON
    app.get('/api-docs.json', (req, res) => {
        res.setHeader('Content-Type', 'application/json');
        res.send(swaggerSpec);
    });

    console.log('📚 Swagger documentation available at /api-docs');
}

module.exports = {
    setupSwagger,
    swaggerSpec
};
