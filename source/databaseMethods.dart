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
      var results = await performQueryOnMySQL('SELECT COUNT(*) FROM user WHERE ID = ' + cookies[i]);
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
  String query = "SELECT ID FROM user WHERE username = '$givenUser' AND password='$givenPass'";  
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
  query = "UPDATE task SET completion=$completion WHERE ID=$taskID;";
  print(query);
  performQueryOnMySQL(query);
}


// Insert a new category into the DBMS
Future<String> createCategory(String owner, String name, String color) async {
  String query;
  query = "INSERT INTO category (ownerID, name, color) VALUES ($owner, '$name', '$color')";
  print(query);
  await performQueryOnMySQL(query);
  
  query = "SELECT ID FROM category WHERE ownerID=$owner AND name='$name'";

  print(query);;
  Results results = await performQueryOnMySQL(query);

  for (var value in results) {
    return value[0].toString();
  }
}

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
    dueTime = dueTime.trim();

    String query = "INSERT INTO task_manager.task (title,description,dateTime,ownerID,categoryID) ";
    query += "VALUES ('" + inputData["title"] + "','" + inputData["desc"] + "', '$dueTime:00'," + inputData["user_id"] + ",$id)";
    performQueryOnMySQL(query);

}

// Method to getting a task
Future<List<int>> getTask(Map<String,String> inputData) async {
  String startRange = inputData["startDate"];
  String endRange = inputData["endDate"];
  String user_id = inputData["user_id"];
  
  String query = "SELECT ID, title, description, dateTime, completion FROM task_manager.task WHERE ownerID=$user_id AND DATE(dateTime) >= '$startRange' AND DATE(dateTime) <= '$endRange' ORDER BY dateTime";

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

  String jsonContent = json.encode(content);
  
  return utf8.encode(jsonContent);
}

Future<List<int>> getCategories(Map<String,String> inputData) async {

  String userID = inputData["user_id"];
  String query = "SELECT id, name FROM task_manager.category WHERE ownerID=$userID";
  Results results = await performQueryOnMySQL(query);

  Map<String,List<Map<String,String>>> content = new Map();

  content["category_options"] ??= new List<Map<String,String>>();
  results.forEach((row) => {
    content["category_options"].add(
    {
      "id" : row[0].toString(),
      "name" : row[1].toString(),
    })
  });

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
