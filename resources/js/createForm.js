// Javascript file to hold behavior related to the create Task form
// Assumes that there is a function loadContent() in another javascript file loaded by the page that can be called to refresh the tasks

// Node to 
var showButtonNode = document.getElementById("display");
// Node for the entire form object idenified 
var formObj = document.getElementById("createForm");
// Node for createTask form identified by id "createTask"
var form = document.getElementById("createTask");
// Initially show is false (set to hidden)
var show = false;

if (formObj != null && form != null) {
    // Define the behavior for the show button
    showButtonNode.addEventListener("click", function() {
        if (!show) {
            // Hide the form object by moving it outside of visible range
            formObj.style.top = -formObj.style.height;
        }
        else {
            // Show by moving it down into visible range
            formObj.style.top = formObj.style.height;
        }
        // Set show variable to other state
        show = !show;
    });
    // Add an event listener for when submit is activated and perform the POST request when it happens 
    form.addEventListener("submit", async function(event) {
        // Preventing default reload request/expectation
        event.preventDefault();
        // Get the form object in the document
        
        // Iterate through the form data, appending onto a string
        // i is index value, s_content to contain what is within the input fields and will be body of POST request
        var i, s_content;
        // Make sure to initialize s_content to empty string before adding anything
        s_content = "";
        for (i = 0; i < form.length-1; i++) {
            // Add this input field's content, using id to identify the variable being set
            s_content += form[i].id + "=" + form[i].value + "&";
            form[i].value = "";
        }
        // Will need to remove the last "&"
        s_content = s_content.substring(0, s_content.length-1);
    
        // Send the new task to the server as a POST request with submission value set to createTask so it is identifiable as this kind of request
        var myRequest = new XMLHttpRequest();
        myRequest.open("POST", "/", true);
        myRequest.setRequestHeader("Content-type", "text/plain");
        myRequest.send("submission=createTask&" + s_content);
    
        // Call loadContent() (assumed to be in another javascript file for the respective page this is attached to)
        loadContent();
    });
}
