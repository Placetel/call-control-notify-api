"""
    Run with:
    python events.py
"""

routingXML = """
<Response>
    <Forward music_on_hold="true" voicemail="false" voicemail_announcement="4711" voicemail_as_attachment="true" forward_announcement="7684">
        <Target ringtime="">
            <Number>7777acbdef@fbpx.de</Number>
        </Target>
    </Forward>
</Response>
"""

from BaseHTTPServer import BaseHTTPRequestHandler
import cgi

class GetHandler(BaseHTTPRequestHandler):

    def do_POST(self):
        self.send_response(200)
        self.end_headers()
        ctype, pdict = cgi.parse_header(self.headers.getheader('content-type'))
        post_data = cgi.parse_multipart(self.rfile, pdict)
        if post_data['event'][0] == 'IncomingCall':
            self.wfile.write(routingXML)
        return

if __name__ == '__main__':
    from BaseHTTPServer import HTTPServer
    server = HTTPServer(('localhost', 8080), GetHandler)
    print 'Starting server, use <Ctrl-C> to stop'
    server.serve_forever()
