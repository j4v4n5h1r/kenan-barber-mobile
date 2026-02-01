import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../models/service_model.dart';
import '../../services/api_service.dart';

class SellerScannerScreen extends StatefulWidget {
  const SellerScannerScreen({super.key});

  @override
  State<SellerScannerScreen> createState() => _SellerScannerScreenState();
}

class _SellerScannerScreenState extends State<SellerScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final ApiService _apiService = ApiService();
  QRViewController? controller;
  String? scannedCode;
  List<Service>? services;
  bool isLoading = false;

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
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scannedCode == null) {
        setState(() {
          scannedCode = scanData.code;
        });
        controller.pauseCamera();
        _showServiceSelectionDialog();
      }
    });
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
      });
      controller?.resumeCamera();
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
      });
      controller?.resumeCamera();
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
        });
        controller?.resumeCamera();
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
              controller?.toggleFlash();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
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
