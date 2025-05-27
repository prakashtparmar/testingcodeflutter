import 'package:flutter/material.dart';
import 'package:snap_check/models/city_model.dart';
import 'package:snap_check/models/country_model.dart';
import 'package:snap_check/models/state_model.dart';
import 'package:snap_check/screens/login_screen.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();

  CountryModel? _selectedCountry;
  StateModel? _selectedState;
  CityModel? _selectedCity;

  // Sample data - replace with API fetched list in real app
  final List<CountryModel> _countries = [
    CountryModel(id: 1, name: 'India'),
    CountryModel(id: 2, name: 'USA'),
  ];
  final List<StateModel> _states = [
    StateModel(id: 1, name: 'Maharashtra', countryId: 1),
    StateModel(id: 2, name: 'California', countryId: 2),
  ];
  final List<CityModel> _cities = [
    CityModel(id: 1, name: 'Mumbai', stateId: 1),
    CityModel(id: 2, name: 'Los Angeles', stateId: 2),
  ];

  final AuthService _authService = AuthService();

  void _signup() async {
    if (_selectedCity == null ||
        _selectedState == null ||
        _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select city, state, and country."),
        ),
      );
      return;
    }

    try {
      final user = await _authService.registerWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        addressLine1: _address1Controller.text,
        addressLine2: _address2Controller.text,
        cityId: _selectedCity!.id!,
        stateId: _selectedState!.id!,
        countryId: _selectedCountry!.id!,
      );
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _address1Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 1',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _address2Controller,
                decoration: const InputDecoration(
                  labelText: 'Address Line 2',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<CountryModel>(
                value: _selectedCountry,
                items:
                    _countries.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country.name ?? ''),
                      );
                    }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Country',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                onChanged:
                    (value) => setState(() {
                      _selectedCountry = value;
                      _selectedState = null;
                      _selectedCity = null;
                    }),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<StateModel>(
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
                      _selectedCity = null;
                    }),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<CityModel>(
                value: _selectedCity,
                items:
                    _cities.where((c) => c.stateId == _selectedState?.id).map((
                      city,
                    ) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city.name ?? ''),
                      );
                    }).toList(),
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
                onChanged: (value) => setState(() => _selectedCity = value),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
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
    );
  }
}
