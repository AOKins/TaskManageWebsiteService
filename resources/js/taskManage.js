// File for both home and agenda pages to load content

// Variable to hold today's date info as reference
var today = new Date();
// Variable to hold today as a formatted string to use with jsonContent 
var today_S = today.getFullYear() + "-" + (today.getMonth()+1) + "-" + (today.getDate())

// Function to append task to a list
// Input: listStart - node to start of the list
//        task - json of the task object needing to be added
// Output: listStart is appended a child that is a list item containing task info and button
function appendTask(listStart, task) {
    // Create element that is to contain the task
    var taskContainer = document.createElement("LI");
    taskContainer.setAttribute("class", "task " + !task.checked);

    // Id is equal to the id of the task in the database
    taskContainer.setAttribute("id", task.task_id);

    // Appending button task container which requires task id value to identify the task 
    var taskPart = document.createElement("BUTTON");
    taskPart.setAttribute("label", "check");
    taskPart.setAttribute("class", "check");
    taskPart.setAttribute("onclick", "taskButtonHandler(" + task.task_id + ")")
    taskContainer.appendChild(taskPart);
    // Appending title to task object
    taskPart = document.createElement("DIV");
    taskPart.setAttribute("id", "title");
    taskPart.appendChild(document.createTextNode(task.title));
    taskContainer.appendChild(taskPart);    

    // Set the due time
    taskPart = document.createElement("DIV");
    taskPart.setAttribute("id", "time");
    // If task's due date is not same as today, should display what the date is (since the time is relative to the day it's due)
    if (task.date != today_S) {
        taskPart.appendChild(document.createTextNode(task.date.substring(5,task.date.length) + " " + task.due));
    }
    else {
        taskPart.appendChild(document.createTextNode(task.due));
    }
    taskContainer.appendChild(taskPart);

    taskPart = document.createElement("DIV");
    taskPart.setAttribute("id", "description");
    taskPart.appendChild(document.createTextNode(task.desc));
    taskContainer.appendChild(taskPart);
    // Appending the task to the list
    listStart.appendChild(taskContainer);
    // Resulting task object is now appended to the list with info
}

// Function to add task content as a JSON file into the main_list 
// Calls appendTask function for each task
function outputTasks(jsonContent) {
    // date variable to handle non-today date info neeeded to be stored/accessed as string
    var date;
    // object for list of nodes that are of class "Tasklist"
    var listOfLists = document.getElementsByClassName("Tasklist");
    var numLists = listOfLists.length;
    // Index number for accessing a list in the list of lists
    var list;
    for (list = 0; list < numLists; list++) {
        // If the list is for tasks related to today
        if (listOfLists[list].id == "today") {
            // Use today's date (today_S) as the key
            if (jsonContent[today_S] != null) {
                for (task in jsonContent[today_S]) {
                    appendTask(listOfLists[list], jsonContent[today_S][task]);
                }    
            }
        }
        else if (listOfLists[list].id == "next2days") {
            // Using for loop to iterate tomorrow (i = 1) and the next day (i = 2)
            var i;
            for (i = 1; i < 3; i++) {
                date = today.getFullYear() + "-" + (today.getMonth()+1) + "-" + (today.getDate()+i);
                for (task in jsonContent[date]) {
                    appendTask(listOfLists[list], jsonContent[date][task]);
                }    
            }
        }
        // For week, does tasks for dates of rest of the week (next 4 days after the next 2)
        else if (listOfLists[list].id == "week") {
            var i;
            for (i = 3; i < 7; i++) {
                date = today.getFullYear() + "-" + (today.getMonth()+1) + "-" + (today.getDate()+i);
                for (task in jsonContent[date]) {
                    appendTask(listOfLists[list], jsonContent[date][task]);
                }
            }
        }
    }
}

// Script function called when the html body has loaded, handles loading the page's tasks
async function loadContent()  {
    // Fetch the data and wait for response
    let data = await fetch(location.protocol + "//" + location.host + ":80" + '/test_data/today.json');
    if (!data.ok) {
        alert("Could not establish connection to server");
    }
    // If received the data okay, call outputTasks with JSON parsing of the content
    else {
        data.text().then((content) => outputTasks(JSON.parse(content)));
    }
}

// Get the Node for createTask form identified by id "createTask"
var formObj = document.getElementById("createTask");
if (formObj != null) {
    // Add an event listener for when submit is activated and perform the POST request when it happens 
    formObj.addEventListener("submit", async function(event) {
        // Preventing default reload request/expectation
        event.preventDefault();
        // Get the form object in the document
        
        // Iterate through the form data, appending onto a string
        // i is index value, s_content to contain what is within the input fields and will be body of POST request
        var i, s_content;
        // Make sure to initialize s_content to empty string before adding anything
        s_content = "";
        for (i = 0; i < formObj.length-1; i++) {
            // Add this input field's content, using id to identify the variable being set
            s_content += formObj[i].id + "=" + formObj[i].value + "&";
            formObj[i].value = "";
        }
        // Will need to remove the last "&"
        s_content = s_content.substring(0, s_content.length-1);

        // Alert for debugging, must remove when satisified with this function
        alert(s_content);
    
        // Send the new task to the server as a POST request with submission value set to createTask so it is identifiable as this kind of request
        var myRequest = new XMLHttpRequest();
        myRequest.open("POST", "/", true);
        myRequest.setRequestHeader("Content-type", "text/plain");
        myRequest.send("submission=createTask&" + s_content);
    
        // Call loadContent() to update the task lists
        loadContent();
    });
    
}

// Function to handle the event of a task's button being called, argument is the task's id value
function taskButtonHandler(id) {
    // Get Node for task with id to identify its status
    var this_task = document.getElementById(id);
    var task_checked = this_task.classList.contains("true");
    // Update locally the task's status by updating its attribute
    if (task_checked) {
        this_task.setAttribute("class", "task false");
    }
    else {
        this_task.setAttribute("class", "task true");    
    }
    // Update the database's task data using a POST request
    var myRequest = new XMLHttpRequest();
    myRequest.open("POST", "/", true);
    myRequest.setRequestHeader("Content-type", "text/plain");
    myRequest.send("submission=updateTask&task_id=" + id + "&checked=" + task_checked);
    // Assuming no need for response
}
