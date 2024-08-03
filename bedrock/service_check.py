from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess
import sys

class ServiceStatusHandler(BaseHTTPRequestHandler):
    def check_service_status(self, service_name):
        """Checks if the given service is active using systemctl."""
        try:
            result = subprocess.run(
                ["systemctl", "is-active", "--quiet", service_name],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            return result.returncode == 0
        except Exception as e:
            print(f"Error checking service status: {e}", file=sys.stderr)
            return False

    def do_GET(self):
        service_name = 'minecraft.service'  # Replace with your service name
        if self.check_service_status(service_name):
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"Service is running")
        else:
            self.send_response(400)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"Service is not running or an error occurred")

def run(server_class=HTTPServer, handler_class=ServiceStatusHandler, port=7777):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f'Starting httpd server on port {port}...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()
