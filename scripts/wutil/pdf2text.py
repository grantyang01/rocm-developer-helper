#!/usr/bin/env python3
"""
PDF to Plain Text Converter
Extracts text from PDF files and saves to .txt format
"""

import sys
import argparse
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError:
    print("Error: pypdf library not found.")
    print("Install it with: pip install pypdf")
    sys.exit(1)


def pdf_to_text(pdf_path: str, output_path: str = None, verbose: bool = False) -> bool:
    """
    Convert PDF file to plain text.
    
    Args:
        pdf_path: Path to input PDF file
        output_path: Path to output text file (optional, defaults to same name with .txt)
        verbose: Print progress information
        
    Returns:
        True if successful, False otherwise
    """
    try:
        pdf_file = Path(pdf_path)
        
        if not pdf_file.exists():
            print(f"Error: PDF file not found: {pdf_path}")
            return False
        
        if not pdf_file.suffix.lower() == '.pdf':
            print(f"Error: File is not a PDF: {pdf_path}")
            return False
        
        # Determine output path
        if output_path is None:
            output_path = pdf_file.with_suffix('.txt')
        else:
            output_path = Path(output_path)
        
        if verbose:
            print(f"Reading PDF: {pdf_file}")
        
        # Read PDF
        reader = PdfReader(pdf_file)
        num_pages = len(reader.pages)
        
        if verbose:
            print(f"Total pages: {num_pages}")
        
        # Extract text from all pages
        text_content = []
        for i, page in enumerate(reader.pages, start=1):
            if verbose:
                print(f"Processing page {i}/{num_pages}...", end='\r')
            
            text = page.extract_text()
            text_content.append(f"--- Page {i} ---\n{text}\n")
        
        # Write to output file
        full_text = '\n'.join(text_content)
        output_path.write_text(full_text, encoding='utf-8')
        
        if verbose:
            print(f"\nSuccessfully converted {num_pages} pages")
            print(f"Output saved to: {output_path}")
        
        return True
        
    except Exception as e:
        print(f"Error converting PDF: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Convert PDF files to plain text",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python pdf_to_text.py document.pdf
  python pdf_to_text.py document.pdf -o output.txt
  python pdf_to_text.py document.pdf --verbose
        """
    )
    
    parser.add_argument('pdf_file', help='Path to PDF file')
    parser.add_argument('-o', '--output', help='Output text file path (default: same name with .txt extension)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Show progress information')
    
    args = parser.parse_args()
    
    # Convert PDF
    success = pdf_to_text(args.pdf_file, args.output, args.verbose)
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

