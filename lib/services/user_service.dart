class UserService {
  static final List<Map<String, String>> _users = [];

  static void addUser(String username, String email, String password) {
    _users.add({'username': username, 'email': email, 'password': password});
  }

  static Map<String, String>? getUser(String input) {
    return _users.firstWhere(
      (user) => user['email'] == input || user['username'] == input,
      orElse: () => {},
    );
  }

  static bool validatePassword(Map<String, String> user, String password) {
    return user['password'] == password;
  }

  static bool userExists(String email, String password) {
    return _users.any((user) =>
        user['email'] == email && user['password'] == password);
  }
}