// Javascript file to hold behavior related to the create Task form

// Node for show button that toggles the display of the form or not
var showButtonNode = document.getElementById("display");
// Node for the entire form object idenified 
var formObj = document.getElementById("createForm");
// Node for createTask form identified by id "createTask"
var form = document.getElementById("createTask");
// Initially show is false (set to hidden)
var categoryInput = document.getElementById("category");
// Node for the form input that allows the user to create new category for their new task
var categoryText = document.getElementById("categoryText");

var colorSelect = document.getElementById("color");

// True when the form should be visible the client
var show = false;

// Add event listener for the show button of the form to adjust the height when clicked
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

// Add an click listner for category input to dynamically show the category name text only when *New* option selected
if (categoryInput != null) {
    var previousValue = categoryInput.value;
    categoryInput.addEventListener("click", function(){
        if (categoryInput.value != previousValue) {
            if (categoryInput.value == "*New*") {
                categoryText.style.display ="inline";
                colorSelect.style.display ="inline";
            }
            else if (previousValue == "*New*")  {
                categoryText.style.display ="none";
                colorSelect.style.display ="none";
            }
        }
        previousValue = categoryInput.value;
    });
}

// Function for adding categories into categoryInput tag for create Task form
function appendingCategories(content) {
    var jsonContent = JSON.parse(content);
    
    var categoryOption;
    for (i in jsonContent.category_options) {
        categoryOption = document.createElement("OPTION");
        categoryOption.setAttribute("value", jsonContent.category_options[i].id); // The value is the category's associated ID
        categoryOption.innerHTML = jsonContent.category_options[i].name;
        categoryInput.appendChild(categoryOption);
    }
    categoryOption = document.createElement("OPTION");
    categoryOption.setAttribute("value", "*New*");
    categoryOption.innerHTML = "*New*";
    categoryInput.appendChild(categoryOption);

    for (i in jsonContent.color_options) {
        colorOption = document.createElement("OPTION");
        colorOption.setAttribute("value", jsonContent.color_options[i].option);
        colorOption.innerHTML = jsonContent.color_options[i].option;
        colorSelect.appendChild(colorOption);
    }


}

// A function called onload, gets categories from the server and appends to the form for drop-down selection
async function getCategories() {
    var request = "submission=getCategories";

    // Fetch the data and wait for response
    let data = await fetch(location.protocol + "//" + location.host, {
        method: 'POST',
        mode: 'cors',
        headers: {
            'Content-Type' : 'text/json'
        },
        body: request,
    });
    if (!data.ok) {
        alert("Could not establish connection to server");
    }
    // If received the data okay, call outputTasks with JSON parsing of the content
    else {
        data.text().then((content) => appendingCategories(content));
    }
}
