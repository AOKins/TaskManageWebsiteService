// File for both home and agenda pages to load content

// Variable to hold today's date info as reference
var today = new Date();
// Variable to hold today as a formatted string to use with jsonContent 
var today_UTC_S = today.getUTCFullYear() + "-" + (today.getUTCMonth()+1) + "-" + (today.getUTCDate());

// Function to append task to a list
// Input: listStart - node to start of the list
//        task - json of the task object needing to be added
// Output: listStart is appended a child that is a list item containing task info and button
function appendTask(listStart, task) {
    // Variable to hold date object of the task
    var taskDate = new Date(task.dateTime);
    var localDate = (taskDate.getMonth()+1).toString() + "-" + taskDate.getDate()
    var localTime =  (taskDate.getHours()).toString() + ":";
    // Append a 0 to the front if the minutes is less than 10 (one digit), otherwise it's just getMinutes()
    if ( taskDate.getMinutes() < 10) {
        localTime += "0" + taskDate.getMinutes().toString();
    }
    else {
        localTime += taskDate.getMinutes().toString();
    }

    // Create element that is to contain the task
    var taskContainer = document.createElement("LI");
    
    taskContainer.setAttribute("class", "task " + task.checked);

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
    // If task's due date is not same as today's, should display what the date is (since the time is relative to the day it's due)
    if (localDate != (today.getMonth()+1) + "-" + (today.getDate()).toString()) {
        taskPart.appendChild(document.createTextNode(localDate + " " + localTime));
    }
    else {
        taskPart.appendChild(document.createTextNode(localTime));
    }
    taskContainer.appendChild(taskPart);

    taskPart = document.createElement("DIV");
    taskPart.setAttribute("id", "description");
    taskPart.appendChild(document.createTextNode(task.desc));
    taskContainer.appendChild(taskPart);

    // To be added taskContainer.style.color = task.color;

    // Appending the task to the list
    listStart.appendChild(taskContainer);
    // Resulting task object is now appended to the list with info
}

// Function to add task content as a JSON file into the main_list 
// Calls appendTask function for each task
function outputTasks(content) {
    jsonContent = JSON.parse(content);
    
    // date variable to handle non-today date info neeeded to be stored/accessed as string
    var date;
    // object for list of nodes that are of class "Tasklist"
    var listOfLists = document.getElementsByClassName("Tasklist");
    var numLists = listOfLists.length;
    // Index number for accessing a list in the list of lists
    var list;

    for (list = 0; list < numLists; list++) {
        // Initialize the list to be empty before appending anything
        listOfLists[list].innerHTML="";
        
        // If the list is for tasks related to today
        if (listOfLists[list].id == "today" && jsonContent[today_UTC_S] != null) {

            for (task in jsonContent[today_UTC_S]) {
                appendTask(listOfLists[list], jsonContent[today_UTC_S][task]);
            }
        }

        else if (listOfLists[list].id == "next2days") {
            // Using for loop to iterate tomorrow (i = 1) and the next day (i = 2)
            var i;
            for (i = 1; i < 3; i++) {
                date = today.getUTCFullYear() + "-" + (today.getUTCMonth()+1) + "-" + (today.getUTCDate()+i);
                if (jsonContent[date] != null) {
                    for (task in jsonContent[date]) {
                        appendTask(listOfLists[list], jsonContent[date][task]);
                    }        
                }
            }
        }
        // For week, does tasks for dates of rest of the week (next 4 days after the next 2)
        else if (listOfLists[list].id == "week") {
            var i;
            for (i = 3; i < 7; i++) {
                date = today.getUTCFullYear() + "-" + (today.getUTCMonth()+1) + "-" + (today.getUTCDate()+i);
                if (jsonContent[date] != null) {
                    for (task in jsonContent[date]) {
                        appendTask(listOfLists[list], jsonContent[date][task]);
                    }
                }
            }
        }
    }
}

// Script function called when the html body has loaded, handles loading the page's tasks
async function loadContent()  {
    var request = "submission=getTask&";
    // Define the next week date in UTC timezone for end date (is ahead by 7 days)
    var nextWeek_UTC_S = today.getUTCFullYear() + "-" + (today.getUTCMonth()+1) + "-" + (today.getUTCDate()+7);
    request += "startDate=" + today_UTC_S;
    request += "&endDate=" + nextWeek_UTC_S;

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
        data.text().then((content) => outputTasks(content));
    }
}

// Function to handle the event of a task's button being called, argument is the task's id value
function taskButtonHandler(id) {
    // Get Node for task with id to identify its status
    var this_task = document.getElementById(id);
    var task_checked = !this_task.classList.contains("true");
    // Update locally the task's status by updating its attribute
    this_task.setAttribute("class", "task");
    if (task_checked) {
        this_task.classList.add("true");
    }
    else {
        this_task.classList.add("false");
    }

    // Update the database's task data using a POST request
    var myRequest = new XMLHttpRequest();
    myRequest.open("POST", "/", true);
    myRequest.setRequestHeader("Content-type", "text/plain");
    myRequest.send("submission=updateTask&task_id=" + id + "&completion=" + task_checked);
    // Assuming no need for response (change done locally prior)
}
