extension ListExtension<T> on List<T> {
    T? firstWhereOrNull(bool Function(T) value) {
        for (var element in this) {
            if (value(element)) return element;
        }

        return null;
    }
}
