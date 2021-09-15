'use strict';

exports.handler = (event, context, callback) => {
    /*
     * Generate HTTP redirect response with 302 status code and Location header.
     */
    const response = {
        status: ${REDIRECT_HTTP_CODE},
        statusDescription: 'Found',
        headers: {
            location: [{
                key: 'Location',
                value: `${REDIRECT_PROTO}://${REDIRECT_URL}`,
            }],
        },
    };
    callback(null, response);
};