import 'dart:core';
import 'dart:io';
import 'dart:convert' show utf8; // For converting POST requests body content into a more usable format

import 'mime.dart'; // Mime type map object is defined in seperate file
import 'fileContent.dart';
import 'databaseMethods.dart';

// Handles the getting of resources for a client (GET requests or resources for POST request)
// Input: HttpRequest request - to get and send info with client
//        loginThruPost - A boolean that is set to true if this get is for a client that has just successfully logged in and so is valid but hasn't gotten a cookie yet
// Output: request is used to send the client the appriopriate file content
void handleGet(HttpRequest request, bool loginThruPost) async {
  // Get the file being requested, then modify to access it the appriopriate resource locally
  String filePath = request.uri.toString();
  String verifiedS = loginThruPost ? "loggedIn" : "";
  // Determine if they are logged in by checking the cookies
  if (request.headers["Cookie"] != null && verifiedS != "") {
    verifiedS = await verifyCookieAccess(request.headers["Cookie"] as List<String>);
  }

  // If accessing the default directory, set to home page by default
  if (filePath == "/") {
    if (verifiedS != "") {
      filePath = "/login.html";
    }
    else {
      filePath = "/home.html";
    }
  }
  
  // Append path to resources
  filePath = "../resources" + filePath;
  // Get file format and add content-type header using MIME type
  String fileFormat = filePath.substring(filePath.lastIndexOf(".")+1);

  request.response.headers.add("content-type", mimeTypesMap[fileFormat] ?? "application/octet-stream");
  // Write response and close, ending conversation
  var bodyContent = fileContentsBytes(filePath);

  // If the content is empty, then the resource is assumed not found (404 error code)
  request.response.statusCode = (bodyContent != []) ? 200 : 404;
  request.response.add(bodyContent);
  request.response.close();
}

// Functiont to handle when the client is making a POST request (which atm is only when logging in)
// Input: HttpRequest object to get and send with client
// Output: If valid login, gives new valid cookie and then passes the request to handleGET
void handlePost(HttpRequest request) async {
  // Get body of Post message from request as a map
  Map<String,String> bodyMap = convertBody(await utf8.decodeStream(request));
  
  bool loggedIn = false;
  
  if (bodyMap["submission"] == "login") {
    String verifyS = await verifyLoginCred(bodyMap["username"] as String, bodyMap["password"] as String);
    // Verify login
    if (verifyS != "") { // If could not verifiy
      // Currently bad implementation of cookie, needs to use database/encryption or something to make much more secure and also identifiable for a specific account
      request.response.headers.add("Set-Cookie", verifyS);
      loggedIn = true;
    }
    // Have handleGet perform the resulting body content for home.html
    return handleGet(request, loggedIn);
  }
  else {
    // If not logging in (currently no way to sign up), then they must have a cookie that identifies them
    String userID_S = await verifyCookieAccess(request.headers["Cookie"] as List<String>);
    bool verified = (userID_S != null) ? true : false;
    if (verified) {
      bodyMap["user_id"] = userID_S;

      if (bodyMap["submission"] == "updateTask") {
        updateTask(bodyMap);
      }
      else if (bodyMap["submission"] == "createTask") {
        createTask(bodyMap);
      }
    }
  }
  request.response.add([]);
  request.response.close();
  return;
}

//Helpful resource to developing initial understanding of HttpServer on Dart and approach to its implementation https://dart.dev/tutorials/server/httpserver
void main() async {

  // Create server object with local address and port 800 (note: does not conform to default HTTP port being 80)
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 800);
  print("Opening the following: " + server.address.address.toString());

  // Wait for requests in the server object, handling the requests
  await for (HttpRequest request in server) {
    // Requests handled in appriopriate function
    // Outputting the request method and uri to terminal
    print(request.method + " " + request.requestedUri.toString());
    switch (request.method) {
      case 'GET':
        // second argument false because this handle is not from logging in and so therefore is expecting a cookie to provide verification
        handleGet(request, false);
        break;
      case 'POST':
        handlePost(request);
        break;
    }
  }
}
