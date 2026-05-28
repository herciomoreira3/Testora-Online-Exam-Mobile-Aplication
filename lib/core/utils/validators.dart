class Validators {
  static String? validateEmail(
    String? value,
    String emptyError,
    String invalidError,
  ) {
    if (value == null || value.trim().isEmpty) {
      return emptyError;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return invalidError;
    }
    return null;
  }

  static String? validatePassword(
    String? value,
    String emptyError,
    String minLengthError,
  ) {
    if (value == null || value.isEmpty) {
      return emptyError;
    }
    if (value.length < 6) {
      return minLengthError;
    }
    return null;
  }
}
