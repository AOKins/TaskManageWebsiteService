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
      user: 'testUser', // test user to login into with using obvious password
      password: "password",
      db: 'task_manager', // connect to task_manager database in the server
    );

    var conn = await MySqlConnection.connect(settings);

    // Check to make sure the connection worked 
    if (conn == null){
      print('ERROR - COULD NOT CONNECT TO DBMS');
      return null;
    }
    else {
      try {

      var results = conn.query(query);

      conn.close();
      return results;
      }
      catch (e) {
        print("Invalid query -> $e");
      }
    }
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
      // Get results from the query looking for ID's that match the cookie's
      var results = await performQueryOnMySQL('SELECT ID FROM user WHERE ID = ' + cookies[i]);
      // If resulting match found then return first found
      for (var row in results) {
        if (row[0] > 0) {
          return cookies[i].toString();
        }
      }
    }
  }
  // Return "" if no cookie
  return "";

}

// Method to determine if a user attempting to login has the correct username and password
// Requires query to database for id that matches given username and password
// Input: given username and password to find user in DBMS with
// Output: User ID in form of a string that was found
Future<String> verifyLoginCred(String givenUser, String givenPass) async {
  // Query for finding user that has same username and password as login (username is assumed to be unique and so there couldn't possibly be multiple users)
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
    // Get the completion value and id of the task to setup/perform the query
    completion = (inputData["completion"] == "true") ? 1 : 0;
    var taskID = inputData["task_id"];

    // Setup the query to update the task's completion value
    query = "UPDATE task SET completion=$completion WHERE ID=$taskID;";
    // Perform the query and do not get/return results
    performQueryOnMySQL(query);
  }
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

  // Return the result or null if not successful
  if (results.first != null) {
    return results.first[0].toString();
  }
  else {
    return null;
  }
}

// Create a new category (called when createTask has a category *New*)
// Input: category name, user creating the category and color
// Output: New category is created in the DBMS tied to the provided userID
void createTask(Map<String,String> inputData) async {
    String id;
    // If a new category was created with this task, must first create the category before getting id 
    if (inputData["categoryCreate"] == "*New*") {
      id = await createCategory(inputData["user_id"], inputData["categoryText"], inputData["color"]);
    }
    else {
    // If not a new category, then "category" key should hold the id
      id = inputData["categoryCreate"];
    }
    var dueDateTime = DateTime.parse(inputData["dateTime"]);
    String dueTime = dueDateTime.toString();

    // Generate query and perform, do not get results
    String query = "INSERT INTO task_manager.task (title,description,dateTime,ownerID,categoryID, completion, recurringID) ";
    query += "VALUES ('" + inputData["title"] + "','" + inputData["desc"] + "', '$dueTime'," + inputData["user_id"] + ", $id, 0, 0)";
    performQueryOnMySQL(query);
}

// Method to getting a task
// Input: startDate and endDate and userID
// Output: Binary output (list<int>) of results to be interpreted as a json of task info grouped by dates and ordered by dateTime
Future<List<int>> getTask(Map<String,String> inputData) async {
  String startRange = inputData["startDate"];
  String endRange = inputData["endDate"];
  String user_id = inputData["user_id"];
  
  String query = "";
  // Generating the query to get all tasks for a user in given time range, includes shared tasks and category info
  query += "SELECT task.ID, task.title, task.description, task.dateTime, task.completion, viewCategories.name, viewCategories.color, user.username as ownerName, task.ownerID ";
  query += "FROM (SELECT DISTINCT category.ID, category.ownerID as CategoryOwnerID, category.name, category.color FROM category LEFT OUTER JOIN share ON share.categoryID = category.ID ";
	query += "WHERE category.ownerID = $user_id OR (share.userID = $user_id AND share.categoryID = category.ID)) as viewCategories INNER JOIN task ON task.categoryID = viewCategories.ID, user ";
	query += "WHERE (task.categoryID = viewCategories.ID OR task.ownerID = $user_id) and user.ID = viewCategories.CategoryOwnerID AND task.dateTime >= '$startRange' AND task.dateTime <= '$endRange';";
  // Create a map to a list of Maps, use date as key to list of task info in the form of maps
  Map<String, List< Map<String,String>>> content = new Map();
  Results results = await performQueryOnMySQL(query);

  String dateTime, date, time;// temp holder variables for a row's dateTime info as strings

  // For each row, append into the content map the row's data as a adding on the list a new map
  results.forEach((row) => {
    // Get a string of date only to use for key and also of time only form dateTime attribute
    dateTime = row[3].toString(),
    date = dateTime.substring(0, dateTime.indexOf(' ') ),
    date.trim(),
    time = dateTime.substring(dateTime.indexOf(' '), dateTime.indexOf(' ') + 6),
    time = time.trim(),

    // If this date does not point to a list (first row with this date value), then set to new list of maps
    content[date] ??= new List<Map<String,String>>(),
    // Using this row's data, append a new map to the list
    content[date].add(
      {
        "task_id": row[0].toString(),
        "title" : row[1].toString(),
        "desc" : row[2].toString(),
        "date" : date,
        "time" : time,
        "completed" : row[4] == 0 ? "false" : "true",
        "categoryName" : row[5],
        "color" : row[6],
        "ownerName" : row[7],
        "shared" : row[8].toString() != user_id ? "true" : "false", // A seperate attribute dervied from comparing the ownerID of the task to the user's and returning true if not the same
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

  // Add category id and name of each row to the list
  results.forEach((row) => {
    content["category_options"].add({
      "id" : row[0].toString(),
      "name" : row[1].toString(),
    })
  });

  // Have list of colors available for creating categories
  content["color_options"] ??= new List<Map<String,String>>();
  query = "SELECT color FROM task_manager.color";
  results = await performQueryOnMySQL(query);

  // Add color names to the list
  results.forEach((row) => {
    content["color_options"].add({
      "option": row[0],
    })
  });

  // Return the content encoded first into json structure, then into uft8 for response body
  return utf8.encode(json.encode(content));
}

// Attempt to create a new user using provided username and password in inputData, returns failure response if not successful from DBMS
// Input: username and password string values from inputData map
// Output: If successful (new user created in dbms) returns resulting id as a string, if not succesful (something such as username is a duplicate) returns null
Future<String> attemptCreateUser(Map<String,String> inputData) async {
  String query;
  String username = inputData["username"];
  String password = inputData["password"];

  query = "INSERT INTO task_manager.user (username, password) VALUES ('$username' , '$password')";
  try {
    // Attempt to create user
    await performQueryOnMySQL(query);

    // No error so succesful creation! Now get the resulting id to return     
    query = "SELECT ID FROM task_manager.user WHERE username='$username' AND password='$password'";
    
    Results results = await performQueryOnMySQL(query); 

    // Return resulting ID value
    return results.first[0].toString();
  }
  catch (e) {
    print("ERROR $e");
    return null;
  }
}

// Method to handle deleting a task, given task id within inputData
// Permission assumed granted
// Input: task id for task being deleted
// Output: task with matching id is deleted from the database
void deleteTask(Map<String,String> inputData) {
  String query;
  String delete_id = inputData["task_id"];
  query = "DELETE FROM task_manager.task WHERE ID=$delete_id";
  // Perform the delete, no results expected
  performQueryOnMySQL(query);
}

// Method for getting the ID of a user with just their username (assumed username is unique but not key), called by shareCategory()
// Input: String of username being used to look up id
// Output: If user exists with ID, returns the ID as a string
Future<String> getUserIDfromUsername(String username) async {
  String query = "SELECT user.id FROM task_manager.user WHERE username='$username'";
  Results result = await performQueryOnMySQL(query);

  return result.first[0].toString();
}

// Method for sharing a category with another user
// Assumes the client making this action is the valid owner of the category and that the categoryID is valid
// Output: Assuming categoryID, client's ID, and the provided user ID to share with are valid, it is inserted into the share table
void shareCategory(Map<String,String> inputData) async {
  String query;
  // Get the values from the input data
  String categoryID = inputData["categoryID"];
  String userName = inputData["username"];
  String ownerID = inputData["user_id"];
  // Get the user id for the user with the provided username
  String userID = await getUserIDfromUsername(userName);

  // Generate and then perform the query
  query = "INSERT INTO task_manager.share (categoryID, userID, ownerID) VALUES ";
  query += "($categoryID, $userID, $ownerID)";
  performQueryOnMySQL(query);
}
