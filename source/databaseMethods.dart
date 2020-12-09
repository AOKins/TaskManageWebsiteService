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
  for (int i = 0; i < cookies.length; i++) {
    var results = await performQueryOnMySQL('SELECT COUNT(*) FROM task_manager.user WHERE ID = ' + cookies[i]);
    // Like verifyLoginCred, this is a hard coded bad method that needs to be replaced with usage of the database
    for (var row in results) {
      if (row[0] >= 0) {
        return cookies[i];
      }
    }
  }
  return "";
}

// Method to determine if a user attempting to login has the correct username and password
// Requires query to database for id that matches given username and password
Future<String> verifyLoginCred(String givenUser, String givenPass) async {
  String query = "SELECT ID FROM task_manager.user WHERE username = '$givenUser' AND password='$givenPass'";  
  var results = await performQueryOnMySQL(query);
  for (var row in results) {
    return row[0].toString();
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
}
