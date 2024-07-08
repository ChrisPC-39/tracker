import 'dart:convert';

class GeminiUtils {
  static String model = 'gemini-1.5-pro';

  static String getFinInstructions(
    List<String> categoryStringList,
    List<String> currencyStringList,
  ) {
    return '''
        Your task is to read a receipt and determine the following information, which you will return formatted as a JSON object:
        {
          "items": ["item1", "item2", ...], // Rename the item names to something normal only if you know what they are (for example remove the underscores from PM_Coca_Cola and the unnecessary 'PM' from the beginning)
          "pieces": [1, 2, ...], // Amount of each item as double. Reformat any "," to "." and make sure it doesn't contain any string
          "prices": [price1, price2, ...], // Price of each item as double.
          "category": "Category from list", //list: $categoryStringList
          "total_price": total, // total price as double. If you can't read it, calculate it based on pieces*price.
          "store": "store name/Transaction", // if you do not know return "Transaction"
          "payment": "Cash/Card/Other", // if you do not know return "Other"
          "currency": "Currency from list", //list: $currencyStringList
        }
        The text you read may not be in english. Keep them in the original language when returning them.
        Don't include any explanatory text outside the JSON object and don't include any formatting. I only want a JSON object returned. 
        Do not add ```json at the beginning or ``` at the end of the output.
      ''';
  }

  Map<String, dynamic> validateOutput(String output) {
    Map<String, dynamic> jsonData = jsonDecode(output);
    Map<String, dynamic> validatedJson = {};

    try {
      List<String> items = List<String>.from(jsonData['items']);
      validatedJson['items'] = items;
    } catch (e) {
      validatedJson['items'] = [];
    }

    try {
      List<dynamic> piecesDynamic = jsonData['pieces'];
      List<double> pieces = piecesDynamic.cast<double>();
      validatedJson['pieces'] = pieces;
    } catch (e) {
      validatedJson['pieces'] = [];
    }

    try {
      List<dynamic> pricesDynamic = jsonData['prices'];
      List<double> prices = pricesDynamic.cast<double>();
      validatedJson['prices'] = prices;
    } catch (e) {
      validatedJson['prices'] = [];
    }

    try {
      String category = jsonData['category'];
      validatedJson['category'] = category;
    } catch (e) {
      validatedJson['category'] = "";
    }

    try {
      String currency = jsonData['currency'];
      validatedJson['currency'] = currency;
    } catch (e) {
      validatedJson['currency'] = "";
    }

    try {
      String payment = jsonData['payment'];
      validatedJson['payment'] = payment.toLowerCase();
    } catch (e) {
      validatedJson['payment'] = "other";
    }

    try {
      String store = jsonData['store'];
      validatedJson['store'] = store;
    } catch (e) {
      validatedJson['store'] = "Transaction";
    }

    try {
      double totalPrice = jsonData['total_price'];
      validatedJson['total_price'] = totalPrice;
    } catch (e) {
      validatedJson['total_price'] = 0.0;
    }

    validatedJson = expandArrays(validatedJson);

    return validatedJson;
  }

  Map<String, dynamic> expandArrays(Map<String, dynamic> validatedJson) {
    List<dynamic> items = validatedJson['items'] ?? [];
    List<dynamic> pieces = validatedJson['pieces'] ?? [];
    List<dynamic> prices = validatedJson['prices'] ?? [];

    // Determine the length of the longest array
    int maxLength = [items.length, pieces.length, prices.length].reduce((a, b) => a > b ? a : b);

    // Function to expand an array to the specified length
    void expandList(List<dynamic> list, int length, dynamic val) {
      while (list.length < length) {
        list.add(val);  // Adding null as the empty value
      }
    }

    // Expand each array to the maxLength
    expandList(items, maxLength, "Unknown");
    expandList(pieces, maxLength, 0.0);
    expandList(prices, maxLength, 0.0);

    // Update the validatedJson map with the expanded arrays
    validatedJson['items'] = items;
    validatedJson['pieces'] = pieces;
    validatedJson['prices'] = prices;

    return validatedJson;
  }
}
