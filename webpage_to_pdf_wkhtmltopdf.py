import subprocess
import sys

def convert_webpage_to_pdf(url, output_path):
    try:
        subprocess.run(["wkhtmltopdf", "--load-error-handling", "ignore", url, output_path], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error converting {url} to PDF: {e}")
        sys.exit(1)

if __name__ == "__main__":
    url = sys.argv[1]
    output_path = sys.argv[2]
    convert_webpage_to_pdf(url, output_path)

