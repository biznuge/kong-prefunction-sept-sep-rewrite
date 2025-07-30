const http = require('node:http');

let ipAddress = null; // Variable to store the found IP address

// Manually parse the command-line arguments
// process.argv contains: ['/path/to/node', '/path/to/script.js', 'arg1', 'arg2', ...]
const args = process.argv.slice(2); // Get arguments after node and script path

// Loop through arguments to find '--ip'
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--ip') {
    // Check if there is a value after the --ip flag
    if (i + 1 < args.length) {
      ipAddress = args[i + 1];
      // Optional: Add validation here to check if it looks like an IP
      break; // Stop searching once --ip is found and processed
    } else {
      console.error("Error: --ip flag requires a value after it.");
      process.exit(1); // Exit with error
    }
  }
}

// Check if the 'ip' argument was successfully found and extracted
if (ipAddress) {

    hostname = ipAddress; // Use the provided IP address
    const port = 8088;

    const server = http.createServer((req, res) => {
        
        const parsedUrl = new URL(req.url, `http://${req.headers.host || 'dummy'}`);

        // Extract the pathname
        const pathName = parsedUrl.pathname; // This gives you '/test/'
        
        if (req.method === 'POST' && req.url === '/test') {
        
            let body = '';
            req.on('data', (chunk) => {
                body += chunk;
            });
            req.on('end', () => {
                const params = new URLSearchParams(body);
                const dob = params.get('dob');

                if (dob) {
                const dateFormat = /^(0[1-9]|[12]\d|3[01])-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\d{4}$/;
                
                if (dateFormat.test(dob)) {
                    res.writeHead(200, { 'Content-Type': 'text/plain' });
                    res.end(dob);
                }else{
                    res.writeHead(400, { 'Content-Type': 'text/plain' });
                    res.end("dob incorrect format");
                }
                }else {
                res.writeHead(400, { 'Content-Type': 'text/plain' });
                res.end('Missing dob field in the request body');
                }
            });
        } else if (req.method === 'GET' && req.url === '/limited') {
        
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end('This is a limited GET response');
          
        } else if (req.method === 'GET' && req.url === '/unlimited') {
        
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end('This is an unlimited GET response');
          
        } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found HERE');
        }
    });

    server.listen(port, hostname, () => {
    console.log(`Server running at http://${hostname}:${port}/`);
    });

}else{
    console.log('No IP address provided. Please use the --ip flag to specify an IP address.');
}