import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NagarRakshakApp());
}

class NagarRakshakApp extends StatelessWidget {
  const NagarRakshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const ReportScreen(),
    );
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _selectedImage;
  String _aiResult = "Ready to Scan";
  String _issueType = "";
  String _severity = "";
  bool _isLoading = false;
  bool _isUploading = false;

  // --- 1. PICK IMAGE ---
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: source, imageQuality: 30);

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _aiResult = "Analyzing...";
        _issueType = "";
        _isLoading = true;
      });
      _analyzeImage(_selectedImage!);
    }
  }

  // --- 2. ANALYZE (AI) ---
  Future<void> _analyzeImage(File image) async {
    // ⚠️ CHECK IP: Ensure this matches your PC's IP
    final url = Uri.parse('http://192.168.1.8:5000/analyze');

    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);

        String issue = data['issue'];
        String severity = data['severity'];

        setState(() {
          _issueType = issue;
          _severity = severity;

          if (issue == 'none' || issue == 'Error') {
            _aiResult = "✅ All Clear\nNo civic issues detected.";
          } else {
            String formattedIssue = issue[0].toUpperCase() + issue.substring(1);
            _aiResult = "⚠️ Issue Detected: $formattedIssue\nSeverity: $severity";
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _aiResult = "Error: Server rejected image.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _aiResult = "Connection Failed.\nIs Python running? Check IP.";
        _isLoading = false;
      });
      print("Error: $e");
    }
  }

  // --- 3. SAVE TO FIREBASE (Original Working Version) ---
  Future<void> _submitReport() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Convert Image to Base64
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Save to Cloud
      await FirebaseFirestore.instance.collection('reports').add({
        'issue': _issueType,
        'severity': _severity,
        'imageBase64': base64Image,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'description': 'Reported via Nagar Rakshak App'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report Submitted Successfully! 🚀'), backgroundColor: Colors.green),
      );

      setState(() {
        _selectedImage = null;
        _aiResult = "Ready to Scan";
        _issueType = "";
        _isUploading = false;
      });

    } catch (e) {
      print("Upload Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload Failed: $e'), backgroundColor: Colors.red),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same UI as before
    Color statusColor;
    Color statusBgColor;

    if (_aiResult.contains("Analyzing") || _aiResult.contains("Ready")) {
      statusColor = Colors.grey;
      statusBgColor = Colors.grey[100]!;
    } else if (_issueType == 'none') {
      statusColor = Colors.green;
      statusBgColor = Colors.green[50]!;
    } else {
      statusColor = Colors.deepOrange;
      statusBgColor = Colors.orange[50]!;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nagar Rakshak", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedImage == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 50, color: Colors.grey),
                            Text("No Image Selected"),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 30),

              if (!_isLoading && !_isUploading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Gallery"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepOrange,
                          side: const BorderSide(color: Colors.deepOrange, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),

              if (_isLoading || _isUploading)
                const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),

              const SizedBox(height: 20),

              if (_aiResult != "Ready to Scan" && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text("AI REPORT", style: TextStyle(fontSize: 12, color: statusColor, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        _aiResult,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor.withOpacity(1.0),
                        ),
                      ),
                      
                      if (_issueType != "" && _issueType != "none" && _issueType != "Error") ...[
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _submitReport,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text("OFFICIAL REPORT TO GOVT"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}