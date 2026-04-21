import os
import sys

try:
    import markdown2
    from fpdf import FPDF
except ImportError:
    print("Missing dependencies. Please run:")
    print("pip install fpdf2 markdown2")
    sys.exit(1)

class BlueprintPDF(FPDF):
    def header(self):
        self.set_font('Arial', 'B', 15)
        self.cell(0, 10, 'GastRotator Engineering Blueprint', 0, 1, 'C')
        self.ln(5)

    def footer(self):
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.cell(0, 10, f'Page {self.page_no()}', 0, 0, 'C')

def convert_md_to_pdf(input_md, output_pdf):
    if not os.path.exists(input_md):
        print(f"Error: {input_md} not found.")
        return

    # 1. Read Markdown
    with open(input_md, 'r', encoding='utf-8') as f:
        md_text = f.read()

    # 2. Convert to basic HTML for parsing if needed, 
    # but here we'll do simple line-by-line rendering for maximum reliability
    # without complex HTML-to-PDF engine dependencies.
    
    pdf = BlueprintPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)
    
    lines = md_text.split('\n')
    
    for line in lines:
        line = line.strip()
        
        # Headers
        if line.startswith('# '):
            pdf.set_font('Arial', 'B', 18)
            pdf.multi_cell(0, 10, line[2:])
            pdf.ln(2)
        elif line.startswith('## '):
            pdf.set_font('Arial', 'B', 14)
            pdf.set_text_color(148, 74, 0) # GastRotator Primary Brown
            pdf.multi_cell(0, 10, line[3:])
            pdf.set_text_color(0, 0, 0)
            pdf.ln(1)
        elif line.startswith('### '):
            pdf.set_font('Arial', 'B', 12)
            pdf.multi_cell(0, 8, line[4:])
        # Lists
        elif line.startswith('* ') or line.startswith('- '):
            pdf.set_font('Arial', '', 11)
            pdf.cell(5) # Indent
            pdf.multi_cell(0, 7, f'• {line[2:]}')
        # Table (simplified handling)
        elif '|' in line and '--' not in line:
            pdf.set_font('Courier', '', 9)
            pdf.multi_cell(0, 6, line)
        # Bold text (very basic check)
        elif '**' in line:
            clean_line = line.replace('**', '')
            pdf.set_font('Arial', '', 11)
            pdf.multi_cell(0, 7, clean_line)
        # Normal text
        else:
            if line:
                pdf.set_font('Arial', '', 11)
                pdf.multi_cell(0, 7, line)
            else:
                pdf.ln(4)

    # 5. Output
    pdf.output(output_pdf)
    print(f"Successfully converted to PDF: {output_pdf}")

if __name__ == "__main__":
    input_file = "docs/DISTRIBUTED_API_BLUEPRINT.md"
    output_file = "docs/DISTRIBUTED_API_BLUEPRINT.pdf"
    convert_md_to_pdf(input_file, output_file)
