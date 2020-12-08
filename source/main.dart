import 'dart:core';
import 'dart:io';
import 'mime.dart'; // Mime type map object is defined in seperate file
import 'fileContent.dart';
import 'databaseMethods.dart';
import 'dart:convert' show utf8; // For converting POST requests body content into a more usable format

// Handles the getting of resources for a client (GET requests or resources for POST request)
// Input: HttpRequest request - to get and send info with client
//        loginThruPost - A boolean that is set to true if this get is for a client that has just successfully logged in and so is valid but hasn't gotten a cookie yet
// Output: request is used to send the client the appriopriate file content
void handleGet(HttpRequest request, bool loginThruPost) async {
  // Get the file being requested, then modify to access it the appriopriate resource locally
  String filePath = request.uri.toString();
  bool verified = loginThruPost;
  // Determine if they are logged in by checking the cookies
  if (request.headers["Cookie"] != null && !verified) {
    verified = verifyCookieAccess(request.headers["Cookie"] as List<String>);
  }
  // If accessing the default directory, set to home page by default
  if ((filePath == "/" && verified) || (filePath == "/login.html" && verified)) {
    filePath = "/home.html";
  }
  // If actually not verified, redirect if going to wrong place
  if (!verified && (filePath.contains(".html"))) {
    if (filePath != "/login.html" && filePath != "/signup.html") {
      filePath == "/login.html";
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
  print(bodyMap.toString());
  if (bodyMap["submission"] == "login") {
    // Verify login
    if (verifyLoginCred(bodyMap["username"] as String, bodyMap["password"] as String)) {
      // Currently bad implementation of cookie, needs to use database/encryption or something to make much more secure and also identifiable for a specific account
      request.response.headers.add("Set-Cookie", "1");
      loggedIn = true;
    }
    // Have handleGet perform the resulting body content for home.html
    return handleGet(request, loggedIn);
  }
  else if (bodyMap["submission"] == "updateTask") {
    updateData(bodyMap);
  }
  else if (bodyMap["submission"] == "createTask") {
    createTask(bodyMap);
  }
  request.response.add([]);
  request.response.close();
  return;
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
