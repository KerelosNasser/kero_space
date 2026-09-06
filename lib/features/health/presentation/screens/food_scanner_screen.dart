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

  Future<void> _enterBarcodeManually() async {
    final controller = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 737628064502',
            labelText: 'Barcode Number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Lookup'),
          ),
        ],
      ),
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Looking up product...';
      });
      final product = await _barcodeService.getProductFromBarcode(barcode);
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
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text('Food Scanner', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flashlight',
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
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
                border: Border.all(color: colors.domainHealth, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colors.domainHealth),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
                    onPressed: _enterBarcodeManually,
                    backgroundColor: colors.domainHealth,
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    label: const Text('Barcode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    heroTag: 'ai_fab',
                    onPressed: _takePhotoAndAnalyze,
                    backgroundColor: colors.accentPrimary,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white),
                    label: const Text('AI Vision', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
