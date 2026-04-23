import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/apple_design.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _avatarController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _orgController;
  late TextEditingController _birthController;
  String? _selectedGender; // Trường Gender quan trọng ở đây
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userData['displayName'],
    );
    _avatarController = TextEditingController(
      text: widget.userData['avatarUrl'],
    );
    _phoneController = TextEditingController(
      text: widget.userData['phoneNumber'],
    );
    _addressController = TextEditingController(
      text: widget.userData['address'],
    );
    _bioController = TextEditingController(text: widget.userData['organic']);
    _orgController = TextEditingController(
      text: widget.userData['organization'],
    );
    _birthController = TextEditingController(text: widget.userData['birthday']);
    _selectedGender =
        widget.userData['gender'] ?? "Nam"; // Gán mặc định nếu null
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => _isSaving = true);
        final String? cloudUrl = await UserService().uploadAvatar(
          File(pickedFile.path),
        );

        if (cloudUrl != null) {
          setState(() {
            _avatarController.text = cloudUrl;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tải ảnh lên thành công!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lỗi tải ảnh lên Cloudinary"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Chọn từ thư viện"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Chụp ảnh mới"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final Map<String, dynamic> updateData = {
      'displayName': _nameController.text,
      'avatarUrl': _avatarController.text,
      'phoneNumber': _phoneController.text,
      'address': _addressController.text,
      'birthday': _birthController.text,
      'organic': _bioController.text,
      'organization': _orgController.text,
      'gender': _selectedGender, // Đưa gender vào gói tin gửi đi
    };

    final success = await UserService().updateProfile(updateData);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String email =
        widget.userData['email'] ?? widget.userData['e-mail'] ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Sửa hồ sơ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _avatarController.text.isNotEmpty
                        ? NetworkImage(_avatarController.text)
                        : null,
                    child: _avatarController.text.isEmpty
                        ? const Icon(Icons.person, size: 55, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showPickerOptions,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppleColors.appleBlue,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_isSaving)
                    const Positioned.fill(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildDisabledField("Email tài khoản", email),
            _buildTextField("Họ và tên", _nameController),

            // --- TRƯỜNG CHỌN GIỚI TÍNH ---
            const Text(
              "Giới tính",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            Row(
              children: [
                _buildGenderRadio("Nam"),
                _buildGenderRadio("Nữ"),
                _buildGenderRadio("Khác"),
              ],
            ),
            const SizedBox(height: 10),

            _buildTextField("Tiểu sử", _bioController, maxLines: 2),
            _buildTextField(
              "Số điện thoại",
              _phoneController,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField("Địa chỉ", _addressController),
            _buildTextField("Ngày sinh", _birthController),
            _buildTextField("Tổ chức", _orgController),

            const SizedBox(height: 30),
            _saveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderRadio(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedGender,
          onChanged: (val) => setState(() => _selectedGender = val),
          activeColor: AppleColors.appleBlue,
        ),
        Text(value),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        initialValue: value,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          prefixIcon: const Icon(Icons.lock_outline, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppleColors.appleBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          "Lưu thay đổi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
