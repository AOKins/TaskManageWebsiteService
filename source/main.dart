
import 'dart:core';
import 'dart:io';
import 'mime.dart'; // Mime type map object is defined in seperate file
import 'dart:convert' show utf8; // For converting POST requests body content into a more usable format

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

// Handles the getting of resources for a client (GET requests or resources for POST request)
// Input: HttpRequest request - to get and send info with client
//        loginThruPost - A boolean that is set to true if this get is for a client that has just successfully logged in and so is valid but hasn't gotten a cookie yet
// Output: request is used to send the client the appriopriate file content
void handleGet(HttpRequest request, bool loginThruPost) async {
  // Get the file being requested, then modify to access it the appriopriate resource locally
  String filePath = request.uri.toString();
  bool verified = loginThruPost;
  // Determine if they are logged in by checking the cookies
  if (request.headers["Cookie"] != null) {
    verified = verifyCookieAccess(request.headers["Cookie"] as List<String>);
  }
  // If accessing the default directory, set to home page by default
  if ((filePath == "/" && verified) || (filePath == "/login.html" && verified)) {
    filePath = "/home.html";
  }
  // If actually not verified, redirect to login page
  if (!verified && (filePath.contains(".html") || filePath == "/")) {
    filePath = "/login.html";
  }
  // Append path to resources
  filePath = "../resources" + filePath;
  // Get file format and add content-type header using MIME type
  String fileFormat = filePath.substring(filePath.lastIndexOf(".")+1);

  request.response.headers.add("content-type", mimeTypesMap[fileFormat] as String);
  // Write response and close, ending conversation
  var bodyContent = fileContentsBytes(filePath);
  // If the content is null, then the resource was not found
    
  request.response.add(bodyContent);
  await request.response.close();
}

// Functiont to handle when the client is making a POST request (which atm is only when logging in)
// Input: HttpRequest object to get and send with client
// Output: If valid login, gives new valid cookie and then passes the request to handleGET
void handlePost(HttpRequest request) async {
  // Get body of Post message from request as a map
  Map<String,String> bodyMap = convertBody(await utf8.decodeStream(request));
  bool loggedIn = false;
  if (bodyMap["submission"] == "login") {
    // Verify login
    if (verifyLoginCred(bodyMap["username"] as String, bodyMap["password"] as String)) {
      // Currently bad implementation of cookie, needs to use database/encryption or something to make much more secure and also identifiable for a specific account
      request.response.headers.add("Set-Cookie", "validcookie");
      loggedIn = true;
    }
  }
  // Have handleGet perform the resulting body content
  handleGet(request, loggedIn);
}

//Helpful resource to developing initial understanding of HttpServer on Dart and approach to its implementation https://dart.dev/tutorials/server/httpserver
void main() async {
  // Create server object with local address and port 80
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 80);
  print("Opening the following: " + server.address.address.toString());

  // Wait for requests in the server object, handling the requests
  await for (HttpRequest request in server) {
    // Requests handled in appriopriate function
    print(request.method + " " + request.requestedUri.toString());
    switch (request.method) {
      case 'GET':
        handleGet(request, false);
        break;
      case 'POST':
        handlePost(request);
        break;
    }
  }
}
