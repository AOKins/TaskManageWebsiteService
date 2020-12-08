

// Method to determine if a client is in possession of a valid cookie
// Currently not valid means implemented, currently verifies by just checking for cookies in general
// Input: List of strings containing all the cookies from the client
// Output: true if one of the cookies is valid
bool verifyCookieAccess(List<String> cookies) {
  for (int i = 0; i < cookies.length; i++) {
    // Like verifyLoginCred, this is a hard coded bad method that needs to be replaced with usage of the database
    if (cookies[i] == (1).toString()) {
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


// Method called when needing to update data
// Input: inputData - map that contains the inputted data relevant to the update (such as task_id and new description)
// Output: DBMS should be updated
void updateData(Map<String,String> inputData) {
  print("A request to update data was received");
}

void createTask(Map<String,String> inputData) {
    print("New task received to be added");
}