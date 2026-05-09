
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';
import '../../models/booking.dart';
import '../../repositories/booking_repository.dart';
import './widgets/consignment_info_card_widget.dart';
import './widgets/customer_info_card_widget.dart';
import './widgets/financial_info_card_widget.dart';
import './widgets/profit_summary_widget.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _repository = BookingRepository();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form state
  final _consignmentController = TextEditingController();
  final _courierNameController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _weightController = TextEditingController();
  final _chargedController = TextEditingController();
  final _costController = TextEditingController();
  final _codAmountController = TextEditingController();
  String _paymentType = 'COD'; // COD or Prepaid

  double get _chargedAmount => double.tryParse(_chargedController.text) ?? 0.0;
  double get _costAmount => double.tryParse(_costController.text) ?? 0.0;
  double get _profit => _chargedAmount - _costAmount;

  @override
  void initState() {
    super.initState();
    _chargedController.addListener(() => setState(() {}));
    _costController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _consignmentController.dispose();
    _courierNameController.dispose();
    _customerNameController.dispose();
    _mobileController.dispose();
    _weightController.dispose();
    _chargedController.dispose();
    _costController.dispose();
    _codAmountController.dispose();
    super.dispose();
  }

  void _onPaymentTypeChanged(String type) {
    setState(() => _paymentType = type);
  }

  Future<void> _saveBooking() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackbar('Please fill all required fields');
      return;
    }

    if (_isSaving) return; // Prevent duplicate saves
    setState(() => _isSaving = true);

    try {
      final booking = Booking(
        consignmentNumber: _consignmentController.text.trim(),
        customerName: _customerNameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        weight: double.parse(_weightController.text),
        chargedAmount: _chargedAmount,
        costAmount: _costAmount,
        paymentType: _paymentType == 'COD' ? PaymentType.cod : PaymentType.prepaid,
        codAmount: _paymentType == 'COD'
            ? double.tryParse(_codAmountController.text) ?? 0.0
            : 0.0,
        courierName: _courierNameController.text.trim(),
      );

      await _repository.saveBooking(booking);

      if (!mounted) return;
      setState(() => _isSaving = false);

      _showSuccessSnackbar('Booking saved successfully');
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.bookingsListScreen,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        debugPrint('Error saving booking: $e');
        _showErrorSnackbar('Failed to save booking: ${e.toString()}');
      }
    }
  }

  void _onConsignmentScanned(String value) {
    setState(() {
      _consignmentController.text = value;
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: GoogleFonts.ibmPlexSans(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.ibmPlexSans(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: const Color(0x1A1565C0),
        leading: IconButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.bookingsListScreen,
            (r) => false,
          ),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A2340)),
        ),
        title: Text(
          'New Booking',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A2340),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 16,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 640 : double.infinity,
              ),
              child: Column(
                children: [
                  if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              ConsignmentInfoCardWidget(
                                consignmentController: _consignmentController,
                                courierNameController: _courierNameController,
                                onScanned: _onConsignmentScanned,
                              ),
                              const SizedBox(height: 12),
                              CustomerInfoCardWidget(
                                customerNameController: _customerNameController,
                                mobileController: _mobileController,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FinancialInfoCardWidget(
                            weightController: _weightController,
                            chargedController: _chargedController,
                            costController: _costController,
                            codAmountController: _codAmountController,
                            paymentType: _paymentType,
                            onPaymentTypeChanged: _onPaymentTypeChanged,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ConsignmentInfoCardWidget(
                      consignmentController: _consignmentController,
                      courierNameController: _courierNameController,
                      onScanned: _onConsignmentScanned,
                    ),
                    const SizedBox(height: 12),
                    CustomerInfoCardWidget(
                      customerNameController: _customerNameController,
                      mobileController: _mobileController,
                    ),
                    const SizedBox(height: 12),
                    FinancialInfoCardWidget(
                      weightController: _weightController,
                      chargedController: _chargedController,
                      costController: _costController,
                      codAmountController: _codAmountController,
                      paymentType: _paymentType,
                      onPaymentTypeChanged: _onPaymentTypeChanged,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Profit Summary Strip
                  ProfitSummaryWidget(
                    chargedAmount: _chargedAmount,
                    costAmount: _costAmount,
                    profit: _profit,
                  ),

                  // Bottom padding for FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveBooking,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(
          _isSaving ? 'Saving...' : 'Save Booking',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: const AppNavigation(currentIndex: 1),
    );
  }
}
