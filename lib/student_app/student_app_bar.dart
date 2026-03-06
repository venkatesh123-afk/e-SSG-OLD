import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_app/staff_app/controllers/auth_controller.dart';
import 'package:student_app/student_app/profile_page.dart';

import 'package:student_app/student_app/services/student_profile_service.dart';
import 'package:student_app/student_app/studentdrawer.dart';
import 'package:student_app/theme_controllers.dart';

class StudentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLeading;

  const StudentAppBar({super.key, this.title = '', this.showLeading = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title.isNotEmpty ? Text(title) : null,
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      leading: showLeading
          ? Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ThemeControllerWrapper(
                        themeController: StudentThemeController.themeMode,
                        child: const StudentDrawerPage(),
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
      actions: [
        // Theme Toggle
        ValueListenableBuilder<ThemeMode>(
          valueListenable: StudentThemeController.themeMode,
          builder: (context, themeMode, _) {
            final isDark =
                themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark);
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: isDark
                    ? const Color(0xFF6366F1) // Light purple for dark mode
                    : const Color(0xFFEFEFEF), // Light gray for light mode
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    StudentThemeController.toggleTheme();
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF333333), // Dark gray for moon icon
                      size: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Profile Menu
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ValueListenableBuilder<String?>(
              valueListenable: StudentProfileService.profileImageUrl,
              builder: (context, imageUrl, _) {
                final isBase64 =
                    imageUrl != null && imageUrl.startsWith('data:image');
                return CircleAvatar(
                  radius: 18,
                  backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                      ? (isBase64
                                ? MemoryImage(
                                    base64Decode(imageUrl.split(',').last),
                                  )
                                : NetworkImage(imageUrl))
                            as ImageProvider
                      : const NetworkImage("https://i.pravatar.cc/150"),
                );
              },
            ),
            itemBuilder: (context) => [
              // Header Item (Welcome Message)
              PopupMenuItem<String>(
                enabled: false,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: StudentProfileService.displayName,
                    builder: (context, name, _) {
                      return Text(
                        "Welcome ${name ?? 'Student'}!",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Profile
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 20,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 12),
                    const Text("Profile"),
                  ],
                ),
              ),
              // Change Password
              PopupMenuItem<String>(
                value: 'password',
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 12),
                    const Text("Change Password"),
                  ],
                ),
              ),

              // Logout
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThemeControllerWrapper(
                      themeController: StudentThemeController.themeMode,
                      child: const ProfilePage(),
                    ),
                  ),
                );
              } else if (value == 'password') {
                // Navigate to Profile but user has to click "Change Password" there.
                // Alternatively, we could navigate to profile and try to trigger state,
                // but simple navigation is safe.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThemeControllerWrapper(
                      themeController: StudentThemeController.themeMode,
                      child: const ProfilePage(),
                    ),
                  ),
                );
              } else if (value == 'logout') {
                final authController = Get.isRegistered<AuthController>()
                    ? Get.find<AuthController>()
                    : Get.put(AuthController());
                authController.logout();
              }
            },
          ),
        ),
      ],
    );
  }
}
