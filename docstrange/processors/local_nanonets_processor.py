"""Local Nanonets OCR processor using the Hugging Face model."""

import os
import logging
from typing import Optional, Dict, Any
from PIL import Image
import torch
from ..result import ConversionResult

logger = logging.getLogger(__name__)


class LocalNanonetsProcessor:
    """Local processor using the Nanonets-OCR2-3B model from Hugging Face."""
    
    def __init__(self):
        """Initialize the local Nanonets processor."""
        self.model = None
        self.tokenizer = None
        self.processor = None
        
        # Optimized for VPS with GPU
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        if torch.cuda.is_available():
            logger.info(f"GPU detected: {torch.cuda.get_device_name(0)}")
        else:
            logger.info("No GPU detected - using CPU")
            
        self._model_loaded = False
        self._model_loading = False  # Flag to prevent multiple loading attempts
        
    def _load_model(self):
        """Load the Nanonets-OCR2-3B model."""
        if self._model_loaded or self._model_loading:
            return
            
        self._model_loading = True
        
        try:
            from transformers import AutoTokenizer, AutoProcessor, AutoModelForImageTextToText
            
            model_path = "nanonets/Nanonets-OCR2-3B"
            
            logger.info(f"Loading Nanonets-OCR2-3B model on {self.device}...")
            logger.info("Using cached model from Hugging Face cache...")
            
            # Load model with VPS GPU-optimized settings
            if self.device == "cuda":
                # GPU-optimized settings for VPS
                self.model = AutoModelForImageTextToText.from_pretrained(
                    model_path,
                    torch_dtype=torch.float16,
                    device_map="auto",
                    attn_implementation="flash_attention_2",
                    local_files_only=False,
                    low_cpu_mem_usage=True,
                    trust_remote_code=True
                )
            else:
                # CPU fallback
                self.model = AutoModelForImageTextToText.from_pretrained(
                    model_path,
                    torch_dtype=torch.float32,
                    device_map=None,
                    attn_implementation="eager",
                    local_files_only=False,
                    low_cpu_mem_usage=True,
                    trust_remote_code=True
                )
            
            if self.device == "cpu":
                self.model = self.model.to(self.device)
                
            self.model.eval()
            
            # Load tokenizer and processor (from cache)
            self.tokenizer = AutoTokenizer.from_pretrained(model_path)
            self.processor = AutoProcessor.from_pretrained(model_path)
            
            self._model_loaded = True
            logger.info("Nanonets-OCR2-3B model loaded successfully from cache")
            
        except Exception as e:
            logger.error(f"Failed to load Nanonets-OCR2-3B model: {e}")
            self._model_loading = False
            raise
        finally:
            self._model_loading = False
    
    def process_image(self, image_path: str, max_new_tokens: int = 4096) -> str:
        """
        Process an image using the local Nanonets model.
        
        Args:
            image_path: Path to the image file
            max_new_tokens: Maximum number of tokens to generate
            
        Returns:
            Extracted text in markdown format
        """
        if not self._model_loaded:
            self._load_model()
        
        try:
            # Load image
            image = Image.open(image_path)
            
            # Prepare the prompt as specified in the Hugging Face documentation
            prompt = """Extract the text from the above document as if you were reading it naturally. Return the tables in html format. Return the equations in LaTeX representation. If there is an image in the document and image caption is not present, add a small description of the image inside the <img></img> tag; otherwise, add the image caption inside <img></img>. Watermarks should be wrapped in brackets. Ex: <watermark>OFFICIAL COPY</watermark>. Page numbers should be wrapped in brackets. Ex: <page_number>14</page_number> or <page_number>9/22</page_number>. Prefer using ☐ and ☑ for check boxes."""
            
            # Prepare messages
            messages = [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": [
                    {"type": "image", "image": f"file://{os.path.abspath(image_path)}"},
                    {"type": "text", "text": prompt},
                ]},
            ]
            
            # Apply chat template
            text = self.processor.apply_chat_template(
                messages, tokenize=False, add_generation_prompt=True
            )
            
            # Process inputs
            inputs = self.processor(
                text=[text], 
                images=[image], 
                padding=True, 
                return_tensors="pt"
            )
            inputs = inputs.to(self.model.device)
            
            # Generate output
            with torch.no_grad():
                output_ids = self.model.generate(
                    **inputs, 
                    max_new_tokens=max_new_tokens, 
                    do_sample=False,
                    temperature=0.0
                )
            
            # Decode output
            generated_ids = [
                output_ids[len(input_ids):] 
                for input_ids, output_ids in zip(inputs.input_ids, output_ids)
            ]
            
            output_text = self.processor.batch_decode(
                generated_ids, 
                skip_special_tokens=True, 
                clean_up_tokenization_spaces=True
            )
            
            return output_text[0]
            
        except Exception as e:
            logger.error(f"Error processing image {image_path}: {e}")
            raise
    
    def process_pdf(self, pdf_path: str) -> str:
        """
        Process a PDF by converting pages to images and processing them.
        
        Args:
            pdf_path: Path to the PDF file
            
        Returns:
            Extracted text in markdown format
        """
        try:
            import fitz  # PyMuPDF
            
            doc = fitz.open(pdf_path)
            results = []
            
            for page_num in range(len(doc)):
                # Convert page to image
                page = doc[page_num]
                pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))  # 2x zoom for better quality
                img_data = pix.tobytes("png")
                
                # Save temporary image
                temp_img_path = f"/tmp/docstrange_page_{page_num}.png"
                with open(temp_img_path, "wb") as f:
                    f.write(img_data)
                
                try:
                    # Process the page
                    page_result = self.process_image(temp_img_path)
                    results.append(f"## Page {page_num + 1}\n\n{page_result}")
                finally:
                    # Clean up temporary file
                    if os.path.exists(temp_img_path):
                        os.unlink(temp_img_path)
            
            doc.close()
            return "\n\n".join(results)
            
        except ImportError:
            logger.error("PyMuPDF not installed. Install with: pip install PyMuPDF")
            raise
        except Exception as e:
            logger.error(f"Error processing PDF {pdf_path}: {e}")
            raise
    
    def get_supported_formats(self) -> list:
        """Get list of supported file formats."""
        return ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp', '.pdf']
    
    def is_supported(self, file_path: str) -> bool:
        """Check if file format is supported."""
        ext = os.path.splitext(file_path)[1].lower()
        return ext in self.get_supported_formats()
    
    def can_process(self, file_path: str) -> bool:
        """Check if this processor can handle the file."""
        return self.is_supported(file_path)
    
    def process(self, file_path: str) -> ConversionResult:
        """
        Process a file and return a ConversionResult.
        
        Args:
            file_path: Path to the file to process
            
        Returns:
            ConversionResult containing the processed content
        """
        try:
            ext = os.path.splitext(file_path)[1].lower()
            
            if ext == '.pdf':
                content = self.process_pdf(file_path)
            else:
                content = self.process_image(file_path)
            
            # Create ConversionResult
            result = ConversionResult(
                content=content,
                metadata={
                    'processor': 'LocalNanonetsProcessor',
                    'model': 'Nanonets-OCR2-3B',
                    'file_path': file_path,
                    'file_type': ext
                }
            )
            
            return result
            
        except Exception as e:
            logger.error(f"Error processing {file_path}: {e}")
            raise
