# Entpoint examples

This are basic examples of API endpoints which should help you to implement your own solutions.

Use the following cURL commands to test your API endpoint:

#### `IncomingCall` event
```bash
curl -X POST --data "event=IncomingCall&from=017312345678&to=022129191999&call_id=f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447" http://localhost:3000
```

#### `CallAccepted` event
```bash
curl -X POST --data "event=CallAccepted&from=017312345678&to=022129191999&call_id=f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447&peer=7777abcdefg@fpbx.de" http://localhost:3000
```

#### `HungUp` event
```bash
curl -X POST --data "event=HungUp&from=017312345678&to=022129191999&call_id=f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447&type=accepted" http://localhost:3000
```
