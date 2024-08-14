from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
import json

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def _send_response(self, message, status_code=200):
        self.send_response(status_code)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(message.encode('utf-8'))

    def _log_request(self):
        ip_address = self.client_address[0]
        
        # Logowanie wszystkich nagłówków
        headers = dict(self.headers)
        
        # Wyodrębnienie ciasteczek, jeśli są obecne
        cookies = self.headers.get('Cookie')
        if cookies:
            headers['Cookies'] = cookies

        # Tworzenie słownika z informacjami o żądaniu
        request_info = {
            'ip_address': ip_address,
            'method': self.command,
            'path': self.path,
            'headers': headers
        }

        # Logowanie informacji o żądaniu jako JSON
        logging.info(f"Request details: {json.dumps(request_info, indent=2)}")

    def do_GET(self):
        self._log_request()
        ascii_cat = """
         /\\_/\\
        ( o.o )
         > ^ <
        """
        self._send_response(f'Connection logged. Here\'s a cat:\n{ascii_cat}')

if __name__ == '__main__':
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        filename='server.log',
        filemode='a'
    )
    server_address = ('', 8877)  # Nasłuchiwanie na porcie 8877
    httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
    logging.info('Starting server...')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info('Server stopped.')