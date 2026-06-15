import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:kero_space/features/health/data/services/barcode_service.dart';
import 'package:kero_space/features/health/data/services/ai_scanner_service.dart';
import 'dart:convert';
import 'dart:io';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  final BarcodeService _barcodeService = GetIt.I<BarcodeService>();
  final AiScannerService _aiScannerService = GetIt.I<AiScannerService>();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isProcessing = false;
  String _statusMessage = 'Scanning barcode...';

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? barcodeValue = barcodes.first.rawValue;
      if (barcodeValue != null) {
        setState(() {
          _isProcessing = true;
          _statusMessage = 'Looking up product...';
        });

        final product = await _barcodeService.getProductFromBarcode(barcodeValue);
        
        if (!mounted) return;
        if (product != null) {
          context.pushReplacement('/health/log', extra: product);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found in OpenFoodFacts.')),
          );
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Scanning barcode...';
          });
          // Add a short delay before re-scanning is allowed, if needed
        }
      }
    }
  }

  Future<void> _takePhotoAndAnalyze() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Opening camera...';
    });
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Compress to save tokens
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Scanning barcode...';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Analyzing food with AI...';
    });

    final bytes = await File(image.path).readAsBytes();
    final base64String = base64Encode(bytes);

    final result = await _aiScannerService.scanFoodImage(base64String);

    if (!mounted) return;
    if (result != null) {
      context.pushReplacement('/health/log', extra: result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to analyze image. Check your OpenRouter key.')),
      );
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Scanning barcode...';
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Food Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // Scanner Overlay Reticle
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentMint, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          if (_isProcessing)
            Container(
              color: AppTheme.bgOverlay,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.accentMint),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
          // Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'barcode_fab',
                    onPressed: () {},
                    backgroundColor: AppTheme.accentMint,
                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.bgPrimary),
                    label: const Text('Barcode', style: TextStyle(color: AppTheme.bgPrimary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    heroTag: 'ai_fab',
                    onPressed: _takePhotoAndAnalyze,
                    backgroundColor: AppTheme.accentViolet,
                    icon: const Icon(Icons.auto_awesome, color: AppTheme.textPrimary),
                    label: const Text('AI Vision', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
