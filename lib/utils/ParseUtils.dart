class ParseUtils {
  static double parseDoubleFromString(String str) {
    if(str.isEmpty) return 0.0;
    String normalizedStr = str.replaceAll(',', '.');
    double parsedValue = double.parse(normalizedStr);
    return parsedValue;
  }

  static List<double> getDoubleListFromDynamicList(List<dynamic> list) {
    List<double> doubleList = [];
    for(int i = 0; i < list.length; i++) {
      doubleList.add(parseDoubleFromString(list[i].toString()));
    }

    return doubleList;
  }

  static List<String> getCategoriesAsStringList(List<dynamic> categories) {
    List<String> categoriesAsStringList = [];
    for(int i = 0; i < categories.length; i++) {
      categoriesAsStringList.add(categories[i]['type']);
    }

    return categoriesAsStringList;
  }

  static List<String> getDynamicListAsStringList(List<dynamic> list) {
    List<String> categoriesAsStringList = [];
    for(int i = 0; i < list.length; i++) {
      categoriesAsStringList.add(list[i]);
    }

    return categoriesAsStringList;
  }
}