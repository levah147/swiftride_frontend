import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:swiftride/services/api_client.dart';
import '../../constants/colors.dart';
import '../../constants/app_dimensions.dart';
import '../../services/driver_service.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final DriverService _driverService = DriverService();
  final ImagePicker _imagePicker = ImagePicker();

  // Document upload states
  Map<String, bool> _documentUploaded = {
    'license': false,
    'registration': false,
    'insurance': false,
    'vehicle_picture': false,
    'driver_picture': false,
  };

  Map<String, bool> _uploading = {
    'license': false,
    'registration': false,
    'insurance': false,
    'vehicle_picture': false,
    'driver_picture': false,
  };

  @override
  void initState() {
    super.initState();
    _checkUploadStatus();
  }

  Future<void> _checkUploadStatus() async {
    try {
      final response = await _driverService.getDocumentsStatus();
      if (response.isSuccess && mounted) {
        final data = response.data as Map<String, dynamic>;
        final documents = data['documents'] as List;
        
        setState(() {
          for (var doc in documents) {
            _documentUploaded[doc['document_type']] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking upload status: $e');
    }
  }

  Future<void> _uploadDocument(String documentType, bool isImage) async {
    try {
      String? filePath;

      if (isImage) {
        final pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        filePath = pickedFile?.path;
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        filePath = result?.files.single.path;
      }

      if (filePath == null) {
        _showErrorSnackBar('No file selected');
        return;
      }

      setState(() => _uploading[documentType] = true);
      debugPrint('📤 Uploading $documentType from: $filePath');

      late ApiResponse<Map<String, dynamic>> response;

      if (isImage) {
        response = await _driverService.uploadVehicleImage(
          imageType: documentType,
          imagePath: filePath,
        );
      } else {
        response = await _driverService.uploadVerificationDocument(
          documentType: documentType,
          filePath: filePath,
        );
      }

      if (!mounted) return;

      setState(() => _uploading[documentType] = false);

      if (response.isSuccess) {
        setState(() => _documentUploaded[documentType] = true);
        _showSuccessSnackBar('${_getDocumentLabel(documentType)} uploaded successfully!');
        debugPrint('✅ Upload successful for $documentType');
      } else {
        _showErrorSnackBar(response.error ?? 'Failed to upload document');
        debugPrint('❌ Upload failed for $documentType: ${response.error}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading[documentType] = false);
        _showErrorSnackBar('Error: $e');
        debugPrint('❌ Exception uploading $documentType: $e');
      }
    }
  }

  String _getDocumentLabel(String type) {
    switch (type) {
      case 'license':
        return 'Driver License';
      case 'registration':
        return 'Vehicle Registration';
      case 'insurance':
        return 'Insurance Document';
      case 'vehicle_picture':
        return 'Vehicle Picture';
      case 'driver_picture':
        return 'Driver Picture';
      default:
        return 'Document';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _allDocumentsUploaded => _documentUploaded.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Verify Your Documents',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Documents Uploaded',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_documentUploaded.values.where((v) => v).length}/${_documentUploaded.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _documentUploaded.values.where((v) => v).length / _documentUploaded.length,
                      minHeight: 6,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Documents Section
            const Text(
              'Required Documents',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Driver License
            _buildDocumentUploadCard(
              type: 'license',
              label: 'Driver License',
              icon: Icons.credit_card,
              isImage: false,
            ),

            const SizedBox(height: 12),

            // Vehicle Registration
            _buildDocumentUploadCard(
              type: 'registration',
              label: 'Vehicle Registration',
              icon: Icons.description,
              isImage: false,
            ),

            const SizedBox(height: 12),

            // Insurance Document
            _buildDocumentUploadCard(
              type: 'insurance',
              label: 'Insurance Document',
              icon: Icons.shield,
              isImage: false,
            ),

            const SizedBox(height: 24),

            // Vehicle Images Section
            const Text(
              'Vehicle Images',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Vehicle Picture
            _buildDocumentUploadCard(
              type: 'vehicle_picture',
              label: 'Vehicle Picture',
              icon: Icons.directions_car,
              isImage: true,
            ),

            const SizedBox(height: 12),

            // Driver Picture
            _buildDocumentUploadCard(
              type: 'driver_picture',
              label: 'Driver Picture',
              icon: Icons.person,
              isImage: true,
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allDocumentsUploaded
                    ? () {
                        _showSuccessSnackBar('All documents submitted for review!');
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _allDocumentsUploaded ? 'Complete Application' : 'Upload All Documents',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What happens next?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our admin team will review your documents within 24-48 hours. You\'ll receive a notification once your application is approved or if we need more information.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadCard({
    required String type,
    required String label,
    required IconData icon,
    required bool isImage,
  }) {
    final isUploaded = _documentUploaded[type] ?? false;
    final isUploading = _uploading[type] ?? false;

    return GestureDetector(
      onTap: isUploading ? null : () => _uploadDocument(type, isImage),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.primary.withOpacity(0.1) : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded ? AppColors.primary : Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUploaded ? AppColors.primary : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUploaded
                        ? 'Uploaded'
                        : isImage
                            ? 'Upload image'
                            : 'Upload document (PDF, JPG, PNG)',
                    style: TextStyle(
                      color: isUploaded ? AppColors.primary : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Status Icon
            if (isUploading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else if (isUploaded)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              )
            else
              Icon(
                Icons.cloud_upload_outlined,
                color: Colors.grey[600],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}