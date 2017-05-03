const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const WebSocket = require('ws');

const port = 30001;

const app = express();
const wss = new WebSocket.Server({port: (port + 1)});
const urlencodedParser = bodyParser.urlencoded({ extended: false });

wss.broadcast = function broadcast (data) {
  wss.clients.forEach(function each (client) {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data)
    }
  })
};

app.get('/', function (req, res) {
  res.sendFile(path.join(__dirname + '/index.html'))
});

app.post('/', urlencodedParser, function (req, res) {
  if (!req.body) return res.sendStatus(400);

  console.log(req.body);

  wss.broadcast(JSON.stringify(req.body));
  res.end()
});

app.listen(port);
