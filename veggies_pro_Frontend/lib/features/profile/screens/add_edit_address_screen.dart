import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/address.dart';
import '../../../services/profile_service.dart';
import '../../../core/error_handler.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final Address? address; // null for add, Address for edit

  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();
  
  String _selectedType = 'home';
  String? _selectedArea; // Area dropdown
  bool _isDefault = false;
  bool _isLoading = false;
  
  // Area to pincode mapping
  final Map<String, String> _areaToPincode = {
    'Kandivali (W)': '400067',
    'Malad (W)': '400064',
  };

  @override
  void initState() {
    super.initState();
    // Set default values for City, State, and Country
    _cityController.text = 'Mumbai';
    _stateController.text = 'Maharashtra';
    _countryController.text = 'India';
    
    if (widget.address != null) {
      _line1Controller.text = widget.address!.line1;
      _line2Controller.text = widget.address!.line2 ?? '';
      _landmarkController.text = widget.address!.landmark ?? '';
      _pincodeController.text = widget.address!.pincode;
      _selectedType = widget.address!.type;
      _isDefault = widget.address!.isDefault;
      
      // Try to match pincode to area
      _areaToPincode.forEach((area, pincode) {
        if (pincode == widget.address!.pincode) {
          _selectedArea = area;
        }
      });
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if area is selected
    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final address = Address(
        id: widget.address?.id,
        type: _selectedType,
        line1: _line1Controller.text.trim(),
        line2: _line2Controller.text.trim().isEmpty ? null : _line2Controller.text.trim(),
        landmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
        area: _selectedArea, // Save the selected area
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        country: _countryController.text.trim(),
        phone: '1234567890', // Default phone number
        isDefault: _isDefault,
      );

      if (widget.address == null) {
        await ProfileService().addAddress(address);
      } else {
        await ProfileService().updateAddress(widget.address!.id!, address);
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.address == null ? 'Address added successfully' : 'Address updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      
      // Use centralized error handling
      await ErrorHandler.handleError(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAddress,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Address Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Address Type',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('Home')),
                DropdownMenuItem(value: 'work', child: Text('Work')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Flat no/ Building name
            TextFormField(
              controller: _line1Controller,
              decoration: InputDecoration(
                labelText: 'Flat no/ Building name *',
                prefixIcon: const Icon(Icons.home),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Flat no/ Building name is required';
                }
                if (value.trim().length < 3) {
                  return 'Please enter a valid flat no or building name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Sector/ Locality
            TextFormField(
              controller: _line2Controller,
              decoration: InputDecoration(
                labelText: 'Sector/ Locality (Optional)',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Landmark
            TextFormField(
              controller: _landmarkController,
              decoration: InputDecoration(
                labelText: 'Landmark (Optional)',
                prefixIcon: const Icon(Icons.place),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintText: '',
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Area Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We deliver to Kandivali (W) and Malad (W) areas',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Area Dropdown
            DropdownButtonFormField<String>(
              value: _selectedArea,
              decoration: InputDecoration(
                labelText: 'Delivery Area *',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _areaToPincode.keys.map((String area) {
                return DropdownMenuItem<String>(
                  value: area,
                  child: Text(area),
                );
              }).toList(),
              onChanged: (String? newArea) {
                setState(() {
                  _selectedArea = newArea;
                  if (newArea != null) {
                    _pincodeController.text = _areaToPincode[newArea]!;
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a delivery area';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // City (Read-only)
            TextFormField(
              controller: _cityController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'City *',
                prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // State (Read-only)
            TextFormField(
              controller: _stateController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'State *',
                prefixIcon: const Icon(Icons.map, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Pincode (Auto-filled and read-only)
            TextFormField(
              controller: _pincodeController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Pincode *',
                prefixIcon: const Icon(Icons.pin_drop, color: Colors.grey),
                suffixIcon: _selectedArea != null
                    ? Icon(Icons.check_circle, color: Colors.green[600], size: 20)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _selectedArea != null ? Colors.green[200]! : Colors.grey,
                    width: 1,
                  ),
                ),
                filled: true,
                fillColor: _selectedArea != null ? Colors.green[50] : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintText: 'Select area to auto-fill',
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: TextStyle(
                  color: _selectedArea != null ? Colors.green[700] : Colors.grey,
                ),
              ),
              style: TextStyle(
                color: _selectedArea != null ? Colors.green[900] : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select a delivery area';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country (Read-only)
            TextFormField(
              controller: _countryController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Country *',
                prefixIcon: const Icon(Icons.public, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintStyle: const TextStyle(color: Colors.grey),
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Set as Default
            CheckboxListTile(
              title: const Text('Set as default address'),
              subtitle: const Text('This will be used for future orders'),
              value: _isDefault,
              onChanged: (value) {
                setState(() => _isDefault = value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.address == null ? 'Add Address' : 'Update Address',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}