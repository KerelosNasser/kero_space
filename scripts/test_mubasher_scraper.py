import urllib.request
import re
import json
from html.parser import HTMLParser

class MubasherParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_price_div = False
        self.price = None
        
    def handle_starttag(self, tag, attrs):
        if tag == 'span':
            for name, value in attrs:
                if name == 'class' and 'market-summary__last-price' in value:
                    self.in_price_div = True
                
    def handle_data(self, data):
        if self.in_price_div:
            # Clean up the string to find the number
            cleaned = data.strip().replace(',', '')
            if cleaned:
                try:
                    self.price = float(cleaned)
                    self.in_price_div = False
                except ValueError:
                    pass

def scrape_comi():
    url = "https://english.mubasher.info/markets/EGX/stocks/COMI"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as response:
            html = response.read().decode('utf-8')
            
            # Let's try regex first, it's often more robust for simple data points on complex SPAs if it's in the initial HTML
            # We look for something like: <span class="market-summary__last-price">81.00</span>
            
            # Print title to ensure we hit the right page
            title_match = re.search(r'<title>(.*?)</title>', html)
            if title_match:
                print(f"Page Title: {title_match.group(1).strip()}")
                
            # Attempt regex for price
            price_match = re.search(r'market-summary__last-price[^>]*>([\d,\.]+)', html)
            if price_match:
                price = float(price_match.group(1).replace(',', ''))
                print(f"SUCCESS: Found COMI Price via Regex: {price} EGP")
                return
                
            # Attempt HTML Parser as fallback
            parser = MubasherParser()
            parser.feed(html)
            if parser.price:
                print(f"SUCCESS: Found COMI Price via Parser: {parser.price} EGP")
                return
                
            print("FAILED: Could not locate the price in the HTML. The site may be fully client-side rendered (SPA) or the class name changed.")
            print("HTML snippet around 'price':")
            # Let's print some snippet to debug
            idx = html.find('last-price')
            if idx != -1:
                print(html[max(0, idx-100):min(len(html), idx+100)])
            else:
                idx = html.find('lastPrice')
                if idx != -1:
                    print(html[max(0, idx-100):min(len(html), idx+100)])
                else:
                    print("Could not find any obvious price anchors.")
                
    except Exception as e:
        print(f"Error fetching {url}: {e}")

if __name__ == "__main__":
    scrape_comi()
