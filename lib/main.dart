import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      routes: {
        '/register': (context) => RegisterPage(),
        '/main': (context) => MainPage(),
        '/login': (context) => LoginPage(),
        '/feedback': (context) => UserFeedbackPage(), // Add this line
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

Future<void> _login(BuildContext context) async {
  if (_formKey.currentState!.validate()) {
    try {
      // Log the email and password
      print('Email: ${_usernameController.text}');
      print('Password: ${_passwordController.text}');
      
      final response = await http.post(
        Uri.parse('http://127.0.0.1/edu_app_server/login.php'),
        body: {
          'email': _usernameController.text,
          'password': _passwordController.text,
        },
      );
      // Log the response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Response data: $responseData'); // Log the response data
        if (responseData['status'] == 'success') {
          // Store session information
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_token', responseData['session_token']); // Store the session token
          // Navigate to the main page
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${responseData['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _login(context),
                child: Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to the main page!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherPage()),
                );
              },
              child: Text('Go to Weather Page'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserProfilePage()),
                );
              },
              child: Text('Go to User Profile Page'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserFeedbackPage()),
                );
              },
              child: Text('Go to User Feedback Page'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CourseSchedulePage()),
                );
              },
              child: Text('Go to Course Schedule Page'),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _loadSessionToken();
  }

Future<void> _loadSessionToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _sessionToken = prefs.getString('session_token');
  });
  _fetchUserData();
}

Future<void> _fetchUserData() async {
  if (_sessionToken == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Session token not found')),
    );
    return;
  }
  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1/edu_app_server/user_profile.php'),
      body: {'email': _sessionToken},
    );
    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final data = responseData['data'];
          setState(() {
            _nameController.text = data['name'];
            _emailController.text = data['email'];
            _studentIdController.text = data['student_id'];
            _phoneNumberController.text = data['phone_number'];
            _addressController.text = data['address'];
            _securityAnswerController.text = data['security_answer'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found')),
          );
        }
      } catch (e) {
        print('Error parsing JSON: $e');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid response format')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error fetching user data: $e'); // Log the error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

Future<void> _updateUserData() async {
  if (_formKey.currentState!.validate()) {
    if (_sessionToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session token not found')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1/edu_app_server/update_user.php'),
        body: {
          'email': _sessionToken,
          'name': _nameController.text,
          'student_id': _studentIdController.text,
          'phone_number': _phoneNumberController.text,
          'address': _addressController.text,
          'security_answer': _securityAnswerController.text,
        },
      );
      
      print('Full response: ${response.body}');  // Add this line
      
      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User data updated successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: ${responseData['message']}')),
            );
          }
        } catch (e) {
          print('Error parsing JSON: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid server response')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error updating user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _studentIdController,
                decoration: InputDecoration(labelText: 'Student ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your student ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _securityAnswerController,
                decoration: InputDecoration(labelText: 'Security Answer'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your security answer';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUserData,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  Map<String, dynamic> _weatherData = {}; // Initialize the field

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:3000/weather')); // Replace with your machine's IP address
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = data;
        });
      } else {
        setState(() {
          _weatherData = {'error': 'Failed to load weather data'};
        });
      }
    } catch (e) {
      print('Error: $e'); // Log the error
      setState(() {
        _weatherData = {'error': 'Error: $e'};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Page'),
      ),
      body: Center(
        child: _weatherData.isEmpty
            ? CircularProgressIndicator()
            : _weatherData.containsKey('error')
                ? Text(_weatherData['error'])
                : _buildWeatherTable(),
      ),
    );
  }

  Widget _buildWeatherTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        _buildTableRow('Coordinate', 'Lon: ${_weatherData['coord']['lon']}, Lat: ${_weatherData['coord']['lat']}'),
        _buildTableRow('Weather', '${_weatherData['weather'][0]['main']}, ${_weatherData['weather'][0]['description']}'),
        _buildTableRow('Temperature', 'Temp: ${_weatherData['main']['temp']}°K, Feels like: ${_weatherData['main']['feels_like']}°K'),
        _buildTableRow('Pressure', '${_weatherData['main']['pressure']} hPa'),
        _buildTableRow('Humidity', '${_weatherData['main']['humidity']}%'),
        _buildTableRow('Visibility', '${_weatherData['visibility']} meters'),
        _buildTableRow('Wind', 'Speed: ${_weatherData['wind']['speed']} m/s, Deg: ${_weatherData['wind']['deg']}°'),
        _buildTableRow('Cloudiness', '${_weatherData['clouds']['all']}%'),
        _buildTableRow('Location', _weatherData['name']),
      ],
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }
}

class RegisterPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  final _nameController = TextEditingController();

  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var digest = sha1.convert(bytes); // Hash the bytes using SHA-1
    return digest.toString(); // Convert the hash to a string
  }

  Future<void> _registerUser(BuildContext context) async {
    print('Register button pressed');
    String hashedPassword = _hashPassword(_passwordController.text); // Hash the password
    print('Hashed Password: $hashedPassword'); // Log the hashed password

    final response = await http.post(
      Uri.parse('http://127.0.0.1/edu_app_server/register.php'),
      body: {
        'name': _nameController.text,
        'email': _emailController.text,
        'student_id': _studentIdController.text,
        'password': hashedPassword, // Use the hashed password
        'phone_number': _phoneNumberController.text,
        'address': _addressController.text,
        'security_answer': _securityAnswerController.text,
      },
    );
    print('Server response: ${response.body}');
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        print('Registration successful');
        // Navigate to the main page
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print('Registration failed: ${responseData['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${responseData['message']}')),
        );
      }
    } else {
      print('Server error: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _studentIdController,
                decoration: InputDecoration(labelText: 'Student ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your student ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _securityAnswerController,
                decoration: InputDecoration(labelText: 'Security Answer'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your security answer';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _registerUser(context);
                  }
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserFeedbackPage extends StatefulWidget {
  @override
  _UserFeedbackPageState createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  File? _image;
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _loadSessionToken();
  }

  Future<void> _loadSessionToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionToken = prefs.getString('session_token');
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _submitFeedback() async {
  if (_formKey.currentState!.validate()) {
    if (_sessionToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session token (email) not found')),
      );
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1/edu_app_server/user_feedback.php'),
      );
      request.fields['email'] = _sessionToken!;
      request.fields['feedback'] = _feedbackController.text;
      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        if (jsonResponse['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Feedback submitted successfully')),
          );
          _feedbackController.clear();
          setState(() {
            _image = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission failed: ${jsonResponse['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Feedback Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(labelText: 'Feedback'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your feedback';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _image == null
                  ? Text('No image selected.')
                  : Image.file(_image!),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitFeedback,
                child: Text('Submit Feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseSchedulePage extends StatefulWidget {
  @override
  _CourseSchedulePageState createState() => _CourseSchedulePageState();
}

class _CourseSchedulePageState extends State<CourseSchedulePage> {
  List<dynamic> _courseSchedule = [];
  final _courseController = TextEditingController();
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _loadSessionToken();
  }

  Future<void> _loadSessionToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionToken = prefs.getString('session_token');
    });
    _fetchCourseSchedule();
  }

  Future<void> _fetchCourseSchedule() async {
    if (_sessionToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session token not found')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1/edu_app_server/course_schedule.php'),
        body: {'session_token': _sessionToken},
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _courseSchedule = responseData['data'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load course schedule')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching course schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _addCourse() async {
    if (_sessionToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session token not found')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1/edu_app_server/add_courses.php'),
        body: {
          'session_token': _sessionToken,
          'course': _courseController.text,
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Course added successfully')),
          );
          _fetchCourseSchedule(); // Refresh the course schedule
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add course')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error adding course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Schedule Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _courseSchedule.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_courseSchedule[index]['course_name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code: ${_courseSchedule[index]['course_code']}'),
                        Text('Instructor: ${_courseSchedule[index]['instructor']}'),
                        Text('Schedule: ${_courseSchedule[index]['schedule']}'),
                      ],
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: _courseController,
              decoration: InputDecoration(labelText: 'Add Course'),
            ),
            ElevatedButton(
              onPressed: _addCourse,
              child: Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }
}