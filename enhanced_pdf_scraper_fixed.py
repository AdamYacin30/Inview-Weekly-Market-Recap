from playwright.sync_api import sync_playwright
import sys
import re
import time
import requests
from urllib.parse import urljoin, urlparse
import os

def find_pdf_links(page, base_url):
    """Find all PDF download links on the page"""
    pdf_links = []
    
    # Common selectors for PDF download links
    pdf_selectors = [
        'a[href*=".pdf"]',
        'a[href*="download"]',
        'a[download]',
        'a[href*="pdf"]',
        'button[onclick*="pdf"]',
        '.download-link',
        '.pdf-link',
        '[data-href*="pdf"]',
        'a[title*="PDF"]',
        'a[title*="Download"]',
        'a[aria-label*="PDF"]',
        'a[aria-label*="Download"]',
        'a:has-text("PDF")',
        'a:has-text("Download")',
        'a:has-text("available here")',
        'a:has-text("DOWNLOAD")',
        'a:has-text("View PDF")',
        'a:has-text("Get PDF")',
        'button:has-text("PDF")',
        'button:has-text("Download")'
    ]
    
    for selector in pdf_selectors:
        try:
            elements = page.query_selector_all(selector)
            for element in elements:
                href = element.get_attribute('href')
                onclick = element.get_attribute('onclick')
                data_href = element.get_attribute('data-href')
                
                # Check href attribute
                if href and ('.pdf' in href.lower() or 'download' in href.lower() or 'pdf' in href.lower()):
                    full_url = urljoin(base_url, href)
                    pdf_links.append(full_url)
                
                # Check onclick attribute
                if onclick and '.pdf' in onclick.lower():
                    # Extract URL from onclick
                    url_match = re.search(r'["\']([^"\']*\.pdf[^"\']*)["\']', onclick)
                    if url_match:
                        full_url = urljoin(base_url, url_match.group(1))
                        pdf_links.append(full_url)
                
                # Check data-href attribute
                if data_href and '.pdf' in data_href.lower():
                    full_url = urljoin(base_url, data_href)
                    pdf_links.append(full_url)
        except Exception as e:
            continue
    
    return list(set(pdf_links))  # Remove duplicates

def download_pdf_directly(url, output_path):
    """Try to download PDF directly using requests"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers, timeout=30, allow_redirects=True)
        
        # Check if it's actually a PDF
        content_type = response.headers.get('content-type', '').lower()
        if 'application/pdf' in content_type or url.lower().endswith('.pdf'):
            with open(output_path, 'wb') as f:
                f.write(response.content)
            print(f"Successfully downloaded PDF directly from: {url}")
            return True
        else:
            print(f"URL does not return a PDF: {url} (Content-Type: {content_type})")
            return False
    except Exception as e:
        print(f"Failed to download PDF directly from {url}: {e}")
        return False

def convert_webpage_to_pdf(url, output_path):
    """Enhanced function that first tries to find PDF downloads, then falls back to webpage conversion"""
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        
        try:
            # Navigate to the page
            page.goto(url, timeout=60000)  # Increased timeout
            page.wait_for_load_state('networkidle', timeout=30000)  # Increased timeout
            
            # First, try to find PDF download links
            pdf_links = find_pdf_links(page, url)
            
            if pdf_links:
                print(f"Found {len(pdf_links)} potential PDF links:")
                for i, link in enumerate(pdf_links):
                    print(f"  {i+1}. {link}")
                
                # Try to download each PDF link using requests first (faster and more reliable)
                for pdf_link in pdf_links:
                    if download_pdf_directly(pdf_link, output_path):
                        browser.close()
                        return True
                
                # If direct download failed, try with Playwright
                for pdf_link in pdf_links:
                    try:
                        print(f"Trying Playwright navigation to: {pdf_link}")
                        # Navigate to the PDF link
                        response = page.goto(pdf_link, timeout=60000)
                        
                        # Check if it's actually a PDF
                        content_type = response.headers.get('content-type', '')
                        if 'application/pdf' in content_type:
                            print(f"Successfully found direct PDF at: {pdf_link}")
                            # For PDF pages, we need to save the content differently
                            # Try to download using requests as backup
                            if download_pdf_directly(pdf_link, output_path):
                                browser.close()
                                return True
                        
                        # If not a PDF, try the next link
                        page.go_back(timeout=30000)
                        
                    except Exception as e:
                        print(f"Failed to access PDF link {pdf_link}: {e}")
                        continue
            
            # If no PDF links found or none worked, try common download patterns
            download_patterns = [
                'a:has-text("Download")',
                'a:has-text("PDF")',
                'button:has-text("Download")',
                'button:has-text("PDF")',
                '.download-btn',
                '.pdf-btn',
                '[data-toggle="download"]',
                'a:has-text("DOWNLOAD THE LATEST REPORT")',
                'a:has-text("View Report")',
                'a:has-text("Get Report")'
            ]
            
            # Go back to original page for download attempts
            page.goto(url, timeout=60000)
            page.wait_for_load_state('networkidle', timeout=30000)
            
            for pattern in download_patterns:
                try:
                    elements = page.query_selector_all(pattern)
                    for element in elements:
                        # Try clicking the download button
                        try:
                            with page.expect_download(timeout=30000) as download_info:
                                element.click()
                                download = download_info.value
                                download.save_as(output_path)
                                print(f"Successfully downloaded via click: {pattern}")
                                browser.close()
                                return True
                        except Exception as click_error:
                            print(f"Click download failed for {pattern}: {click_error}")
                            continue
                except Exception as e:
                    continue
            
            # If still no success, fall back to webpage conversion
            print("No PDF downloads found, converting webpage to PDF...")
            page.goto(url, timeout=60000)
            page.wait_for_load_state('networkidle', timeout=30000)
            
            # Remove common navigation elements to focus on content
            page.evaluate("""
                // Remove common navigation and footer elements
                const elementsToRemove = document.querySelectorAll('nav, header, footer, .navigation, .nav, .menu, .sidebar, .ad, .advertisement');
                elementsToRemove.forEach(el => el.remove());
                
                // Remove fixed positioned elements
                const fixedElements = document.querySelectorAll('*');
                fixedElements.forEach(el => {
                    const style = window.getComputedStyle(el);
                    if (style.position === 'fixed' || style.position === 'sticky') {
                        el.remove();
                    }
                });
            """)
            
            page.pdf(path=output_path, format='A4', print_background=True, margin={
                'top': '1cm',
                'right': '1cm',
                'bottom': '1cm',
                'left': '1cm'
            })
            
            browser.close()
            return True
            
        except Exception as e:
            print(f"Error processing {url}: {e}")
            browser.close()
            return False

if __name__ == "__main__":
    url = sys.argv[1]
    output_path = sys.argv[2]
    success = convert_webpage_to_pdf(url, output_path)
    sys.exit(0 if success else 1)

