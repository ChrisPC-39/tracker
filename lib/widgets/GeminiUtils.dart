class GeminiUtils {
  static String model = 'gemini-1.5-pro';

  String getFinInstructions(
    List<String> categoryStringList,
    List<String> currencyStringList,
  ) {
    return '''
        Your task is to read a piece of text and determine the following information, formatted as a JSON object:
        {
          "items": ["item1", "item2", ...], // Reformatted item names
          "pieces": ["1x", "2x", ...], // Amount of each item. Reformat to remove any numbers after "," and make sure it doesn't contain any string except for "x"
          "prices": ["price1", "price2", ...], 
          "category": "Category from list", //list: $categoryStringList
          "total_price": "total price", 
          "store": "store name/None",
          "payment": "Cash/Card/None",
          "currency": "Currency from list", //list: $currencyStringList
        }
        The text you read may not be in english. Keep them in the original language when returning them.
        If something is not known, return "none" for that key.
        Don't include any explanatory text outside the JSON object and don't include any formatting. I only want a JSON object returned. 
        Do not add ```json at the beginning or ``` at the end of the output.
      ''';
  }
}
