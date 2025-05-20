import 'package:frappe_flutter_app/core/barrel_file.dart';
import 'package:frappe_flutter_app/repositories/frappe_repository.dart';
import 'package:frappe_flutter_app/services/connectivity_service.dart';

import 'package:frappe_flutter_app/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> getData() async {
    List<dynamic> res = await FrappeRepository(
      DioService.instance.client,
    ).apiResource<List<dynamic>>(
      doctype: 'User',
    );
    logger.info(res);
    SnackbarGlobal.show(
      'Data received successfully',
      textColor: Colors.white,
      backgroundColor: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<ConnectivityService>().isConnected;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: !isConnected
          ? const OfflineWidget()
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Welcome to the Home Screen!'),
                  ElevatedButton(
                    onPressed: getData,
                    child: const Text("Get Data"),
                  )
                ],
              ),
            ),
    );
  }
}
