import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../models/picked_location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
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
  final DonationItem? donationToEdit;
  final String? prefilledTitle;
  final String? prefilledQuantity;
  final FoodCategory? prefilledCategory;
  final String? prefilledServes;
  final String? prefilledAddress;

  const AddDonationScreen({
    super.key,
    this.donationToEdit,
    this.prefilledTitle,
    this.prefilledQuantity,
    this.prefilledCategory,
    this.prefilledServes,
    this.prefilledAddress,
  });

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _servesController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();

  late FoodCategory _selectedCategory;
  late ListingType _listingType;
  String _pickupWindow = '2 hours';
  PickedLocation? _selectedLocation;
  String? _selectedImagePath;
  String? _pickupAddressError;
  bool _isLoading = false;

  static const _pickupOptions = [
    '2 hours',
    '3 hours',
    '4 hours',
    '6 hours',
    '8 hours',
  ];

  @override
  void initState() {
    super.initState();
    final toEdit = widget.donationToEdit;

    if (toEdit != null) {
      _selectedCategory = toEdit.category;
      _listingType = toEdit.listingType;
      _pickupWindow = toEdit.pickupWindow;
      _foodNameController.text = toEdit.title.split('·').first.trim();
      _quantityController.text = toEdit.quantity.toString();
      _servesController.text = toEdit.servesApprox;
      _selectedImagePath = toEdit.imagePath;

      if (toEdit.originalPrice != null) {
        _originalPriceController.text = toEdit.originalPrice!.toString();
      }
      if (toEdit.discountedPrice != null) {
        _discountedPriceController.text = toEdit.discountedPrice!.toString();
      }

      _selectedLocation = PickedLocation(
        latitude: toEdit.pickupLatitude ?? 27.7215,
        longitude: toEdit.pickupLongitude ?? 85.3206,
        address: toEdit.pickupAddress,
      );
    } else {
      _selectedCategory = widget.prefilledCategory ?? FoodCategory.veg;
      _listingType = ListingType.donateFree;
      if (widget.prefilledTitle != null) {
        _foodNameController.text = widget.prefilledTitle!;
      }
      if (widget.prefilledQuantity != null) {
        _quantityController.text = widget.prefilledQuantity!;
      }
      if (widget.prefilledServes != null) {
        _servesController.text = widget.prefilledServes!;
      }
      if (widget.prefilledAddress != null) {
        _selectedLocation = PickedLocation(
          latitude: 27.7215,
          longitude: 85.3206,
          address: widget.prefilledAddress!,
        );
      }
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
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
          selectionHint: 'Tap anywhere on the map to select the pickup location.',
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
      setState(() => _pickupAddressError = 'Please select a pickup address on the map');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final donationProvider = context.read<DonationProvider>();
    final isEditing = widget.donationToEdit != null;
    final foodName = _foodNameController.text.trim();
    final description = _descriptionController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 10;
    final serves = _servesController.text.trim();
    final originalPrice = double.tryParse(_originalPriceController.text.trim());
    final discountedPrice = double.tryParse(_discountedPriceController.text.trim());

    final servesCount = int.tryParse(serves.replaceAll(RegExp(r'\D'), '')) ?? (quantity * 2);

    String foodTypeStr = 'VEG';
    if (_selectedCategory == FoodCategory.nonVeg) foodTypeStr = 'NONVEG';
    if (_selectedCategory == FoodCategory.mixed) foodTypeStr = 'MIXED';

    if (isEditing) {
      final updated = widget.donationToEdit!.copyWith(
        title: '$foodName · $quantity Plates',
        category: _selectedCategory,
        quantity: quantity,
        servesApprox: serves,
        pickupAddress: _selectedLocation!.address,
        pickupLatitude: _selectedLocation!.latitude,
        pickupLongitude: _selectedLocation!.longitude,
        pickupWindow: _pickupWindow,
        listingType: _listingType,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        imagePath: _selectedImagePath,
      );
      donationProvider.updateDonation(updated);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      final success = await donationProvider.createDonationOnApi(
        token: authProvider.currentUser?.token,
        title: foodName,
        description: description.isEmpty
            ? 'Freshly prepared food items ready for immediate collection.'
            : description,
        foodType: foodTypeStr,
        quantity: quantity.toDouble(),
        quantityUnit: 'Plates',
        peopleServed: servesCount,
        bestBefore: DateTime.now().add(const Duration(hours: 4)),
        pickupAddress: _selectedLocation!.address,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        listingType: _listingType == ListingType.discountedSale ? 'FLASH_SALE' : 'DONATION',
        price: originalPrice,
        flashSalePrice: discountedPrice,
        imagePath: _selectedImagePath,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ListingSuccessScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(donationProvider.errorMessage ?? 'Failed to publish food listing. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
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
    if (original != null && discounted != null && discounted >= original) {
      return 'Must be less than original price';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.donationToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DonorAppBar(
        title: isEditing ? 'Edit Donation' : 'Add Donation',
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
              PhotoUploadArea(
                imagePath: _selectedImagePath,
                onImageSelected: (path) => setState(() => _selectedImagePath = path),
                onImageRemoved: () => setState(() => _selectedImagePath = null),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Food item name',
                hintText: 'e.g. Rice bowl with curry',
                controller: _foodNameController,
                validator: (value) => _required(value, 'food item name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                hintText: 'e.g. Freshly cooked, contains rice, lentils, and mixed vegetables',
                controller: _descriptionController,
                maxLines: 3,
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
                      validator: (value) {
                        final req = _required(value, 'quantity');
                        if (req != null) return req;
                        final n = int.tryParse(value!.trim());
                        if (n == null || n <= 0) return 'Invalid quantity';
                        return null;
                      },
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
                initialValue: _pickupWindow,
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
                        label: 'Original price (Rs)',
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
                        label: 'Price after discount (Rs)',
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
                text: isEditing ? 'Save Changes' : 'Post donation',
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