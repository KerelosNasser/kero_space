import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;

void main() async {
  final dio = Dio();
  const ticker = 'COMI';
  final url = 'https://english.mubasher.info/markets/EGX/stocks/$ticker';
  
  try {
    final response = await dio.get(url, options: Options(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }
    ));
    
    print('Status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      var document = parse(response.data);
      // Let's print all class names of elements that look like price to see if the selector changed
      var priceElement = document.querySelector('.market-summary__price');
      print('Selector .market-summary__price: ${priceElement?.text}');
      
      // Let's find other candidate elements if the selector is null
      if (priceElement == null) {
        // Find elements with classes that contain 'price' or 'value'
        var allText = document.body?.text ?? '';
        print('Document length: ${allText.length}');
        
        // Find all divs or spans containing class like price
        var divs = document.querySelectorAll('div');
        for (var div in divs) {
          var className = div.className;
          if (className.contains('price') || className.contains('summary')) {
            print('Found element: class="$className", text="${div.text.trim()}"');
          }
        }
        
        var spans = document.querySelectorAll('span');
        for (var span in spans) {
          var className = span.className;
          if (className.contains('price') || className.contains('value')) {
            print('Found span: class="$className", text="${span.text.trim()}"');
          }
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
