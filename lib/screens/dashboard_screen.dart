import 'package:flutter/material.dart';
 // Using AuthService
import 'package:file_picker/file_picker.dart';

import '../model/auth_model.dart';
import '../services/auth_services.dart'; // Essential for file picking

// Custom colors for theme consistency
const Color primaryBlue = Color(0xFF4c51bf);
const Color secondaryPurple = Color(0xFF805ad5);

class DashboardScreen extends StatelessWidget {
  final AppUser? initialUser;

  DashboardScreen({super.key, this.initialUser});

  final AuthService _auth = AuthService();

  // Helper method to build a drawer list tile
  Widget _buildDrawerTile(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : primaryBlue),
      title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
            color: isLogout ? Colors.red : Colors.black87,
          )
      ),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        onTap();
      },
    );
  }

  // Helper function to centralize the logic for determining display text
  ({String name, String email}) _getDisplayValues(AppUser? user) {
    if (user == null) {
      return (name: 'Welcome!', email: 'Authenticating...');
    }

    String name;
    String email = user.email.isNotEmpty ? user.email : 'Not available';

    if (user.displayName?.isNotEmpty == true) {
      name = user.displayName!;
    } else if (user.email.isNotEmpty) {
      name = user.email.split('@').first;
    } else {
      name = 'Welcome User!';
    }
    return (name: name, email: email);
  }

  // Method to show the file upload dialog with local state management
  void _showUploadDialog(BuildContext context) {
    // State variables defined in the showDialog scope (but outside StatefulBuilder)
    // This allows the StatefulBuilder's setState to reliably update these variables.
    String _selectedFileName = 'No file selected';
    final TextEditingController _nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the local state of the dialog
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {

            // Function to handle real file picking
            void _pickFile() async {
              FilePickerResult? result;

              try {
                // Set custom file types for better UX (documents and images)
                result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File picker error: $e')),
                );
                return;
              }


              if (result != null && result.files.isNotEmpty) {
                final pickedName = result.files.single.name;

                setState(() {
                  _selectedFileName = pickedName;
                  // Update the text field with the picked file name
                  _nameController.text = pickedName;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File selected: $pickedName')),
                );
              } else {
                // User canceled the picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File selection canceled.')),
                );
              }
            }

            // Set initial controller text if a file was previously selected
            if (_selectedFileName != 'No file selected' && _nameController.text.isEmpty) {
              _nameController.text = _selectedFileName;
            }


            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text(
                'Upload New Document',
                style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('Choose a file to upload to PaperPulse.', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    // Text field for document name (pre-populated with file name)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Document Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // File Picker Button
                    ElevatedButton.icon(
                      onPressed: _pickFile, // Call the real file picker
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Select File from Local Storage'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: secondaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Display the selected file name
                    Text(
                      'Selected: $_selectedFileName',
                      style: TextStyle(
                          fontSize: 12,
                          color: _selectedFileName != 'No file selected' ? primaryBlue : Colors.grey
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  // Disable upload if no file is selected
                  onPressed: _selectedFileName == 'No file selected'
                      ? null
                      : () {
                    // NOTE: This is where you would finalize the upload,
                    // e.g., using Firebase Storage with the picked file bytes/path.
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Uploading $_selectedFileName...')),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),

      // Floating Action Button for Upload
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadDialog(context),
        backgroundColor: secondaryPurple,
        tooltip: 'Upload New Document',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: const Icon(Icons.cloud_upload, color: Colors.white, size: 28),
      ),

      // Left Drawer (Sheet) implementation (Drawer logic remains unchanged)
      drawer: Drawer(
        child: StreamBuilder<AppUser?>(
          stream: _auth.user,
          builder: (context, snapshot) {

            AppUser? currentUser = snapshot.data ?? initialUser;
            final display = _getDisplayValues(currentUser);

            String nameToDisplay = display.name;
            String emailToDisplay = display.email;

            return Column(
              children: <Widget>[
                // Custom Drawer Header
                Container(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 20,
                      left: 16,
                      right: 16
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, secondaryPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 30, color: primaryBlue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameToDisplay,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              emailToDisplay,
                              style: const TextStyle(color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation options
                _buildDrawerTile(context, title: 'Profile', icon: Icons.account_circle, onTap: () {}),
                _buildDrawerTile(context, title: 'Settings', icon: Icons.settings, onTap: () {}),
                _buildDrawerTile(context, title: 'Activity Feed', icon: Icons.notifications, onTap: () {}),
                const Spacer(), // Pushes logout to the bottom
                // Logout button
                const Divider(),
                _buildDrawerTile(
                  context,
                  title: 'Logout',
                  icon: Icons.exit_to_app,
                  isLogout: true,
                  onTap: () async {
                    await _auth.signOut();
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),

      // Dashboard Body Content
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_open, size: 80, color: secondaryPurple),
              const SizedBox(height: 16),
              const Text(
                'Welcome to PaperPulse',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Your documents are waiting! Use the upload button to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _showUploadDialog(context),
                icon: const Icon(Icons.upload, color: primaryBlue),
                label: const Text('Start Uploading'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}