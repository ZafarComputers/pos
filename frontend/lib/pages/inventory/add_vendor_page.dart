import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/inventory_service.dart';

class AddVendorPage extends StatefulWidget {
  const AddVendorPage({super.key});

  @override
  State<AddVendorPage> createState() => _AddVendorPageState();
}

class _AddVendorPageState extends State<AddVendorPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedStatus = 'Active';
  int _selectedCityId = 1; // Default city ID
  bool _isLoading = false;
  Map<String, String> _fieldErrors = {}; // Store field-specific errors

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _fieldErrors.clear(); // Clear previous field errors
    });

    try {
      final vendorData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'city_id': _selectedCityId,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'status': _selectedStatus,
      };

      // Remove null values
      vendorData.removeWhere((key, value) => value == null);

      await InventoryService.createVendor(vendorData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor added successfully!'),
            backgroundColor: Color(0xFF28A745),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to add vendor';
        bool hasFieldErrors = false;

        // Try to parse validation errors from the API response
        if (e.toString().contains('Inventory API failed')) {
          try {
            // Extract the response body from the error message
            final errorParts = e.toString().split(' - ');
            if (errorParts.length >= 2) {
              final responseBody = errorParts[1];
              final errorData = jsonDecode(responseBody);

              if (errorData is Map<String, dynamic>) {
                // Check for Laravel validation errors
                if (errorData.containsKey('errors') &&
                    errorData['errors'] is Map<String, dynamic>) {
                  final errors = errorData['errors'] as Map<String, dynamic>;
                  setState(() {
                    _fieldErrors = errors.map((key, value) {
                      if (value is List && value.isNotEmpty) {
                        return MapEntry(key, value.first.toString());
                      }
                      return MapEntry(key, value.toString());
                    });
                  });
                  hasFieldErrors = true;
                  // Re-validate to show field errors
                  _formKey.currentState!.validate();
                } else if (errorData.containsKey('message')) {
                  errorMessage = errorData['message'];
                }
              }
            }
          } catch (parseError) {
            // If parsing fails, use the original error
            errorMessage = e.toString();
          }
        } else {
          errorMessage = e.toString();
        }

        // Only show snackbar if there are no field-specific errors
        if (!hasFieldErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Color(0xFFDC3545),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Vendor'),
        backgroundColor: const Color(0xFF0D1845),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: const Text(
                'Add Vendor',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF8F9FA)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D1845)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF0D1845).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.business,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add New Vendor',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enter vendor details to add them to the system',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form Fields
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // First Name Field
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.person),
                                errorText: _fieldErrors['first_name'],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter first name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Last Name Field
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.person),
                                errorText: _fieldErrors['last_name'],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter last name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // CNIC Field
                            TextFormField(
                              controller: _cnicController,
                              decoration: InputDecoration(
                                labelText: 'CNIC *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.credit_card),
                                errorText: _fieldErrors['cnic'],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter CNIC';
                                }
                                // Basic CNIC validation (13 digits)
                                final cnicRegex = RegExp(r'^\d{13}$');
                                if (!cnicRegex.hasMatch(
                                  value.replaceAll('-', ''),
                                )) {
                                  return 'Please enter a valid CNIC (13 digits)';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.email),
                                errorText: _fieldErrors['email'],
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final emailRegex = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Phone Field
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.phone),
                                errorText: _fieldErrors['phone'],
                              ),
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 16),

                            // City Dropdown (simplified for now)
                            DropdownButtonFormField<int>(
                              value: _selectedCityId,
                              decoration: InputDecoration(
                                labelText: 'City *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.location_city),
                                errorText: _fieldErrors['city_id'],
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('Lahore'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('Karachi'),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text('Islamabad'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCityId = value);
                                }
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a city';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Address Field
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Address (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.home),
                                errorText: _fieldErrors['address'],
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 16),

                            // Status Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                labelText: 'Status *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.toggle_on),
                                errorText: _fieldErrors['status'],
                              ),
                              items: ['Active', 'Inactive']
                                  .map(
                                    (status) => DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedStatus = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Color(0xFF6C757D)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF28A745),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Add Vendor'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
