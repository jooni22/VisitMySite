import urllib.request
import http.cookiejar
import sys
import re

def scrape_cookies(url):
    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    opener.addheaders = [('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')]
    
    try:
        if not url.startswith(('http://', 'https://')):
            raise ValueError(f"unknown url type: '{url}'")
        
        response = opener.open(url)
        headers = response.info()

        # Zapisujemy nagłówki do pliku
        with open('headers.txt', 'w') as header_file:
            for header in headers:
                header_file.write(f'{header}: {headers[header]}\n')

        # Zapisujemy ciasteczka do pliku
        with open('cookies.txt', 'w') as cookie_file:
            for cookie in cj:
                cookie_file.write(f'{cookie.name}={cookie.value}\n')

        print(f"Cookies and headers saved for {url}")
    except ValueError as e:
        domain = re.sub(r'^www\.', '', url)
        print(f"Error: unknown url type: {domain}")
        print("Please add 'http://' or 'https://' to the VIEW_URL in the configuration file.")
        sys.exit(1)
    except Exception as e:
        print(f"Error occurred while scraping {url}: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 cookie_scraper.py <url>")
        sys.exit(1)
    
    url = sys.argv[1]
    scrape_cookies(url)