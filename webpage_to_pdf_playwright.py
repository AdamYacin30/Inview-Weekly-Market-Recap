import asyncio
from playwright.sync_api import sync_playwright
import requests
import sys
import os
from urllib.parse import urljoin

def download_pdf_from_url(url, output_path):
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(output_path, 'wb') as pdf_file:
            for chunk in response.iter_content(chunk_size=8192):
                pdf_file.write(chunk)
        print(f"Successfully downloaded PDF from {url} to {output_path}")
        return True
    except requests.exceptions.RequestException as e:
        print(f"Error downloading PDF from {url}: {e}")
        return False

def convert_webpage_to_pdf(url, output_path):
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()
            page.set_default_timeout(60000)  # Increase timeout to 60 seconds

            if "pgim.com" in url:
                page.goto(url)
                page.wait_for_load_state('domcontentloaded')
                
                # Try to handle the attestation modal if it appears
                try:
                    # Wait for the modal to appear and click the agree button
                    page.wait_for_selector('button:has-text("Agree & Proceed")', timeout=5000) # Shorter timeout for modal
                    page.click('button:has-text("Agree & Proceed")')
                    page.wait_for_load_state('networkidle')
                except Exception:
                    print("No attestation modal found or could not interact with it.")

                # Directly click 'Read the Commentary'
                page.wait_for_selector('a:has-text("Read the Commentary")', state='visible')
                page.click('a:has-text("Read the Commentary")')
                page.wait_for_load_state('networkidle')
                # Look for the actual PDF link on the page after clicking 'Read the Commentary'
                pdf_link = page.locator('embed[type="application/pdf"]').first
                if pdf_link.is_visible():
                    pdf_url = pdf_link.get_attribute('src')
                    # Construct absolute URL if relative
                    if pdf_url and not pdf_url.startswith(('http://', 'https://')):
                        pdf_url = urljoin(url, pdf_url)
                    if pdf_url and download_pdf_from_url(pdf_url, output_path):
                        browser.close()
                        return True
                # Fallback to print if direct PDF not found or downloadable
                page.pdf(path=output_path)

            elif "deutschewealth.com" in url:
                page.goto(url)
                # Wait for and click the 'Accept all and continue' button for cookies
                page.wait_for_selector('button:has-text("Accept all and continue")', state='visible')
                page.click('button:has-text("Accept all and continue")')
                page.wait_for_load_state('networkidle')
                # Look for the actual PDF link on the page after cookie consent
                pdf_link = page.locator('a[href$=".pdf"]').first
                if pdf_link.is_visible():
                    pdf_url = pdf_link.get_attribute('href')
                    # Construct absolute URL if relative
                    if pdf_url and not pdf_url.startswith(('http://', 'https://')):
                        pdf_url = urljoin(url, pdf_url)
                    if pdf_url and download_pdf_from_url(pdf_url, output_path):
                        browser.close()
                        return True
                # Fallback to print if direct PDF not found or downloadable
                page.pdf(path=output_path)

            elif "privatebank.bankofamerica.com" in url:
                page.goto(url)
                page.wait_for_selector('a:has-text("Read full report here >>")', state='visible')
                pdf_link_element = page.locator('a:has-text("Read full report here >>")')
                pdf_url = pdf_link_element.get_attribute('href')
                # Construct absolute URL if relative
                if pdf_url and not pdf_url.startswith(('http://', 'https://')):
                    pdf_url = urljoin(url, pdf_url)
                if pdf_url and download_pdf_from_url(pdf_url, output_path):
                    browser.close()
                    return True
                else:
                    print(f"Could not find or download PDF from 'Read full report here >>' link on {url}. Falling back to webpage conversion.")
                    page.pdf(path=output_path)

            else:
                page.goto(url)
                page.wait_for_load_state('networkidle')
                page.pdf(path=output_path)

            browser.close()
            print(f"Successfully converted webpage {url} to PDF at {output_path}")
            return True
    except Exception as e:
        print(f"Error converting webpage {url} to PDF: {e}")
        return False

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python webpage_to_pdf_playwright.py <url> <output_path>")
        sys.exit(1)

    url = sys.argv[1]
    output_path = sys.argv[2]

    # First, try to download directly if it's a PDF URL
    if url.lower().endswith('.pdf'):
        if download_pdf_from_url(url, output_path):
            sys.exit(0)

    # Otherwise, convert the webpage to PDF
    if convert_webpage_to_pdf(url, output_path):
        sys.exit(0)
    else:
        sys.exit(1)
