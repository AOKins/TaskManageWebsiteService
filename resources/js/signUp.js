var signUp = document.getElementById("signUp")

// Function called when submitting that takes contents of resulting attempt to create user, alerts if invalid, redirects to home if successful (should have cookie now from server for access)
function successCheck(content) {
    if (content.toString() == "result=failure") {
        alert("invalid submission");
    }
    else if (content.toString() == "result=success") {
        // Successfully created a user and got a cookie for with ID!
        // With this success, redirect to home
        // https://www.w3schools.com/howto/howto_js_redirect_webpage.asp for seeing how to redirect user from one page to another
        window.location.replace(location.protocol + "//" + location.host + "/home.html");
    }
}


if (signUp != null) {
    signUp.addEventListener("submit", async function(event) {        
        event.preventDefault()
        
        var NewName = signUp[0];
        var NewPass = signUp[1];
        var confirmPass = signUp[2];
        if (NewPass.value != confirmPass.value) {
            alert("invalid credentials");
            NewPass.value = "";
            confirmPass.value = "";
        }
        else {
            var s_content = "submission=createUser&username=" + NewName.value + "&password=" + NewPass.value;
            // Clear form contents
            NewName.value = "";
            NewPass.value = "";
            confirmPass.value = "";
            
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
    });
}
