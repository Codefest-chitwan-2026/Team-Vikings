import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../models/picked_location.dart';
import '../../widgets/donor/add_donation/food_category_selector.dart';
import '../../widgets/donor/add_donation/listing_type_toggle.dart';
import '../../widgets/donor/add_donation/photo_upload_area.dart';
import '../../widgets/donor/add_donation/pickup_address_picker.dart';
import '../../widgets/donor/add_donation/pickup_window_dropdown.dart';
import '../../widgets/donor/shared/donor_app_bar.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../shared/map_address_picker_screen.dart';
import 'listing_success_screen.dart';


class AddDonationScreen extends StatefulWidget {
  const AddDonationScreen({super.key});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _servesController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();

  FoodCategory _selectedCategory = FoodCategory.veg;
  ListingType _listingType = ListingType.donateFree;
  String _pickupWindow = '30 minutes';
  PickedLocation? _selectedLocation;
  String? _pickupAddressError;
  bool _isLoading = false;

  static const _pickupOptions = [
    '15 minutes',
    '30 minutes',
    '45 minutes',
    '1 hour',
  ];

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _servesController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final selectedLocation = _selectedLocation;
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapAddressPickerScreen(
          initialLocation: selectedLocation == null
              ? null
              : LatLng(selectedLocation.latitude, selectedLocation.longitude),
          selectionHint:
              'Tap anywhere on the map to select the pickup location.',
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedLocation = result;
      _pickupAddressError = null;
    });
  }

  Future<void> _submitDonation() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      setState(() => _pickupAddressError = 'Select pickup address on map');
      return;
    }

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ListingSuccessScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String label) {
    return value == null || value.trim().isEmpty ? 'Enter $label' : null;
  }

  String? _price(String? value, String label) {
    final requiredError = _required(value, label);
    if (requiredError != null) return requiredError;

    final price = double.tryParse(value!.trim());
    if (price == null || price <= 0) return 'Enter a valid $label';
    return null;
  }

  String? _validateDiscountedPrice(String? value) {
    final priceError = _price(value, 'discounted price');
    if (priceError != null) return priceError;

    final originalText = _originalPriceController.text.trim();
    if (originalText.isEmpty) return null;

    final original = double.tryParse(originalText);
    final discounted = double.tryParse(value!.trim());
    if (original != null &&
        discounted != null &&
        discounted >= original) {
      return 'Must be less than original price';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DonorAppBar(
        title: 'Add Donation',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              FoodCategorySelector(
                selected: _selectedCategory,
                onChanged: (category) => setState(() => _selectedCategory = category),
              ),
              const SizedBox(height: 20),
              PhotoUploadArea(onTap: () => _showMessage('Photo upload coming soon.')),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Food item name',
                hintText: 'e.g. Rice bowl with curry',
                controller: _foodNameController,
                validator: (value) => _required(value, 'food item name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Quantity (plates)',
                      hintText: '10',
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      validator: (value) => _required(value, 'quantity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Serves approx.',
                      hintText: '15 people',
                      controller: _servesController,
                      validator: (value) => _required(value, 'serves count'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PickupWindowDropdown(
                value: _pickupWindow,
                options: _pickupOptions,
                onChanged: (value) => setState(() => _pickupWindow = value),
              ),
              const SizedBox(height: 20),
              const Text(
                'How should it be listed?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ListingTypeToggle(
                selected: _listingType,
                onChanged: (type) => setState(() => _listingType = type),
              ),
              if (_listingType == ListingType.discountedSale) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Original price',
                        hintText: 'e.g. 500',
                        controller: _originalPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _price(value, 'original price'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Price after discount',
                        hintText: 'e.g. 200',
                        controller: _discountedPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateDiscountedPrice,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              PickupAddressPicker(
                location: _selectedLocation,
                onTap: _openMapPicker,
                errorText: _pickupAddressError,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Post donation',
                isLoading: _isLoading,
                onPressed: _submitDonation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
