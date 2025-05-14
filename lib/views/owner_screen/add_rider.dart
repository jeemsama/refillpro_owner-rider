import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AddRider extends StatefulWidget {
  const AddRider({super.key});

  @override
  State<AddRider> createState() => _AddRiderState();
}

class RiderItem {
  final int id;
  final String name;
  final String contactNumber;

  RiderItem({
    required this.id,
    required this.name,
    required this.contactNumber,
  });
}

class _AddRiderState extends State<AddRider> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode contactNumberFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool obscurePassword = true;
  bool isLoading = false;
  String errorMessage = '';

  List<RiderItem> riders = [];

  @override
  void initState() {
    super.initState();
    _fetchRiders();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    passwordController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    contactNumberFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchRiders() async {
    final token = await _getToken();
    if (token == null) return;

    final url = Uri.parse('http://192.168.1.7:8000/api/riders');
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<Map<String, dynamic>> list;
        if (decoded is List) {
          list = List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map<String, dynamic>) {
          list =
              decoded.entries
                  .where((e) => int.tryParse(e.key) != null)
                  .map((e) => Map<String, dynamic>.from(e.value))
                  .toList();
        } else {
          list = [];
        }

        setState(() {
          riders =
              list
                  .map(
                    (r) => RiderItem(
                      id: r['id'] as int,
                      name: r['name'] as String,
                      contactNumber: r['phone'] as String? ?? '',
                    ),
                  )
                  .toList();
        });
      } else {
        debugPrint('Failed to fetch riders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ _fetchRiders error: $e');
    }
  }

  Future<void> _addRider() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String contact = contactNumberController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || contact.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please log in.')),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      final url = Uri.parse('http://192.168.1.7:8000/api/riders');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': contact,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _fetchRiders();
        nameController.clear();
        emailController.clear();
        contactNumberController.clear();
        passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider added successfully!')),
        );
      } else {
        final err = jsonDecode(response.body);
        setState(() {
          errorMessage = err['message'] ?? 'Failed to add rider';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } on SocketException catch (e) {
      setState(() {
        errorMessage = 'Network error: ${e.message}';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteRider(int index) async {
    final rider = riders[index];
    final token = await _getToken();
    if (token == null) return;

    final url = Uri.parse('http://192.168.1.7:8000/api/riders/${rider.id}');
    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => riders.removeAt(index));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rider removed')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Add Rider'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddRiderForm(),
            const SizedBox(height: 24),
            _buildRidersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRiderForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add rider',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'NAME',
            controller: nameController,
            focusNode: nameFocus,
            nextFocusNode: emailFocus,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'EMAIL',
            controller: emailController,
            focusNode: emailFocus,
            nextFocusNode: contactNumberFocus,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: 'Contact Number',
            controller: contactNumberController,
            focusNode: contactNumberFocus,
            nextFocusNode: passwordFocus,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildPasswordField(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: isLoading ? null : _addRider,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
            ),
            onSubmitted: (_) {
              if (nextFocusNode != null)
                FocusScope.of(context).requestFocus(nextFocusNode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PASSWORD',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  obscureText: obscurePassword,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => obscurePassword = !obscurePassword),
                child: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRidersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riders',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ...riders.map((rider) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rider.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rider.contactNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _deleteRider(riders.indexOf(rider)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
