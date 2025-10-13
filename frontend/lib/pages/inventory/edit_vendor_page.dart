import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/inventory_service.dart';
import '../../models/vendor.dart' as vendor;

class EditVendorPage extends StatefulWidget {
  final vendor.Vendor vendorData;
  final VoidCallback onVendorUpdated;

  const EditVendorPage({
    super.key,
    required this.vendorData,
    required this.onVendorUpdated,
  });

  @override
  State<EditVendorPage> createState() => _EditVendorPageState();
}

class _EditVendorPageState extends State<EditVendorPage> {
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
  void initState() {
    super.initState();
    // Pre-fill form with existing vendor data
    _firstNameController.text = widget.vendorData.firstName;
    _lastNameController.text = widget.vendorData.lastName;
    _cnicController.text = widget.vendorData.cnic;
    _emailController.text = ''; // Email not available in current model
    _phoneController.text = ''; // Phone not available in current model
    _addressController.text = widget.vendorData.address ?? '';
    _selectedStatus = widget.vendorData.status;
    _selectedCityId = int.tryParse(widget.vendorData.cityId) ?? 1;
  }

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

      await InventoryService.updateVendor(widget.vendorData.id, vendorData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor updated successfully!'),
            backgroundColor: Color(0xFF28A745),
            duration: Duration(seconds: 2),
          ),
        );
        widget.onVendorUpdated();
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update vendor';
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
                    errorData['errors'] is Map) {
                  final errors = errorData['errors'] as Map<String, dynamic>;
                  setState(() {
                    _fieldErrors.clear();
                    errors.forEach((field, messages) {
                      if (messages is List && messages.isNotEmpty) {
                        // Map API field names to form field names
                        String formField = field;
                        if (field == 'city_id') formField = 'city';
                        _fieldErrors[formField] = messages.first.toString();
                      }
                    });
                  });
                  hasFieldErrors = true;

                  // Clear CNIC field if there's a CNIC validation error
                  if (_fieldErrors.containsKey('cnic')) {
                    _cnicController.clear();
                  }

                  // Re-validate form to show field errors
                  _formKey.currentState!.validate();
                } else if (errorData.containsKey('message')) {
                  errorMessage = errorData['message'].toString();
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
        title: const Text('Edit Vendor'),
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
                'Update',
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
                                Icons.edit,
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
                                    'Edit Vendor',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Update vendor information',
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
                            // First Name and Last Name Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      labelText: 'First Name *',
                                      hintText: 'Enter first name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      prefixIcon: const Icon(Icons.person),
                                      errorText: _fieldErrors['first_name'],
                                    ),
                                    onChanged: (value) {
                                      if (_fieldErrors.containsKey(
                                        'first_name',
                                      )) {
                                        setState(() {
                                          _fieldErrors.remove('first_name');
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (_fieldErrors.containsKey(
                                        'first_name',
                                      )) {
                                        return _fieldErrors['first_name'];
                                      }
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'First name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Last Name *',
                                      hintText: 'Enter last name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      prefixIcon: const Icon(Icons.person),
                                      errorText: _fieldErrors['last_name'],
                                    ),
                                    onChanged: (value) {
                                      if (_fieldErrors.containsKey(
                                        'last_name',
                                      )) {
                                        setState(() {
                                          _fieldErrors.remove('last_name');
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (_fieldErrors.containsKey(
                                        'last_name',
                                      )) {
                                        return _fieldErrors['last_name'];
                                      }
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Last name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // CNIC and Email Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cnicController,
                                    decoration: InputDecoration(
                                      labelText: 'CNIC *',
                                      hintText: '12345-1234567-1',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      prefixIcon: const Icon(Icons.credit_card),
                                      errorText: _fieldErrors['cnic'],
                                    ),
                                    onChanged: (value) {
                                      if (_fieldErrors.containsKey('cnic')) {
                                        setState(() {
                                          _fieldErrors.remove('cnic');
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (_fieldErrors.containsKey('cnic')) {
                                        return _fieldErrors['cnic'];
                                      }
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'CNIC is required';
                                      }
                                      // Basic CNIC format validation
                                      final cnicRegex = RegExp(
                                        r'^\d{5}-\d{7}-\d{1}$',
                                      );
                                      if (!cnicRegex.hasMatch(value.trim())) {
                                        return 'Invalid CNIC format';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'vendor@example.com',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      prefixIcon: const Icon(Icons.email),
                                      errorText: _fieldErrors['email'],
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (value) {
                                      if (_fieldErrors.containsKey('email')) {
                                        setState(() {
                                          _fieldErrors.remove('email');
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (_fieldErrors.containsKey('email')) {
                                        return _fieldErrors['email'];
                                      }
                                      if (value != null &&
                                          value.trim().isNotEmpty) {
                                        final emailRegex = RegExp(
                                          r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$',
                                        );
                                        if (!emailRegex.hasMatch(
                                          value.trim(),
                                        )) {
                                          return 'Invalid email format';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Phone and Status Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      labelText: 'Phone',
                                      hintText: '+923001234567',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      prefixIcon: const Icon(Icons.phone),
                                      errorText: _fieldErrors['phone'],
                                    ),
                                    keyboardType: TextInputType.phone,
                                    onChanged: (value) {
                                      if (_fieldErrors.containsKey('phone')) {
                                        setState(() {
                                          _fieldErrors.remove('phone');
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (_fieldErrors.containsKey('phone')) {
                                        return _fieldErrors['phone'];
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Status *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      prefixIcon: const Icon(Icons.toggle_on),
                                      errorText: _fieldErrors['status'],
                                    ),
                                    items: ['Active', 'Inactive'].map((status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedStatus = value;
                                          if (_fieldErrors.containsKey(
                                            'status',
                                          )) {
                                            _fieldErrors.remove('status');
                                          }
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (_fieldErrors.containsKey('status')) {
                                        return _fieldErrors['status'];
                                      }
                                      if (value == null || value.isEmpty) {
                                        return 'Status is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Address
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                hintText: 'Enter vendor address',
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
                              onChanged: (value) {
                                if (_fieldErrors.containsKey('address')) {
                                  setState(() {
                                    _fieldErrors.remove('address');
                                  });
                                }
                              },
                              validator: (value) {
                                if (_fieldErrors.containsKey('address')) {
                                  return _fieldErrors['address'];
                                }
                                return null;
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
                              child: const Text('Update Vendor'),
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
