import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../constants/routes_constant.dart';
import '../providers/auth_provider.dart';
import '../router.dart';
import '../services/logger_service.dart';
import '../utils/utils.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Future<void> _logoutUser(BuildContext context) async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      router.go(RouteConstants.login);
    } catch (e, t) {
      logger.error('Error while adding app drawer', error: e, stackTrace: t);
    }
  }

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          FutureBuilder(
            future: _getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasData) {
                final userData = snapshot.data!;
                final userId = userData['userId'];
                final fullName = userData['fullName'];
                final initials = userData['initials'];
                return UserAccountsDrawerHeader(
                  accountName: Text(
                    fullName ?? 'Not Available',
                    style: const TextStyle(fontSize: 18),
                  ),
                  accountEmail: Text(userId!),
                  currentAccountPictureSize: const Size.square(70),
                  currentAccountPicture: CircleAvatar(
                    child: Text(
                      initials!,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                );
              } else {
                return const Text('User ID not found');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              _logoutUser(context);
            },
          ),
          const Spacer(),
          ListTile(
            title: FutureBuilder(
              future: Utils.getAppVersion(),
              builder: (context, snapshot) {
                logger.info(snapshot);
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasData) {
                  return Text(
                    'App Version: ${snapshot.data}',
                    style: const TextStyle(fontSize: 16),
                  );
                } else {
                  return const Text('App version not found');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _getUserDetails() async {
    String? userId = await secureStorage.read(key: 'userId');
    String? fullName = await secureStorage.read(key: 'fullName');

    String initials;
    if (fullName != null && fullName.isNotEmpty) {
      List<String> nameParts = fullName.split(' ');
      initials = nameParts
          .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
          .join('');
    } else {
      initials = userId?.substring(0, 1) ?? '';
    }

    return {
      'userId': userId ?? '',
      'fullName': fullName ?? '',
      'initials': initials,
    };
  }
}
