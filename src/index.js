'use strict';

exports.handler = (event, context, callback) => {
    /*
     * Generate HTTP redirect response with 302 status code and Location header.
     */
    const response = {
        status: process.env.REDIRECT_HTTP_CODE,
        statusDescription: 'Found',
        headers: {
            location: [{
                key: 'Location',
                value: `${process.env.REDIRECT_PROTO}://${process.env.REDIRECT_URL}`,
            }],
        },
    };
    callback(null, response);
};