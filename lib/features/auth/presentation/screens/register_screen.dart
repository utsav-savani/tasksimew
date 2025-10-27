import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.pushReplacementNamed(context, RouteConstants.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Name Field
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.validateName,
                ),

                const SizedBox(height: 16),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                ),

                const SizedBox(height: 16),

                // Phone Field (Optional)
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),

                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: Validators.validatePassword,
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),

                const SizedBox(height: 24),

                // Register Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return PrimaryButton(
                      text: 'Register',
                      onPressed: authProvider.isLoading ? null : _handleRegister,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          RouteConstants.login,
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
