import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';

class CustomerOrderConfirmationScreen extends StatefulWidget {
  final String orderId;
  final String otp;
  final double amount;
  final String service;
  final String address;
  final String scheduledTime;

  const CustomerOrderConfirmationScreen({
    required this.orderId,
    required this.otp,
    required this.amount,
    required this.service,
    required this.address,
    required this.scheduledTime,
    Key? key,
  }) : super(key: key);

  @override
  State<CustomerOrderConfirmationScreen> createState() =>
      _CustomerOrderConfirmationScreenState();
}

class _CustomerOrderConfirmationScreenState
    extends State<CustomerOrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyOtp() {
    Clipboard.setData(ClipboardData(text: widget.otp));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP copied to clipboard!'),
        backgroundColor: AppTheme.emerald,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareOtp() {
    final text =
        'Service completion OTP for order ${widget.orderId}: ${widget.otp}';
    // In real app, use share_plus package
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ready to share! Text copied.'),
        backgroundColor: AppTheme.saffron,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success animation
            Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.emerald.withOpacity(0.1),
                    AppTheme.emerald.withOpacity(0.05),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.emerald, Color(0xFF059669)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.emerald.withOpacity(0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Order Confirmed!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '₹${widget.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // OTP Section
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Completion OTP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 12),

                  // OTP Display
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF0EA5E9),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your OTP',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0369A1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.otp,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0369A1),
                                letterSpacing: 4,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: _copyOtp,
                              icon: Icon(Icons.content_copy_rounded),
                              color: Color(0xFF0369A1),
                            ),
                            Text(
                              'Copy',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF0369A1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _shareOtp,
                      icon: Icon(Icons.share_rounded),
                      label: Text('SHARE OTP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.saffron,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Info box
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color(0xFFFEF08A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_rounded, color: Color(0xFFD97706)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Share this OTP with your service provider to verify service completion',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Order Details
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildDetailRow(Icons.receipt_long_rounded, 'Order ID',
                      widget.orderId),
                  SizedBox(height: 12),
                  _buildDetailRow(
                      Icons.build_circle_rounded, 'Service', widget.service),
                  SizedBox(height: 12),
                  _buildDetailRow(
                      Icons.location_on_rounded, 'Address', widget.address),
                  SizedBox(height: 12),
                  _buildDetailRow(Icons.schedule_rounded, 'Scheduled',
                      widget.scheduledTime),
                  SizedBox(height: 24),

                  // Next Steps
                  Text(
                    'What Happens Next?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildStep('1', 'Vendor will be assigned',
                      'within 30 minutes'),
                  SizedBox(height: 12),
                  _buildStep('2', 'You\'ll get notification',
                      'when vendor arrives'),
                  SizedBox(height: 12),
                  _buildStep('3', 'Service will be completed',
                      'photos & payment proof'),
                  SizedBox(height: 12),
                  _buildStep('4', 'Rate the service',
                      'provide feedback'),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'BACK TO HOME',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Color(0xFF64748B)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String num, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.saffron, Color(0xFFE97316)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
