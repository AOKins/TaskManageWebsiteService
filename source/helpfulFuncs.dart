import 'dart:io';

// Takes in an inputted body and converts into a map
// '&' seperates pairs, '=' for (key,value)
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

// Method to determine if a client is in possession of a valid cookie
// Currently not valid means implemented, currently verifies by just checking for cookies in general
// Input: List of strings containing all the cookies from the client
// Output: true if one of the cookies is valid
bool verifyCookieAccess(List<String> cookies) {
  for (int i = 0; i < cookies.length; i++) {
    // Like verifyLoginCred, this is a hard coded bad method that needs to be replaced with usage of the database
    if (cookies[i] == "validcookie") {
      return true;
    }
  }
  return false;
}

// Method to determine if a user attempting to login has the correct username and password
// Currently not valid implementation, needs communication with the database or appriopriate portal to work as intended feature
bool verifyLoginCred(String givenUser, String givenPass) {
  print(givenUser + "  " + givenPass);
  // At the moment, this is the only valid login credentials and is hardcoded (the project needs to have this method replaced with communication with the Database server)
  if (givenUser == "admin" && givenPass == "password") {
    return true;
  }
  return false;
}


// input tells what needs to be updated
void updateData(Map<String,String> inputData) {

}
