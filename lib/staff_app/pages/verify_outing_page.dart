import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:student_app/staff_app/api/api_service.dart';

class VerifyOutingPage extends StatefulWidget {
  final String? name;
  final String? adm;
  final String? time;
  final String? status;
  final String? type;
  final String? imageUrl;
  final int? outingId;

  const VerifyOutingPage({
    super.key,
    this.name,
    this.adm,
    this.time,
    this.status,
    this.type,
    this.imageUrl,
    this.outingId,
  });

  @override
  State<VerifyOutingPage> createState() => _VerifyOutingPageState();
}

class _VerifyOutingPageState extends State<VerifyOutingPage> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;

  bool _isLoadingDetails = false;
  Map<String, dynamic>? _details;
  bool _isUploadingPhoto = false;
  bool _isReportingIn = false;
  bool _isApproving = false;
  bool _photoUploaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.outingId != null && widget.outingId != 0) {
      _fetchDetails();
    }
  }

  @override
  void didUpdateWidget(covariant VerifyOutingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.outingId != oldWidget.outingId) {
      setState(() {
        _details = null;
        _capturedImage = null;
        _photoUploaded = false;
        _isUploadingPhoto = false;
      });
      if (widget.outingId != null && widget.outingId != 0) {
        _fetchDetails();
      }
    }
  }

  Future<void> _fetchDetails() async {
    try {
      setState(() => _isLoadingDetails = true);
      final data = await ApiService.getOutingDetails(widget.outingId!);
      setState(() {
        final indexData = data['indexdata'];
        if (indexData is List && indexData.isNotEmpty) {
          _details = indexData.first;
        } else if (indexData is Map<String, dynamic>) {
          _details = indexData;
        } else {
          _details = data; // Fallback
        }

        // Photo must be uploaded in current session to enable approve

        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() => _isLoadingDetails = false);
      debugPrint("Error fetching outing details: $e");
    }
  }

  bool get _isPhotoAvailable {
    return _photoUploaded ||
        _capturedImage != null ||
        (_details?['pic'] != null && _details!['pic'].toString().isNotEmpty) ||
        (_details?['letter_photo'] != null &&
            _details!['letter_photo'].toString().isNotEmpty) ||
        (_details?['photo'] != null &&
            _details!['photo'].toString().isNotEmpty) ||
        (widget.imageUrl != null && widget.imageUrl!.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final darkGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1a1a2e),
        Color(0xFF16213e),
        Color(0xFF0f3460),
        Color(0xFF533483),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: MediaQuery.of(context).size.height, // ✅ full height
        width: double.infinity,
        decoration: BoxDecoration(gradient: darkGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppTitle(context, isDark),
                const SizedBox(height: 28),

                /// ADMISSION NUMBER
                Center(
                  child: Text(
                    _details?['admno'] ?? widget.adm ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// MAIN CARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoadingDetails)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      else ...[
                        _buildRow(
                          "Student Name",
                          _details?['student_name'] ?? widget.name ?? "-",
                        ),
                        _buildRow("Father Name", _details?['fname'] ?? "-"),
                        _buildRow(
                          "Admission No",
                          _details?['admno'] ?? widget.adm ?? "-",
                        ),
                        _buildRow("Mobile", _details?['mobile'] ?? "-"),
                        if (_details?['branch'] != null &&
                            _details!['branch'].toString().isNotEmpty)
                          _buildRow("Branch", _details!['branch']),
                        if (_details?['group'] != null &&
                            _details!['group'].toString().isNotEmpty)
                          _buildRow("Group", _details!['group']),
                        if (_details?['course'] != null &&
                            _details!['course'].toString().isNotEmpty)
                          _buildRow("Course", _details!['course']),
                        if (_details?['batch'] != null &&
                            _details!['batch'].toString().isNotEmpty)
                          _buildRow("Batch", _details!['batch']),
                        _buildRow("Out Date", _details?['out_date'] ?? "-"),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Colors.white24, thickness: 1),
                        ),
                        _buildRow(
                          "Permission By",
                          _details?['permission'] ?? "-",
                        ),
                        _buildRow("Purpose", _details?['purpose'] ?? "-"),
                        _buildRow(
                          "Type",
                          _details?['outingtype'] ??
                              _details?['outing_type'] ??
                              widget.status ??
                              "-",
                        ),
                        _buildRow(
                          "Time",
                          _details?['outing_time'] ?? widget.time ?? "-",
                        ),
                      ],

                      const SizedBox(height: 20),

                      /// IMAGE PREVIEW
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _capturedImage != null
                            ? Image.file(
                                _capturedImage!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : (_details?['pic'] != null ||
                                  _details?['letter_photo'] != null ||
                                  _details?['photo'] != null ||
                                  (widget.imageUrl != null &&
                                      widget.imageUrl!.isNotEmpty))
                            ? Image.network(
                                _details?['pic'] ??
                                    _details?['letter_photo'] ??
                                    _details?['photo'] ??
                                    widget.imageUrl!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Image.asset(
                                  "assets/girl.jpg",
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                "assets/girl.jpg",
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),

                      const SizedBox(height: 20),

                      _buildActionButtons(context),
                    ],
                  ),
                ),

                const SizedBox(height: 60), // ✅ instead of Spacer
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= APP TITLE =================
  Widget _buildAppTitle(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: const [
          Icon(Icons.arrow_back, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Verify Outing",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            "$title : ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _buildActionButtons(BuildContext context) {
    final status = widget.status?.toLowerCase() ?? "";
    final bool isPending = status == "pending";
    final bool isApproved = status == "approved";

    return Column(
      children: [
        if (isPending) ...[
          _buildFullWidthButton(
            label: "Take Photo",
            color: const Color(0xFF5A8DEE), // Blue
            onTap: () => _showCaptureDialog(context),
          ),
          const SizedBox(height: 16),
          _buildFullWidthButton(
            label: _isApproving
                ? "Approving..."
                : _isUploadingPhoto
                ? "Uploading Photo..."
                : "Approve",
            color: _isPhotoAvailable && !_isUploadingPhoto
                ? const Color(0xFF2EBD85)
                : Colors.grey,
            onTap: () async {
              if (_isApproving || _isUploadingPhoto) return;
              if (!_isPhotoAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Please take a photo first and wait for upload",
                    ),
                  ),
                );
                return;
              }

              if (widget.outingId == null || widget.outingId == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid Outing ID")),
                );
                return;
              }

              setState(() => _isApproving = true);

              try {
                await ApiService.approveOuting(widget.outingId!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Outing Approved Successfully"),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true); // Refresh list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Approval Failed: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() => _isApproving = false);
              }
            },
          ),
        ],
        if (isApproved)
          _buildFullWidthButton(
            label: _isReportingIn ? "Reporting In..." : "Report In",
            color: const Color(0xFFFFB425), // Orange
            onTap: () async {
              if (_isReportingIn) return;

              if (widget.outingId == null || widget.outingId == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid Outing ID")),
                );
                return;
              }

              setState(() => _isReportingIn = true);

              try {
                await ApiService.inreportOuting(widget.outingId!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Report In Successful"),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.pop(context, true); // Pass true to refresh the list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Report In Failed: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() => _isReportingIn = false);
              }
            },
          ),
      ],
    );
  }

  Widget _buildFullWidthButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ================= DIALOG =================
  void _showCaptureDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF2C2F3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Capture Student Photo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _dialogButton(
                    label: "Capture Photo",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                    ),
                    onTap: () async {
                      await _captureFromCamera();
                      Navigator.pop(context);
                    },
                  ),
                  _dialogButton(
                    label: "Upload Photo",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A8DEE), Color(0xFF6A5AE0)],
                    ),
                    onTap: () async {
                      await _pickFromGallery();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CAMERA =================
  Future<void> _captureFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) {
      final file = File(photo.path);
      setState(() => _capturedImage = file);
      await _uploadPhoto(file);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      final file = File(image.path);
      setState(() => _capturedImage = file);
      await _uploadPhoto(file);
    }
  }

  Future<void> _uploadPhoto(File file) async {
    if (widget.outingId == null || widget.outingId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid Outing ID")));
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
      _photoUploaded = false;
    });

    try {
      final String? newUrl = await ApiService.uploadOutingPhoto(
        file,
        outingId: widget.outingId!,
      );
      setState(() {
        _photoUploaded = true;
        if (newUrl != null && newUrl != "SUCCESS_NO_URL") {
          if (_details != null) {
            _details!['pic'] = newUrl;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Photo Uploaded Successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Widget _dialogButton({
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 170,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
