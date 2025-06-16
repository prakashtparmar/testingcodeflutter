import 'package:flutter/material.dart';
import 'package:snap_check/models/city_model.dart';
import 'package:snap_check/models/country_model.dart';
import 'package:snap_check/models/state_model.dart';
import 'package:snap_check/models/taluka_model.dart';
import 'package:snap_check/services/api_exception.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';
import '../services/auth_service.dart';

enum Gender { male, female, other }

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  Gender? _selectedGender;

  String? _token;

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
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUser();
    await _fetchLocations();
    await _fetchUserDetail();
  }

  Future<void> _loadUser() async {
    final tokenData = await SharedPrefHelper.getToken();
    setState(() {
      _token = tokenData ?? "";
    });
  }

  Future<void> _fetchUserDetail() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await _authService.fetchUserDetail(_token!);
      if (response?.success == true) {
        if (response?.data != null) {
          var user = response?.data?.user;

          if (user != null) {
            setState(() {
              _emailController.text = user.email!;
              _firstNameController.text = user.firstName!;
              _lastNameController.text = user.lastName!;
              _address1Controller.text = user.addressLine1!;
              _address2Controller.text = user.addressLine2!;
              // _selectedCountry = user.country;
              // _selectedState = user.state;
              // _selectedCity = user.city;
              // _selectedTaluko = user.taluka;
              // 1. Set selected country
              _selectedCountry = _countries.firstWhere(
                (c) => c.id == user.country?.id,
                orElse: () => _countries.first,
              );

              // 2. Populate states from selected country
              _states = _selectedCountry?.states ?? [];

              // 3. Set selected state
              _selectedState = _states.firstWhere(
                (s) => s.id == user.state?.id,
                orElse: () => _states.first,
              );

              // 4. Populate cities from selected state
              _cities = _selectedState?.cities ?? [];

              // 5. Set selected city
              _selectedCity = _cities.firstWhere(
                (c) => c.id == user.city?.id,
                orElse: () => _cities.first,
              );

              // 6. Populate talukas from selected city
              _talukas = _selectedCity?.talukas ?? [];

              // 7. Set selected taluka
              _selectedTaluko = _talukas.firstWhere(
                (t) => t.id == user.taluka?.id,
                orElse: () => _talukas.first,
              );
              _selectedGender = genderFromString(user.gender);
            });
          }
        }
      }
    } on UnauthorizedException {
      SharedPrefHelper.clearUser();
      _redirectToLogin();
    } on NotFoundException {
      _showError('User not found.');
    } on ServerErrorException {
      _showError('Server error. Try again later.');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Something went wrong. $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Gender? genderFromString(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      default:
        return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _redirectToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: Theme.of(context).textTheme.titleSmall),
        RadioListTile<Gender>(
          title: const Text('Male'),
          value: Gender.male,
          groupValue: _selectedGender,
          onChanged: (Gender? value) {
            setState(() => _selectedGender = value);
          },
        ),
        RadioListTile<Gender>(
          title: const Text('Female'),
          value: Gender.female,
          groupValue: _selectedGender,
          onChanged: (Gender? value) {
            setState(() => _selectedGender = value);
          },
        ),
        RadioListTile<Gender>(
          title: const Text('Other'),
          value: Gender.other,
          groupValue: _selectedGender,
          onChanged: (Gender? value) {
            setState(() => _selectedGender = value);
          },
        ),
      ],
    );
  }

  void _editProfile() async {
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
      final response = await _authService.postUserDetail(
        token: _token!,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        addressLine1: _address1Controller.text,
        addressLine2: _address2Controller.text,
        talukaId: _selectedTaluko!.id!,
        cityId: _selectedCity!.id!,
        stateId: _selectedState!.id!,
        countryId: _selectedCountry!.id!,
        gender: _selectedGender?.name,
      );
      setState(() => _isLoading = false);
      if (!mounted) return;
      if (response.data != null) {
        Navigator.pop(context);
      } else {
        final allMessages = response.message;

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
          appBar: AppBar(title: const Text("Edit Details")),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _buildGenderSelector(),

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
                      enabled: false,
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

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _editProfile,
                        child: const Text("Submit"),
                      ),
                    ),
                    const SizedBox(height: 30),
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
