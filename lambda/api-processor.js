'use strict';

/**
 * Lambda function for processing API requests
 * This function can be invoked by API Gateway for backend processing
 */

exports.handler = async (event, context) => {
    console.log('Event:', JSON.stringify(event, null, 2));

    try {
        // Parse the incoming request
        const httpMethod = event.httpMethod || event.requestContext?.http?.method;
        const path = event.path || event.requestContext?.http?.path;
        const body = event.body ? JSON.parse(event.body) : {};

        // Route based on HTTP method and path
        let response;

        switch (httpMethod) {
            case 'GET':
                response = handleGet(path, event.queryStringParameters);
                break;
            case 'POST':
                response = handlePost(path, body);
                break;
            default:
                response = {
                    statusCode: 405,
                    body: JSON.stringify({ error: 'Method not allowed' })
                };
        }

        // Add CORS headers
        return {
            ...response,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
                ...response.headers
            }
        };

    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message
            })
        };
    }
};

/**
 * Handle GET requests
 */
function handleGet(path, queryParams) {
    if (path === '/api/status') {
        return {
            statusCode: 200,
            body: JSON.stringify({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                version: '1.0.0',
                environment: process.env.ENVIRONMENT || 'dev'
            })
        };
    }

    if (path === '/api/info') {
        return {
            statusCode: 200,
            body: JSON.stringify({
                service: 'Cloud Portfolio API',
                description: 'Lambda-based API processor',
                endpoints: [
                    'GET /api/status',
                    'GET /api/info',
                    'POST /api/process'
                ]
            })
        };
    }

    return {
        statusCode: 404,
        body: JSON.stringify({ error: 'Not found' })
    };
}

/**
 * Handle POST requests
 */
function handlePost(path, body) {
    if (path === '/api/process') {
        // Example data processing
        const processedData = {
            received: body,
            processed: true,
            timestamp: new Date().toISOString(),
            processedBy: 'lambda-api-processor'
        };

        return {
            statusCode: 200,
            body: JSON.stringify(processedData)
        };
    }

    return {
        statusCode: 404,
        body: JSON.stringify({ error: 'Not found' })
    };
}
