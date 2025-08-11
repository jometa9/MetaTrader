const http = require('http');
const POST_KEY = "keykey";  // 🔐 POST API key
const GET_KEY = "keykey";   // 🔐 GET API key
let latestData = null;

const server = http.createServer((req, res) => {
  // --- POST Handler ---
  if (req.method === 'POST' && req.url === '/api') 
  {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => 
	{
      try 
	  {
        const data = JSON.parse(body);
        // Check POST API key
        if (data.apiKey !== POST_KEY) 
		{
          res.writeHead(403, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ error: 'Invalid POST API key' }));
        }
        delete data.apiKey;
        latestData = data;
        console.log("✅ Received and stored data:", latestData);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok' }));
      } 
	  catch (err) 
	  {
        console.error("❌ JSON parse error:", err.message);
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON' }));
      }
    }
  );
  } 
  // --- GET Handler ---  
  else // --- GET Handler ---
if (req.method === 'GET' && req.url.startsWith('/api')) 
{
    const url = new URL(req.url, `http://${req.headers.host}`);
    const apiKey = url.searchParams.get('api_key');

    if (apiKey !== GET_KEY) {
        res.writeHead(403, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Forbidden: Invalid API key' }));
        return;
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(latestData || {}));
}
  // --- 404 ---  
  else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

// Start server
server.listen(80, () => {
  console.log(`✅ Server running on http://localhost/api`);
});
