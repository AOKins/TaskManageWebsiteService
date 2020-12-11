import 'dart:io';

// Takes in an inputted body and converts into a map
// '&' seperates pairs, '=' for (key,value)
// Input: string containing variables to parse through
// Output: Map equivalent of inputted string with variable names as keys
Map<String,String> convertBody(String input) {
  List<int> ampIndexes = [];  // List to store the indexes where the & are
  List<int> equIndexes = [];  // List to store the indexes where the = are
  Map<String, String> result = new Map<String,String>();

  ampIndexes.add(-1); // Adding -1 as index for first ampersand (start of first assignment)
  for (int i = 0; i < input.length; i++) {
    if (input[i] == '&') {
      ampIndexes.add(i);
    } else if (input[i] == '=') {
      equIndexes.add(i);
    }
  }
  ampIndexes.add(input.length);  // Adding length (just out of range of end of string) as last ampersand

  String left, right;
  for (int i = 0; i < equIndexes.length; i++) {
    left = input.substring(ampIndexes[i]+1, equIndexes[i]);
    right = input.substring(equIndexes[i]+1, ampIndexes[i+1]);
    
    result[left] = right;
  }
  return result;
}

// Takes the path and returns the binary result
// Input: filePath - string to where the file is
// Output: returns the file contents as bytes, null if error occurs (outputs error to terminal)
List<int> fileContentsBytes(String filePath) {
  try {
    var resourceFile = new File(filePath);
    return resourceFile.readAsBytesSync();
  }
  catch(e) {
    print(e);
    return [];
  }
}
