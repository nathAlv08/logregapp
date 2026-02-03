import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';


const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDA1D8cojamu6tOhJaXjOCD5ilM3IFLGZc",
  authDomain: "loginregistermock.firebaseapp.com",
  projectId: "loginregistermock",
  storageBucket: "loginregistermock.firebasestorage.app",
  messagingSenderId: "991469464030",
  appId: "1:991469464030:android:fd58a6f03104726f7b554f",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    print('Firebase error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Project Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: 'Inter',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (snapshot.hasData) return const HomePage();
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> register(String email, String password, String nama) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'nama': nama,
        'email': email,
        'role': 'mahasiswa',
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async => await _auth.signOut();
}

Future<void> openFileMobile(String base64String, String fileName) async {
  try {
    final bytes = base64Decode(base64String);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      print("Gagal membuka file: ${result.message}");
    }
  } catch (e) {
    print("Error opening file: $e");
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    String? error = await AuthService().login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    setState(() => _isLoading = false);
    if (error != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.school, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text("Student Task Hub", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 40),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 15),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MASUK"),
                ),
              ),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text("Buat Akun Baru")),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    setState(() => _isLoading = true);
    String? error = await AuthService().register(_emailCtrl.text.trim(), _passCtrl.text.trim(), _nameCtrl.text.trim());
    setState(() => _isLoading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Akun")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("DAFTAR"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (c) => AddTaskModal(userId: user!.uid)
        ),
        label: const Text("Upload Tugas"),
        icon: const Icon(Icons.upload_file),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.white, child: Text("M", style: TextStyle(color: Colors.indigo))),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Halo Mahasiswa,", style: TextStyle(color: Colors.white70)),
                      Text(user?.email ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => AuthService().logout()),
              ],
            ),
          ),


          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 50),
                          const SizedBox(height: 10),
                          const Text("Butuh Index Database!", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          const Text(
                            "Cek 'Run' tab di Android Studio. Klik link error untuk membuat index.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text("Error Detail: ${snapshot.error}", style: const TextStyle(fontSize: 10, color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off, size: 60, color: Colors.grey[300]),
                        Text("Belum ada file tugas", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return TaskCard(data: data, docId: doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageBase64;
  final String tag;

  const FullScreenImagePage({super.key, required this.imageBase64, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Tampilan Penuh", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              base64Decode(imageBase64),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const TaskCard({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    bool hasFile = data['fileBase64'] != null && data['fileBase64'].toString().isNotEmpty;
    bool isImage = hasFile && (data['fileType'] == 'jpg' || data['fileType'] == 'png' || data['fileType'] == 'jpeg');

    Color badgeColor = Colors.green;
    if (data['priority'] == 'Medium') badgeColor = Colors.orange;
    if (data['priority'] == 'High') badgeColor = Colors.red;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImagePage(
                      imageBase64: data['fileBase64'],
                      tag: docId,
                    ),
                  ),
                );
              },
              child: Hero(
                tag: docId,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.memory(
                    base64Decode(data['fileBase64']),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(height: 150, color: Colors.grey, child: const Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),

          if (hasFile && !isImage)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, size: 40, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['fileName'] ?? "Dokumen Tugas", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Tipe: ${data['fileType']?.toUpperCase()}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.blue),
                    tooltip: "Buka File",
                    onPressed: () {
                      openFileMobile(data['fileBase64'], data['fileName'] ?? 'tugas.${data['fileType']}');
                    },
                  )
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                      child: Text(data['priority'], style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.indigo),
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (c) => AddTaskModal(
                                userId: FirebaseAuth.instance.currentUser!.uid,
                                docId: docId,
                                initialData: data
                            )
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => FirebaseFirestore.instance.collection('tasks').doc(docId).delete(),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(data['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(data['description'], style: const TextStyle(color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class AddTaskModal extends StatefulWidget {
  final String userId;
  final String? docId;
  final Map<String, dynamic>? initialData;

  const AddTaskModal({super.key, required this.userId, this.docId, this.initialData});
  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'Low';

  String? _fileName;
  String? _fileBase64;
  String? _fileType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleCtrl.text = widget.initialData!['title'];
      _descCtrl.text = widget.initialData!['description'];
      _priority = widget.initialData!['priority'];
      _fileName = widget.initialData!['fileName'];
      _fileBase64 = widget.initialData!['fileBase64'];
      _fileType = widget.initialData!['fileType'];
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
      withData: true,
    );

    if (result != null) {
      if (result.files.first.size > 2 * 1024 * 1024) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File terlalu besar! Max 2MB"), backgroundColor: Colors.red));
        return;
      }

      setState(() {
        _fileName = result.files.first.name;
        _fileType = result.files.first.extension;

        if (result.files.first.bytes != null) {
          _fileBase64 = base64Encode(result.files.first.bytes!);
        } else if (result.files.first.path != null) {
          final file = File(result.files.first.path!);
          _fileBase64 = base64Encode(file.readAsBytesSync());
        }
      });
    }
  }

  void _saveTask() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> dataToSave = {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'priority': _priority,
        'userId': widget.userId,
        'fileName': _fileName,
        'fileType': _fileType,
        'fileBase64': _fileBase64,
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance.collection('tasks').doc(widget.docId).update(dataToSave);
      } else {
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('tasks').add(dataToSave);
      }

      if(mounted) Navigator.pop(context);
    } catch (e) {
      if(mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.docId != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isEdit ? "Edit Tugas" : "Upload Tugas Baru", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 10),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi', prefixIcon: Icon(Icons.description))),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _priority,
            items: ['Low', 'Medium', 'High'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _priority = v!),
            decoration: const InputDecoration(labelText: 'Prioritas'),
          ),
          const SizedBox(height: 20),

          InkWell(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
                color: _fileName != null ? Colors.green[50] : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: _fileName != null ? Colors.green : Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _fileName ?? "Pilih File (JPG, PNG, PDF, DOC)",
                      style: TextStyle(color: _fileName != null ? Colors.green[800] : Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_fileName != null) const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveTask,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(isEdit ? "UPDATE TUGAS" : "SIMPAN TUGAS"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}