#!/usr/bin/env python3
"""
Test script for VPS deployment verification
Checks that the local model is used and no authentication is required
"""

import sys
import os
import logging
from pathlib import Path

# Add the project to Python path
sys.path.insert(0, str(Path(__file__).parent))

def test_imports():
    """Test that all required modules can be imported."""
    print("🔍 Testing imports...")
    try:
        from docstrange.extractor import DocumentExtractor
        from docstrange.processors.local_nanonets_processor import LocalNanonetsProcessor
        print("✅ All imports successful")
        return True
    except Exception as e:
        print(f"❌ Import error: {e}")
        return False

def test_extractor_initialization():
    """Test that extractor initializes without authentication."""
    print("\n🔍 Testing extractor initialization...")
    try:
        from docstrange.extractor import DocumentExtractor
        extractor = DocumentExtractor()
        print("✅ Extractor initialized successfully")
        
        # Check that local processor is added
        processor_types = [type(p).__name__ for p in extractor.processors]
        if 'LocalNanonetsProcessor' in processor_types:
            print("✅ Local Nanonets processor is configured")
        else:
            print("❌ Local Nanonets processor not found")
            return False
            
        # Check supported formats
        formats = extractor.get_supported_formats()
        if formats:
            print(f"✅ Supported formats: {formats}")
        else:
            print("❌ No supported formats found")
            return False
            
        return True
    except Exception as e:
        print(f"❌ Extractor initialization error: {e}")
        return False

def test_local_processor():
    """Test that local processor can be initialized."""
    print("\n🔍 Testing local processor...")
    try:
        from docstrange.processors.local_nanonets_processor import LocalNanonetsProcessor
        processor = LocalNanonetsProcessor()
        print("✅ Local processor initialized")
        
        # Check device detection
        if processor.device:
            print(f"✅ Device detected: {processor.device}")
        else:
            print("❌ No device detected")
            return False
            
        # Check supported formats
        formats = processor.get_supported_formats()
        if formats:
            print(f"✅ Processor supports: {formats}")
        else:
            print("❌ No formats supported by processor")
            return False
            
        return True
    except Exception as e:
        print(f"❌ Local processor error: {e}")
        return False

def test_no_authentication():
    """Test that no authentication is required."""
    print("\n🔍 Testing authentication requirements...")
    try:
        from docstrange.extractor import DocumentExtractor
        # Try to create extractor without any API key
        extractor = DocumentExtractor(api_key=None)
        print("✅ Extractor created without API key")
        
        # Check that local processor is primary
        if extractor.processors:
            primary_processor = extractor.processors[0]
            if 'LocalNanonetsProcessor' in str(type(primary_processor)):
                print("✅ Local processor is primary (no authentication required)")
                return True
            else:
                print("❌ Local processor is not primary")
                return False
        else:
            print("❌ No processors configured")
            return False
            
    except Exception as e:
        print(f"❌ Authentication test error: {e}")
        return False

def test_model_download():
    """Test that model can be downloaded (without actually downloading)."""
    print("\n🔍 Testing model download capability...")
    try:
        from transformers import AutoTokenizer, AutoProcessor, AutoModelForImageTextToText
        
        model_path = "nanonets/Nanonets-OCR2-3B"
        print(f"✅ Model path configured: {model_path}")
        
        # Test tokenizer download (lightweight)
        print("📥 Testing tokenizer download...")
        tokenizer = AutoTokenizer.from_pretrained(model_path)
        print("✅ Tokenizer download successful")
        
        # Test processor download (lightweight)
        print("📥 Testing processor download...")
        processor = AutoProcessor.from_pretrained(model_path)
        print("✅ Processor download successful")
        
        return True
    except Exception as e:
        print(f"❌ Model download test error: {e}")
        return False

def main():
    """Run all tests."""
    print("🚀 DocStrange VPS Setup Test")
    print("=" * 40)
    
    tests = [
        test_imports,
        test_extractor_initialization,
        test_local_processor,
        test_no_authentication,
        test_model_download
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()
    
    print("=" * 40)
    print(f"📊 Test Results: {passed}/{total} passed")
    
    if passed == total:
        print("🎉 All tests passed! VPS setup is ready.")
        print("\n📋 Next steps:")
        print("1. Upload the project to your VPS")
        print("2. Run: chmod +x deploy_vps.sh")
        print("3. Run: ./deploy_vps.sh")
        print("4. The model will download automatically on first use")
        return 0
    else:
        print("❌ Some tests failed. Please check the errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
