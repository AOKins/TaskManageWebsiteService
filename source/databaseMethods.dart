import 'dart:convert';
import 'package:mysql1/mysql1.dart'; // For connecting into MySQL

// A simple handler to return results of a query from the task_manager database
// Assumed access is already granted and just need to get results
// Input: query - string for SQL statement to perform
// Output: returns results of query in Results object
Future<Results> performQueryOnMySQL(String query) async {
  // Attempt to open a connection and perform a query
  try {
    var settings = new ConnectionSettings(
      host: 'localhost', 
      port: 3306,
      user: 'testUser', // test user to login into with using unsecure password
      password: "password",
      db: 'task_manager', // connect to task_manager database in the server
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

// Method to determine if a client is in possession of a valid cookie by checking against user IDs
// Input: List of strings containing all the cookies from the client
// Output: "" if no user found matching cookie for userID, returns cookie that matches userID 
Future<String> verifyCookieAccess(List<String> cookies) async {
  // If the there are cookies then we need to iterate through them and perform a query to see if it's in the DBMS
  if (cookies.length != null) {
    for (int i = 0; i < cookies.length; i++) {
      var results = await performQueryOnMySQL('SELECT COUNT(*) FROM user WHERE ID = ' + cookies[i]);
      // Like verifyLoginCred, this is a hard coded bad method that needs to be replaced with usage of the database
      for (var row in results) {
        if (row[0] > 0) {
          return cookies[i];
        }
      }
    }
  }
  // Return "" if no user was found
  return "";
}

// Method to determine if a user attempting to login has the correct username and password
// Requires query to database for id that matches given username and password
// Input: given username and password to find user in DBMS with
// Output: User ID in form of a string that was found
Future<String> verifyLoginCred(String givenUser, String givenPass) async {
  String query = "SELECT ID FROM user WHERE username = '$givenUser' AND password='$givenPass'";  
  var results = await performQueryOnMySQL(query);
  for (var row in results) {
    if (row[0] != 0) {
      return row[0].toString();
    }
  }
  // Return "" if no user was found
  return "";
}

// Method called when needing to update task data (currently only handles completion value)
// Input: inputData - map that contains the inputted data relevant to the update (such as task_id and new description)
// Output: DBMS has task with matching inputData["task_id"] with completion attribute set to inputData["completion"]
void updateTask(Map<String,String> inputData) {
  String query;
  int completion = 0;
  // Get the completion value
  if (inputData["completion"] != null ) {
    completion = (inputData["completion"] == "true") ? 1 : 0;
  }
  // Get the id of the task and setup/perform the query
  var taskID = inputData["task_id"];
  query = "UPDATE task SET completion=$completion WHERE ID=$taskID;";
  performQueryOnMySQL(query);
}

// Insert a new category into the DBMS
// Input: Strings for setting owner, name, and color for new category
// Output: returns categoryID for new category 
Future<String> createCategory(String owner, String name, String color) async {
  String query;
  // Insert new category into the DBMS
  query = "INSERT INTO category (ownerID, name, color) VALUES ($owner, '$name', '$color')";
  await performQueryOnMySQL(query);
  // Get the id of the new category using the new id and name
  query = "SELECT ID FROM category WHERE ownerID=$owner AND name='$name'";
  Results results = await performQueryOnMySQL(query);
  // Return the result
  for (var value in results) {
    return value[0].toString();
  }
}

// Create a new category (called when createTask has a category *New*)
// Input: category name, user creating the category and color
// Output: New category is created in the DBMS tied to the provided userID
void createTask(Map<String,String> inputData) async {
    String id;
    // If a new category was created with this task, must first create the category before getting id 
    if (inputData["category"] == "*New*") {
      id = await createCategory(inputData["user_id"], inputData["categoryText"], inputData["color"]);
    }
    else {
    // If not a new category, then "category" key should hold the id
      id = inputData["category"];
    }
    String dueTime = inputData["due_date"] + " " + inputData["due_time"];
    // Trim to remove spaces from ends if they exist 
    dueTime = dueTime.trim();
    // Generate query and perform
    String query = "INSERT INTO task_manager.task (title,description,dateTime,ownerID,categoryID) ";
    query += "VALUES ('" + inputData["title"] + "','" + inputData["desc"] + "', '$dueTime:00'," + inputData["user_id"] + ",$id)";
    performQueryOnMySQL(query);

}

// Method to getting a task
// Input: startDate and endDate and userID
// Output: Binary output (list<int>) of results to be interpreted as a json of results
//            Contains task info to display to user and identify tasks
Future<List<int>> getTask(Map<String,String> inputData) async {
  String startRange = inputData["startDate"];
  String endRange = inputData["endDate"];
  String user_id = inputData["user_id"];
  
  String query = "SELECT ID, title, description, dateTime, completion FROM task_manager.task WHERE ownerID=$user_id AND DATE(dateTime) >= '$startRange' AND DATE(dateTime) <= '$endRange' ORDER BY dateTime";

  // Create a map to a list of Maps, use date as key to list of task info in the form of maps
  Map<String, List< Map<String,String>>> content = new Map();
  Results results = await performQueryOnMySQL(query);

  String dateTime, date;// temp holder for a row's dateTime
  // For each row, append into the content map the row's data as a adding on the list a new map
  results.forEach((row) => {
    // Get the time and date seperately
    dateTime = row[3].toString(),
    date = dateTime.substring(0, dateTime.indexOf(' ') ),

    // If this date does not point to a list (first row with this date), then set to new list
    content[date] ??= new List<Map<String,String>>(),

    // Using this row's data, append a new map to the list
    content[date].add(
      {
        "task_id": row[0].toString(),
        "title" : row[1].toString(),
        "desc" : row[2].toString(),
        "dateTime" : dateTime,
        "checked" : row[4] == 0 ? "false" : "true",
      }
    )
  });
  // Encode the map into a json string
  String jsonContent = json.encode(content);
  // Encode the json string into utf8
  return utf8.encode(jsonContent);
}

// Get categories that a user owns and all available colors
// Input: userID from inputData
// Output: a utf8 encoded json containing the user's available categories and colors
Future<List<int>> getCategories(Map<String,String> inputData) async {
  // Get user id and and generate query to get categories that the user owns
  String userID = inputData["user_id"];
  String query = "SELECT id, name FROM task_manager.category WHERE ownerID=$userID";
  Results results = await performQueryOnMySQL(query);

  Map<String,List<Map<String,String>>> content = new Map();
  // Have list of category names and ids the the user has as options that they own
  content["category_options"] ??= new List<Map<String,String>>();
  results.forEach((row) => {
    content["category_options"].add(
    {
      "id" : row[0].toString(),
      "name" : row[1].toString(),
    })
  });

  // Have list of colors available for creating categories
    content["color_options"] ??= new List<Map<String,String>>();
  query = "SELECT color FROM task_manager.color";
  results = await performQueryOnMySQL(query);

  results.forEach((row) => {
    content["color_options"].add(
    {
      "option": row[0],
    })
  });
  // Return the content encoded first into json structure, then into uft8 for response body
  return utf8.encode(json.encode(content));
}
