extension StringExtension on String {
    String toCapitalize() {
        return split(' ')
            .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
}

extension NullableStringExtension on String? {
    bool isNotNullOrEmpty() {
        return this != null || this == "";
    }
}
