import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/theme.dart';
import 'chat_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  DocumentSnapshot? searchedUser;
  bool isSearching = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> searchUser() async {
    final email = _searchController.text.trim();

    // Validation
    if (email.isEmpty) {
      setState(() {
        errorMessage = "Please enter an email address";
        searchedUser = null;
      });
      return;
    }

    // Check if user is trying to search for themselves
    final currentUser = FirebaseAuth.instance.currentUser;
    if (email == currentUser?.email) {
      setState(() {
        errorMessage = "You cannot chat with yourself";
        searchedUser = null;
      });
      return;
    }

    // Show loading state
    setState(() {
      isSearching = true;
      errorMessage = null;
      searchedUser = null;
    });

    try {
      print("Searching for email: $email");

      // First check all users to see what emails exist
      final allUsers = await FirebaseFirestore.instance
          .collection("users")
          .get();

      print("All emails in database:");
      for (var doc in allUsers.docs) {
        print("- ${doc.data()['email']}");
      }

      final result = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: email)
          .get();

      print("Search result: ${result.docs.length} users found");

      setState(() {
        isSearching = false;
        if (result.docs.isNotEmpty) {
          searchedUser = result.docs.first;
          errorMessage = null;
        } else {
          searchedUser = null;
          errorMessage = "No user found with email: $email";
        }
      });
    } catch (e) {
      print("Search error: $e");
      setState(() {
        isSearching = false;
        errorMessage = "Error searching user: ${e.toString()}";
        searchedUser = null;
      });
    }
  }

  Future<String> createChatRoom(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Check for existing chat
    final chatQuery = await FirebaseFirestore.instance
        .collection("chats")
        .where("users", arrayContains: currentUserId)
        .get();

    for (var doc in chatQuery.docs) {
      final users = doc["users"] as List;
      if (users.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new chat
    final newChat = await FirebaseFirestore.instance.collection("chats").add({
      "users": [currentUserId, otherUserId],
      "createdAt": FieldValue.serverTimestamp(),
      "lastMessage": "",
      "lastMessageTime": FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  Future<void> startChat() async {
    if (searchedUser == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final chatId = await createChatRoom(searchedUser!.id);

      // Hide loading
      Navigator.of(context).pop();

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatPage(chatId: chatId, otherUser: searchedUser!),
        ),
      );
    } catch (e) {
      // Hide loading
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Find Users",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Icon(
                  Icons.logout,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderColor,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage: currentUser?.photoURL != null
                          ? NetworkImage(currentUser!.photoURL!)
                          : null,
                      backgroundColor: AppColors.primary,
                      radius: 24,
                      child: currentUser?.photoURL == null
                          ? Text(
                              currentUser?.displayName
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.displayName ?? 'You',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentUser?.email ?? '',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              "Search for Users",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter an email address to find and chat with other users",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: "Enter user's email address",
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  suffixIcon: isSearching
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.all(8),
                          child: Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: isSearching ? null : searchUser,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  enabled: !isSearching,
                ),
                onSubmitted: (_) => searchUser(),
              ),
            ),

            const SizedBox(height: 24),

            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.inter(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (searchedUser != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "User Found!",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.borderColor,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage:
                                searchedUser!["photoUrl"] != null &&
                                    searchedUser!["photoUrl"]
                                        .toString()
                                        .isNotEmpty
                                ? NetworkImage(searchedUser!["photoUrl"])
                                : null,
                            backgroundColor: AppColors.primary,
                            radius: 28,
                            child:
                                searchedUser!["photoUrl"] == null ||
                                    searchedUser!["photoUrl"].toString().isEmpty
                                ? Text(
                                    (searchedUser!["name"] ?? 'U')
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                searchedUser!["name"] ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                searchedUser!["email"] ?? '',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: startChat,
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text(
                          "Start Chat",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (searchedUser == null && errorMessage == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.search,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Find Users to Chat",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Search for users by their email address to start chatting.\n\nNote: Both users must have signed in to appear in search results.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
