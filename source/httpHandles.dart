import 'dart:convert' show utf8; // For converting POST requests body content into a more usable format
import 'mime.dart'; // Mime type map object is defined in seperate file
import 'dart:core';
import 'dart:io';

import 'fileContent.dart';
import 'databaseMethods.dart';

// Handles the getting of resources for a client (GET requests or resources for POST request)
// Input: HttpRequest request - to get and send info with client
//        loginThruPost - A boolean that is set to true if this get is for a client that has just successfully logged in and so is valid but hasn't gotten a cookie yet
// Output: request is used to send the client the appriopriate file content
void handleGet(HttpRequest request, bool loginThruPost) async {
  // Get the file being requested, then modify to access it the appriopriate resource locally
  String filePath = request.uri.toString();
  // If logging in through the post, then set the verifiedS to "loggedIn" as validation 
  String verifiedS = loginThruPost ? "loggedIn" : "";

  // Determine if they are logged in by checking the cookies if they are not loggedIn through post
  if (request.headers["Cookie"] != null && verifiedS == "") {
    verifiedS = await verifyCookieAccess(request.headers["Cookie"]);
  }

  // If accessing the default directory, set to home page by default
  if (filePath == "/") {
      filePath = "/home.html";
  }
  // Get file format and add content-type header using MIME type
  String fileFormat = filePath.substring(filePath.lastIndexOf(".")+1);

  // If couldn't determine a verification, then replace the resource being requested to login.html
  if (verifiedS == "" && (filePath != "/signup.html" && filePath != "/login.html") && fileFormat == "html") {
      filePath = "/login.html";
  }
  
  // Append path to resources folder
  filePath = "../resources" + filePath;
  request.response.headers.add("content-type", mimeTypesMap[fileFormat] ?? "application/octet-stream");

  // Get, write, and then close the response, ending conversation
  var bodyContent = fileContentsBytes(filePath);

  request.response.statusCode = (bodyContent != []) ? 200 : 404;  // If the content is empty, then the resource is assumed was not found (404 error code)
  request.response.add(bodyContent);

  request.response.close();
}

// Function to handle when the client is making a POST request (which atm is only when logging in)
// Input: HttpRequest object to get and send with client
// Output: If valid login, gives new valid cookie and then passes the request to handleGET
void handlePost(HttpRequest request) async {
  // Get body of Post message from request as a map
  Map<String,String> bodyMap = convertBody(await utf8.decodeStream(request));
  bool loggedIn = false;

  // Result stores the content for responding body
  List<int> result;

  // If the POST method is logging in then the body content is login attempt info that needs to be handles
  if (bodyMap["submission"] == "login") {
    String verifyS = await verifyLoginCred(bodyMap["username"] as String, bodyMap["password"] as String);
    // Verify login
    if (verifyS != null) { // If could not verifiy
      // Currently bad implementation of cookie, needs to use database/encryption or something to make much more secure and also identifiable for a specific account
      request.response.headers.add("Set-Cookie", verifyS);
      loggedIn = true;
    }
    // Have handleGet perform the resulting body content for requested page
    return handleGet(request, loggedIn);
  }

  // If the POST method is in a new user creating an account, need to determine if that's successful or not
  else if (bodyMap["submission"] == "createUser") {
    // Attempt to create the user
    String id = await attemptCreateUser(bodyMap);

    // If the id is not null then successs and set cookie to the newly created id
    if (id != null) {
      request.response.headers.add("Set-Cookie", id);
      result = utf8.encode("result=success");
    }
    // If the id is null that means the user could not be created (duplicate username attempted to be created)
    else {
      result = utf8.encode("result=failure");
    }  
  }
  else {
    // If not logging in or sign up, then they must have a cookie that identifies them so try and get it
    String userID_S;
    try {
      userID_S = await verifyCookieAccess(request.headers["Cookie"] as List<String>);
    }
    catch (e) {
      print(e);
      request.response.close();
      return;
    }
    print("cookie: " + userID_S);
      // Add the id to the map
    bodyMap["user_id"] = userID_S;
    // Determine if verified or not by checking the string before checking submission 
    if (userID_S != "") {

      // https://www.geeksforgeeks.org/switch-case-in-dart/
      // Check what action is being requested using the key "submission" and call the appriopriate function
      // get methods return results, update/create/etc. don't
      switch (bodyMap["submission"]) {
        case "getTask" : {
          result = await getTask(bodyMap);
        } break;
        case "getCategories" : {
          result = await getCategories(bodyMap);
        } break;
        case "updateTask" : {
          updateTask(bodyMap);
        } break;
        case "createTask" : {
          createTask(bodyMap);
        } break;
        case "deleteTask" : {
          deleteTask(bodyMap);
        } break;
        case "shareCategory" : {
          shareCategory(bodyMap);
        } break;
      }
    }
  }
  // If results has content, then be sure to return it to the client before closing the connection
  
  // Set mime type to json for results, if the map is null (not defined) default to application/octet-stream
  request.response.headers.add("content-type", mimeTypesMap["json"] ?? "application/octet-stream");
  // If result is null than add an empty list
  request.response.add(result ?? []);
  request.response.close();
}
