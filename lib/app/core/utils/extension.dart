extension StringExtensions on String {
  String getFirstTwoWordInitials() {
    List<String> words = split(' ');

    return words.take(2).map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join();
  }
}
