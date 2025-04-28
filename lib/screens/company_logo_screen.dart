import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/custom_scaffold.dart';
import '../theme/theme.dart';
import '../models/company.dart';
import '../providers/company_provider.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

class CompanyLogoScreen extends StatefulWidget {
  const CompanyLogoScreen({Key? key}) : super(key: key);

  @override
  State<CompanyLogoScreen> createState() => _CompanyLogoScreenState();
}

class _CompanyLogoScreenState extends State<CompanyLogoScreen> {
  bool _isLoading = false;
  String? _logoUrl;
  dynamic _pickedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Company? _company;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final company = companyProvider.currentCompany;
      
      if (company == null) {
        throw Exception('No company selected');
      }

      setState(() {
        _company = company;
        _logoUrl = company.logoUrl;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading company data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Web implementation
        final html.FileUploadInputElement input = html.FileUploadInputElement()
          ..accept = 'image/*';
        input.click();
        
        await input.onChange.first;
        if (input.files!.isEmpty) return;
        
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        
        await reader.onLoad.first;
        setState(() {
          _pickedImage = reader.result;
        });
      } else {
        // Mobile implementation
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        
        if (pickedFile != null) {
          setState(() {
            _pickedImage = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadLogo() async {
    if (_pickedImage == null || _company == null) return;
    
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('company_logos')
          .child('${_company!.id}.jpg');
      
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Web implementation
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
        );
        
        // Convert base64 to blob
        final imageData = _pickedImage.toString().split(',').last;
        final blob = html.Blob([imageData], 'image/jpeg');
        
        uploadTask = storageRef.putBlob(blob, metadata);
      } else {
        // Mobile implementation
        uploadTask = storageRef.putFile(_pickedImage);
      }
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });
      
      // Wait for upload to complete
      await uploadTask;
      
      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Update company document with logo URL
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_company!.id)
          .update({
        'logoUrl': downloadUrl,
      });
      
      // Update local company data
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final updatedCompany = _company!.copyWith(logoUrl: downloadUrl);
      await companyProvider.updateCompany(updatedCompany);
      
      setState(() {
        _logoUrl = downloadUrl;
        _pickedImage = null;
        _company = updatedCompany;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  bool get _isSubscribed {
    return _company?.subscription != null;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Company Logo',
      selectedIndex: 5, // Settings is selected
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subscription check
                  if (!_isSubscribed)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.amber[100]!,
                              Colors.amber[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.amber[800]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.amber[800],
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Premium Feature',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[800],
                                          fontSize: 22,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Upgrade to add your company logo',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber[200]!,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildPremiumFeature(
                                    'Add your company logo to invoices',
                                    Icons.insert_drive_file,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPremiumFeature(
                                    'Enhance your brand identity',
                                    Icons.branding_watermark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPremiumFeature(
                                    'Look more professional to clients',
                                    Icons.business,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/subscription');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[800],
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.star),
                                    SizedBox(width: 12),
                                    Text(
                                      'Upgrade Now',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  if (_isSubscribed) ...[
                    // Logo section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.8),
                              AppTheme.accentColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Company Logo',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your logo will appear on invoices and other company documents',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 32),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: _pickedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _pickedImage is File
                                            ? Image.file(
                                                _pickedImage,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                _pickedImage.toString(),
                                                fit: BoxFit.cover,
                                              ),
                                      )
                                    : _logoUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              _logoUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 80,
                                                color: AppTheme.primaryColor.withOpacity(0.7),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Click to add logo',
                                                style: TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            if (_pickedImage != null) ...[
                              _isUploading
                                  ? Container(
                                      width: 220,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Column(
                                        children: [
                                          LinearProgressIndicator(
                                            value: _uploadProgress,
                                            backgroundColor: Colors.white.withOpacity(0.3),
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: _uploadLogo,
                                      icon: const Icon(Icons.cloud_upload),
                                      label: const Text('Upload Logo'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppTheme.accentColor,
                                        elevation: 3,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                            ],
                            if (_logoUrl != null && _pickedImage == null) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.edit),
                                label: const Text('Change Logo'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Logo guidelines
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Logo Guidelines',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            _buildGuideline('Use a square or rectangular image for best results'),
                            _buildGuideline('Recommended size: 800x800 pixels or larger'),
                            _buildGuideline('Supported formats: JPG, PNG, GIF'),
                            _buildGuideline('Maximum file size: 5MB'),
                            _buildGuideline('Use a transparent background for best appearance on invoices'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
  
  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPremiumFeature(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.amber[800],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
