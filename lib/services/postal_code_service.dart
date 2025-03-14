import 'dart:convert';
import 'package:http/http.dart' as http;

class PostalCodeService {
  static Future<String> fetchBuildingNumber(String postalCode) async {
    if (postalCode.length != 6) {
      return 'Invalid';
    }

    var url = Uri.parse('https://www.sglocate.com/api/json/searchwithpostcode.aspx');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'APIKey': '394A6F696E304AE2AD1FE6AE92B6DF33B1FF166FAAD74903BCB2DE7180955402',
        'APISecret': 'D212808035CB4E3BA6BA807790E5F4F28248E8AB6CFD4EC68B6B3917318A2EAB',
        'Postcode': postalCode,
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['IsSuccess'] == true && data['Postcodes'] != null && data['Postcodes'].isNotEmpty) {
        return data['Postcodes'][0]['BuildingNumber'] ?? 'N/A';
      }
    }
    return 'Not Found';
  }
}
