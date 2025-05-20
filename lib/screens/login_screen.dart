import 'package:frappe_flutter_app/core/barrel_file.dart';
import 'package:frappe_flutter_app/providers/auth_provider.dart';
import 'package:frappe_flutter_app/widgets/powered_by_agkiya.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;

      try {
        final isLoggedIn =
            await Provider.of<AuthProvider>(context, listen: false)
                .login(email, password);
        if (isLoggedIn) {
          router.go(RouteConstants.home);
        }
      } catch (e, t) {
        SnackbarGlobal.show(
          'Login Failed with error $e',
          textColor: Colors.white,
          backgroundColor: Colors.red,
        );

        logger.error(
          'LoginScreenState Login failed: ${e.toString()}',
          error: e,
          stackTrace: t,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              spacing: 10.h,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildLogo(),
                _buildForm(),
                const PoweredByAgkiya(),
                _buildAppVersion(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        FileConstants.loginLogo,
        height: 200.h,
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        spacing: 10.h,
        children: [
          CustomTextField(
            enabled: true,
            labelText: 'Email',
            textEditingController: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Email';
              }
              return null;
            },
          ),
          CustomTextField(
            textEditingController: _passwordController,
            labelText: 'Password',
            obscureText: !_passwordVisible,
            enabled: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Password';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
          CustomElevatedButton(
            onPressed: _login,
            label: 'Login',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(String loadingText) {
    return Center(
        child: CustomLoading(
      loadingText: loadingText,
    ));
  }

  Widget _buildAppVersion() {
    return FutureBuilder(
      future: Utils.getAppVersion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView('Loading App Version');
        } else if (snapshot.hasData) {
          return Text(
            'App Version: ${snapshot.data}',
            style: const TextStyle(fontSize: 16),
          );
        } else {
          return const Text('App version not found');
        }
      },
    );
  }
}
