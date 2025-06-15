import 'package:flutter/material.dart';
import 'package:snap_check/models/city_model.dart';
import 'package:snap_check/models/country_model.dart';
import 'package:snap_check/models/state_model.dart';
import 'package:snap_check/models/taluka_model.dart';
import 'package:snap_check/screens/login_screen.dart';
import 'package:snap_check/services/basic_service.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();

  CountryModel? _selectedCountry;
  StateModel? _selectedState;
  CityModel? _selectedCity;
  TalukaModel? _selectedTaluko;
  bool _isLoading = false;

  // Sample data - replace with API fetched list in real app
  List<CountryModel> _countries = [];
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  List<TalukaModel> _talukas = [];

  final AuthService _authService = AuthService();
  final BasicService _basicService = BasicService();

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      setState(() => _isLoading = true);

      final response = await _basicService.getLocations();
      if (response != null && response.data != null) {
        setState(() {
          _countries = response.data!;
          _states = response.data!.first.states!;
          _cities = response.data!.first.states!.first.cities!;
          _talukas = response.data!.first.states!.first.cities!.first.talukas!;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tour details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) {
      return; // Show validation errors
    }
    if (_selectedTaluko == null ||
        _selectedCity == null ||
        _selectedState == null ||
        _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select taluka city, state, and country."),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final response = await _authService.registerWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        addressLine1: _address1Controller.text,
        addressLine2: _address2Controller.text,
        talukaId: _selectedTaluko!.id!,
        cityId: _selectedCity!.id!,
        stateId: _selectedState!.id!,
        countryId: _selectedCountry!.id!,
      );
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (response.data != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        final allMessages = response.errors!.getAllMessages();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(allMessages)));
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Create Account",
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let’s get you started!",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'First name is required'
                                        : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Last name is required'
                                        : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _address1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 1',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Address Line 1 is required'
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _address2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 2',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Address Line 2 is required'
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<CountryModel>(
                      isExpanded: true, // ✅ Important fix
                      value: _selectedCountry,
                      items:
                          _countries.map((country) {
                            return DropdownMenuItem(
                              value: country,
                              child: Text(
                                country.name ?? '',
                                overflow:
                                    TextOverflow
                                        .ellipsis, // Truncate long names
                              ),
                            );
                          }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      onChanged:
                          (value) => setState(() {
                            _selectedCountry = value;
                            _states = value!.states!;
                            _selectedState = null;
                            _selectedCity = null;
                          }),
                      validator:
                          (value) =>
                              value == null ? 'Please select a country' : null,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<StateModel>(
                      isExpanded: true, // ✅ Important fix

                      value: _selectedState,
                      items:
                          _states
                              .where((s) => s.countryId == _selectedCountry?.id)
                              .map((state) {
                                return DropdownMenuItem(
                                  value: state,
                                  child: Text(state.name ?? ''),
                                );
                              })
                              .toList(),
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      onChanged:
                          (value) => setState(() {
                            _selectedState = value;
                            _cities = value!.cities!;
                            _selectedCity = null;
                          }),
                      validator:
                          (value) =>
                              value == null ? 'Please select a state' : null,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<CityModel>(
                      isExpanded: true, // ✅ Important fix

                      value: _selectedCity,
                      items:
                          _cities
                              .where((c) => c.stateId == _selectedState?.id)
                              .map((city) {
                                return DropdownMenuItem(
                                  value: city,
                                  child: Text(city.name ?? ''),
                                );
                              })
                              .toList(),
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      onChanged:
                          (value) => setState(() {
                            _selectedCity = value;
                            _talukas = value!.talukas!;
                            _selectedTaluko = null;
                          }),
                      validator:
                          (value) =>
                              value == null ? 'Please select a city' : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<TalukaModel>(
                      isExpanded: true, // ✅ Important fix

                      value: _selectedTaluko,
                      items:
                          _talukas
                              .where((c) => c.cityId == _selectedCity?.id)
                              .map((taluka) {
                                return DropdownMenuItem(
                                  value: taluka,
                                  child: Text(taluka.name ?? ''),
                                );
                              })
                              .toList(),
                      decoration: const InputDecoration(
                        labelText: 'Taluko',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      onChanged:
                          (value) => setState(() => _selectedTaluko = value),
                      validator:
                          (value) =>
                              value == null ? 'Please select a taluko' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordConfirmationController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm Password is required';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signup,
                        child: const Text("Create Account"),
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Login",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withAlpha((0.4 * 255).round()),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
