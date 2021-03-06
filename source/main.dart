import 'dart:core';
import 'dart:io';
import 'httpHandles.dart';
//Helpful resource to developing initial understanding of HttpServer on Dart and approach to its implementation https://dart.dev/tutorials/server/httpserver
void main() async {
  int portNum = 800;
  // Create server object with local address and port 800 (note: does not conform to default HTTP port which is 80)
  var server = await HttpServer.bind(InternetAddress.anyIPv4, portNum);
  print("Opening the following: " + server.address.address.toString() + ":" + portNum.toString());

  // Wait for requests in the server object, handling the requests
  await for (HttpRequest request in server) {
    // Requests handled in appriopriate function
    // Outputting the request method and uri to terminal
    print(request.method + " " + request.requestedUri.toString());
    switch (request.method) {
      case 'GET':
        // second argument false because this handle is not from logging in and so therefore flagged is expecting a cookie to provide verification
        handleGet(request, false);
        break;
      case 'POST':
        handlePost(request);
        break;
    }
  }
}
