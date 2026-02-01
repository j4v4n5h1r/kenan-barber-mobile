import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/service_model.dart';
import '../../services/api_service.dart';

class SellerScannerScreen extends StatefulWidget {
  const SellerScannerScreen({super.key});

  @override
  State<SellerScannerScreen> createState() => _SellerScannerScreenState();
}

class _SellerScannerScreenState extends State<SellerScannerScreen> {
  final ApiService _apiService = ApiService();
  final MobileScannerController controller = MobileScannerController();
  String? scannedCode;
  List<Service>? services;
  bool isLoading = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final loadedServices = await _apiService.getSellerServices();
      setState(() {
        services = loadedServices;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xidmətlər yüklənə bilmədi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    if (scannedCode == null) {
      setState(() {
        scannedCode = code;
        isProcessing = true;
      });
      controller.stop();
      _showServiceSelectionDialog();
    }
  }

  Future<void> _showServiceSelectionDialog() async {
    if (services == null || services!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hələ xidmət əlavə edilməyib'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        scannedCode = null;
        isProcessing = false;
      });
      controller.start();
      return;
    }

    final selectedService = await showDialog<Service>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xidmət Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: services!
              .map(
                (service) => ListTile(
                  title: Text(service.name),
                  subtitle: Text(
                    '${service.price.toStringAsFixed(2)} ₼ - Cashback: ${service.cashbackPercentage.toStringAsFixed(0)}%',
                  ),
                  onTap: () => Navigator.pop(context, service),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (selectedService != null) {
      await _processCashback(selectedService);
    } else {
      setState(() {
        scannedCode = null;
        isProcessing = false;
      });
      controller.start();
    }
  }

  Future<void> _processCashback(Service service) async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await _apiService.processCashback(
        customerQrCode: scannedCode!,
        serviceId: service.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Cashback uğurla əlavə edildi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          scannedCode = null;
          isLoading = false;
          isProcessing = false;
        });
        controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kodu Oxut'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () {
              controller.switchCamera();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator()
                  else if (scannedCode != null)
                    Text(
                      'QR Kod: $scannedCode',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  else
                    const Text(
                      'QR kodu kameranın qabağına tutun',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
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
