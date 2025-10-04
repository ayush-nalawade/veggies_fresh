import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/address.dart';
import '../../../services/profile_service.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final Address? address; // null for add, Address for edit

  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedType = 'home';
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _nameController.text = widget.address!.name;
      _line1Controller.text = widget.address!.line1;
      _line2Controller.text = widget.address!.line2 ?? '';
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _pincodeController.text = widget.address!.pincode;
      _countryController.text = widget.address!.country;
      _phoneController.text = widget.address!.phone;
      _selectedType = widget.address!.type;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final address = Address(
        id: widget.address?.id,
        type: _selectedType,
        name: _nameController.text.trim(),
        line1: _line1Controller.text.trim(),
        line2: _line2Controller.text.trim().isEmpty ? null : _line2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save address: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              decoration: const InputDecoration(
                labelText: 'Address Type',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
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

            // Address Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Address Name (e.g., My Home)',
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Address name is required';
                }
                if (value.trim().length < 2) {
                  return 'Address name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address Line 1
            TextFormField(
              controller: _line1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Address line 1 is required';
                }
                if (value.trim().length < 5) {
                  return 'Address line 1 must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address Line 2
            TextFormField(
              controller: _line2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2 (Optional)',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City *',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'City is required';
                }
                if (value.trim().length < 2) {
                  return 'City must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // State
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(
                labelText: 'State *',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'State is required';
                }
                if (value.trim().length < 2) {
                  return 'State must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Pincode
            TextFormField(
              controller: _pincodeController,
              decoration: const InputDecoration(
                labelText: 'Pincode *',
                prefixIcon: Icon(Icons.pin_drop),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pincode is required';
                }
                if (value.trim().length < 6) {
                  return 'Pincode must be at least 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country *',
                prefixIcon: Icon(Icons.public),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Country is required';
                }
                if (value.trim().length < 2) {
                  return 'Country must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.trim().length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
                return null;
              },
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
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.address == null ? 'Add Address' : 'Update Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
