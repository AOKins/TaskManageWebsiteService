import 'dart:convert';

import 'package:mysql1/mysql1.dart'; // For connecting into MySQL

// A simple handler to return results of a query from the task_manager database
// Assumed access is already granted and just need to get results
Future<Results> performQueryOnMySQL(String query) async {
  // Open a connection
  try {
    var settings = new ConnectionSettings(
      host: 'localhost', 
      port: 3306,
      user: 'testUser', // test user to login into with using unsecure password
      password: "password",
      db: 'task_manager',
    );

    var conn = await MySqlConnection.connect(settings);

    //figured it would at least get here so i could see if it worked but i dont think it gets there 
    if (conn == null){
      print('ERROR - COULD NOT CONNECT TO DBMS');
    }

    var results = conn.query(query);

    conn.close();
    return results;
  }
  catch(e) {
    print("ERROR WITH QUERY -> $e");
    return e;
  }
}

// Method to determine if a client is in possession of a valid cookie
// Currently not valid means implemented, currently verifies by just checking for cookies in general
// Input: List of strings containing all the cookies from the client
// Output: true if atleast one of the cookies is valid
Future<String> verifyCookieAccess(List<String> cookies) async {
  // Finally, close the connection
  if (cookies.length != null) {
    for (int i = 0; i < cookies.length; i++) {
      var results = await performQueryOnMySQL('SELECT COUNT(*) FROM task_manager.user WHERE ID = ' + cookies[i]);
      // Like verifyLoginCred, this is a hard coded bad method that needs to be replaced with usage of the database
      for (var row in results) {
        if (row[0] > 0) {
          return cookies[i];
        }
      }
    }
    print("not verified");
  }
  return "";
}

// Method to determine if a user attempting to login has the correct username and password
// Requires query to database for id that matches given username and password
Future<String> verifyLoginCred(String givenUser, String givenPass) async {
  String query = "SELECT ID FROM task_manager.user WHERE username = '$givenUser' AND password='$givenPass'";  
  var results = await performQueryOnMySQL(query);
  for (var row in results) {
    if (row[0] != 0) {
      return row[0].toString();
    }
  }
}

// Method called when needing to update task data (currently only handles completion value)
// Input: inputData - map that contains the inputted data relevant to the update (such as task_id and new description)
// Output: DBMS should be updated
void updateTask(Map<String,String> inputData) {
  String query;
  int completion = 0;
  if (inputData["completion"] != null ) {
    completion = (inputData["completion"] == "true") ? 1 : 0;
  }
  var taskID = inputData["task_id"];
  query = "UPDATE task_manager.task SET completion = $completion WHERE ID=$taskID";
  performQueryOnMySQL(query);
}

void createTask(Map<String,String> inputData) {
    print("New task received to be added");
    print(inputData.toString());
}

// Method to getting a task
Future<List<int>> getTask(Map<String,String> inputData) async {
  String startRange = inputData["startDate"];
  String endRange = inputData["endDate"];
  String user_id = inputData["user_id"];
  
  String query = "SELECT ID, title, description, dateTime, completion FROM task_manager.task WHERE ownerID=$user_id AND DATE(dateTime) >= '$startRange' AND DATE(dateTime) <= '$endRange' ORDER BY dateTime";

  Map<String, List< Map<String,String>>> content = new Map();
  Results results = await performQueryOnMySQL(query);

  String dateTime, date, time;// temp holder for a row's dateTime
  // For each row, append into the content map the row's data as a adding on the list a new map
  results.forEach((row) => {
    // Get the time and date seperately
    dateTime = row[3].toString(),
    time = dateTime.substring(dateTime.indexOf(' ') + 1),
    date = dateTime.substring(0, dateTime.indexOf(' ') ),

    // If this date does not point to a list (first row with this date), then set to new list
    content[date] ??= new List<Map<String,String>>(),

    // Using this row's data, append a new map to the list
    content[date].add(
      {
        "task_id": row[0].toString(),
        "title" : row[1].toString(),
        "desc" : row[2].toString(),
        "date" : date,
        "due" : time,
        "checked" : row[4] == 0 ? "false" : "true",
      }
    )
  });

  String jsonContent = json.encode(content);
  
  return utf8.encode(jsonContent);
}

Future<List<int>> getCategories(Map<String,String> inputData) async {
  String userID = inputData["user_id"];
  String query = "SELECT name FROM task_manager.category WHERE ownerID=$userID";
  Results results = await performQueryOnMySQL(query);

  Map<String,List<String>> content = new Map();
  content["category_options"] = new List<String>();
  content["color_options"] = new List<String>();
  results.forEach((row) => {
    content["category_options"].add(
      row[0],
    )
  });

  
  query = "SELECT color FROM task_manager.color";
  results = await performQueryOnMySQL(query);
  results.forEach((row) => {
    content["color_options"].add(
      row[0],
    )
  });
  // Return the content encoded first into json structure, then into uft8 for response body
  return utf8.encode(json.encode(content));
}
