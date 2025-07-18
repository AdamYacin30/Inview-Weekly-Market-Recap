from pypdf import PdfWriter
import sys

def merge_pdfs(input_pdfs, output_pdf):
    writer = PdfWriter()
    for pdf in input_pdfs:
        writer.append(pdf)
    writer.write(output_pdf)
    writer.close()

if __name__ == "__main__":
    input_files = sys.argv[1:-1]
    output_file = sys.argv[-1]
    merge_pdfs(input_files, output_file)
