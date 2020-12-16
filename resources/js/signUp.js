var signUp = document.getElementById("signUp")

// Function called when submitting that takes contents of resulting attempt to create user, alerts if invalid, redirects to home if successful (should have cookie now from server for access)
function successCheck(content) {
    // If failure, then alert the user of invalid submission
    if (content.toString() == "result=failure") {
        alert("invalid submission");
    }
    // Successfully created a user and got a cookie for with ID!
    else if (content.toString() == "result=success") {
        // With this success, redirect to home
        // https://www.w3schools.com/howto/howto_js_redirect_webpage.asp for seeing how to redirect user from one page to another
        window.location.replace(location.protocol + "//" + location.host + "/home.html");
    }
}

// Create submit event listener if the signUp object is not null
if (signUp != null) {
    signUp.addEventListener("submit", async function(event) {        
        event.preventDefault() // Prevent default behaviors
        
        // Get the submitted username, password, and confirmation password
        var NewName = signUp[0];
        var NewPass = signUp[1];
        var confirmPass = signUp[2];
        // First verify the password and clear if not valid
        if (NewPass.value != confirmPass.value) {
            alert("invalid credentials");
        }
        else {
            // Generate body content
            var s_content = "submission=createUser&username=" + NewName.value + "&password=" + NewPass.value;
            
            // Attempt to create new user, if the username already exists then deny
            let data = await fetch(location.protocol + "//" + location.host, {
                method: 'POST',
                body: s_content,
            });
            if (!data.ok) {
                alert("Could not establish connection to server");
            }
            // If received the data okay, call outputTasks with JSON parsing of the content
            else {
                data.text().then((content) => successCheck(content));
            }
        }
        // Clear form contents
        NewName.value = "";
        NewPass.value = "";
        confirmPass.value = "";
    });
}
