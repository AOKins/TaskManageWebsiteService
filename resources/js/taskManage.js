// File for both home and agenda pages to load content

// Variable to hold today's date info as reference
var today = new Date();
var tempDate = new Date();
// Function to append task to a list
// Input: listStart - node to start of the list
//        task - json of the task object needing to be added
//        dateAllowed - a local date to check against the task's local date to determine if the task should be added
// Output: listStart is appended a child that is a list item containing task info and button
function appendTask(listStart, task, dateAllowed) {
    // Variable to hold date object of the task

    var year = task.date.toString().substring(0,4);
    var month = task.date.toString().substring(5,7);
    var day = task.date.toString().substring(8,10);
    var hour = task.time.toString().substring(0,2);
    var minute = task.time.toString().substring(3,5);

    var UTCDate = new Date(Date.UTC(year, month-1,day, hour-(today.getTimezoneOffset() % 60) ,minute))

    // Convert the date for this task to local time equivalent
    var localDate = UTCDate.getFullYear() + "-";
    
    if (UTCDate.getMonth() < 10) {
        localDate += "0" + (UTCDate.getMonth()+1) + "-";        
    }
    else {
        localDate += (UTCDate.getMonth()+1) + "-";
    }
    if (UTCDate.getDate() < 10) {
        localDate += "0" + UTCDate.getDate() + '-';
    }
    else {
        localDate += UTCDate.getDate();
    }
    
    var localTime =  UTCDate.getHours() + ":" + UTCDate.getMinutes();
    if (UTCDate.getMinutes() < 10) {
        localTime += "0";
    }

    if (localDate == dateAllowed) {
        // Create element that is to contain the task
        var taskContainer = document.createElement("LI");

        taskContainer.setAttribute("class", "task");
        taskContainer.setAttribute("shared", task.shared);
        taskContainer.setAttribute("category", task.categoryName);
        taskContainer.setAttribute("completed", task.completed);

        // Store what the color of the task is in both an attribute for access and assign to style if not completed
        taskContainer.setAttribute("categoryColor", task.color);

        if (task.completed == "true") {
            taskContainer.style.backgroundColor = "grey";
        }
        else {
            taskContainer.style.backgroundColor = task.color;
        }

        // Id is equal to the id of the task in the database
        taskContainer.setAttribute("id", task.task_id);

        // If shared, append an element that states who the owner is
        if (task.shared == "true") {
            taskPart = document.createElement("DiV");
            taskPart.innerHTML = ("Shared by " + task.ownerName);
            taskPart.setAttribute("id", "shareTag");
            taskContainer.appendChild(taskPart);
        }

        // If not a shared task, append an option for deleting the task 
        else if (task.shared != "true") {
            taskPart = document.createElement("BUTTON");
            taskPart.setAttribute("label", "delete");
            taskPart.setAttribute("class", "delete");
            taskPart.setAttribute("onclick", "deleteTaskHandler(" + task.task_id + ")")
            taskContainer.appendChild(taskPart);    
        }

        // Appending button task container which requires task id value to identify the task 
        var taskPart = document.createElement("BUTTON");
        taskPart.setAttribute("label", "check");
        taskPart.setAttribute("class", "check");
        taskPart.setAttribute("onclick", "taskCompletionHandler(" + task.task_id + ")")
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
        if (localDate != today.getFullYear() + "-" + (today.getMonth()+1) + "-" + (today.getDate()).toString()) {
            taskPart.appendChild(document.createTextNode(localDate + "\t"));
        }
        
        taskPart.appendChild(document.createTextNode(localTime));
        
        taskContainer.appendChild(taskPart);


        taskContainer.appendChild(document.createElement("br"));

        taskPart = document.createElement("DIV");
        taskPart.setAttribute("id", "description");
        taskPart.appendChild(document.createTextNode(task.desc));
        taskContainer.appendChild(taskPart);


        // Appending the task to the list
        listStart.appendChild(taskContainer);
        // Resulting task object is now appended to the list with info

    }
}

// Function to add task content as a JSON file into the main_list 
// Calls appendTask function for each task
function outputTasks(content) {
    jsonContent = JSON.parse(content);
    
    // date variable to handle non-today date info neeeded to be stored/accessed as string
    // object for list of nodes that are of class "Tasklist" in the html file
    // Get number of lists to consider (home for example may have only 1)
    var listOfLists = document.getElementsByClassName("Tasklist");
    var numLists = listOfLists.length;
    // Index number for accessing a list in the list of lists
    var list;

    tempDate = new Date();
    var tempDate_S;
    var dateAllowed;
    for (list = 0; list < numLists; list++) {
        // Initialize the list to be empty before appending anything
        listOfLists[list].innerHTML = "";
        var offset;

        // If the list is for tasks related to today
        if (listOfLists[list].id == "today") {
            offset = 0;
            // Set the local date string allowed to be just today
            dateAllowed = today.getUTCFullYear() + "-" + (today.getMonth()+1) + "-" + (today.getDate());
            
            // Get 3 date range with today being today's UTC date
            for (i = -1; i <= 1; i++) {
                // Set the temp date holder to be today's date minus one
                tempDate.setUTCDate(today.getUTCDate()+i+offset);
                tempDate_S = tempDate.getUTCFullYear() + "-" + (tempDate.getMonth()+1) + "-" + (tempDate.getDate());
                if (jsonContent[tempDate_S] != null) {
                    for (task in jsonContent[tempDate_S]) {
                        appendTask(listOfLists[list], jsonContent[tempDate_S][task], dateAllowed);
                    }
                }
            }
        }
        else if (listOfLists[list].id == "next2days") { 
                for (offset = 1; offset < 3; offset++) {
                    // Set the local date string allowed to be just today
                    tempDate.setUTCDate(today.getUTCDate()+offset);
                    dateAllowed = tempDate.getUTCFullYear() + "-" + (tempDate.getMonth()+1) + "-" + (tempDate.getDate());
                    
                    // Get 3 date range with today being today's UTC date
                    for (i = -1; i <= 1; i++) {
                        // Set the temp date holder to be offset for number of days away from today's
                        tempDate.setUTCDate(today.getUTCDate()+i+offset);
                        tempDate_S = tempDate.getUTCFullYear() + "-" + (tempDate.getMonth()+1) + "-" + (tempDate.getDate());
                        if (jsonContent[tempDate_S] != null) {
                            for (task in jsonContent[tempDate_S]) {
                                appendTask(listOfLists[list], jsonContent[tempDate_S][task], dateAllowed);
                            }
                        }
                    }
                }
        }
        else if (listOfLists[list].id == "week") { 
            for (offset = 3; offset < 8; offset++) {
                // Set the local date string allowed to be just today
                tempDate.setUTCDate(today.getUTCDate()+offset);
                dateAllowed = tempDate.getUTCFullYear() + "-" + (tempDate.getMonth()+1) + "-" + (tempDate.getDate());
                
                // Get 3 date range with today being today's UTC date
                for (i = -1; i <= 1; i++) {
                    // Set the temp date holder to be offset for number of days away from today's
                    tempDate.setUTCDate(today.getUTCDate()+i+offset);
                    tempDate_S = tempDate.getUTCFullYear() + "-" + (tempDate.getMonth()+1) + "-" + (tempDate.getDate());
                    if (jsonContent[tempDate_S] != null) {
                        for (task in jsonContent[tempDate_S]) {
                            appendTask(listOfLists[list], jsonContent[tempDate_S][task], dateAllowed);
                        }
                    }
                }
            }
    }
}
}

// Script function called when the html body has loaded, handles loading the page's tasks
async function loadContent()  {
    var request = "submission=getTask&";

    // Object for next week's date
    var nextWeek = new Date();
    nextWeek.setDate(today.getUTCDate()+8);

    // Variable to hold today as a formatted string to use with query 
    // adding one to month because value ranges from 0 to 11 instead of 1 to 12
    // Subtracting one day to ensure capture of all tasks
    var today_UTC_S = today.getUTCFullYear() + "-" + (today.getUTCMonth()+1) + "-" + (today.getUTCDate()-1);
    
    // Define the next week date string using nextWeek date object
    var nextWeek_UTC_S = nextWeek.getUTCFullYear() + "-" + (nextWeek.getUTCMonth()+1) + "-" + (nextWeek.getUTCDate());

    // Add to request body
    request += "startDate=" + today_UTC_S;
    request += "&endDate=" + nextWeek_UTC_S;

    // Fetch the data and wait for response
    let data = await fetch(location.protocol + "//" + location.host, {
        method: 'POST',
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
function taskCompletionHandler(id) {
    // Get Node for task with id to identify its status
    var this_task = document.getElementById(id);
    var task_complete = this_task.getAttribute("completed");
    var task_color = this_task.getAttribute("categorycolor");

    // Update locally the task's status by updating its attribute
    if (task_complete == "false") {
        this_task.setAttribute("completed", "true");
        task_complete = "true";
        this_task.style.backgroundColor = "grey";
    }
    else {
        this_task.setAttribute("completed", "false");
        task_complete = "false";
        this_task.style.backgroundColor = task_color;
    }

    // Update the database's task data using a POST request
    var myRequest = new XMLHttpRequest();
    myRequest.open("POST", "/", true);
    myRequest.setRequestHeader("Content-type", "text/plain");
    myRequest.send("submission=updateTask&task_id=" + id + "&completion=" + task_complete);
    // Assuming no need for response (change done locally prior)
}

// Function to handle when the delete button for a task is clicked on
function deleteTaskHandler(id) {
    var this_task = document.getElementById(id);
    // Remove this task from the document
    this_task.parentNode.removeChild(this_task);

    // Update the database's task data using a POST request, not expecting a response
    var myRequest = new XMLHttpRequest();
    myRequest.open("POST", "/", true);
    myRequest.setRequestHeader("Content-type", "text/plain");
    myRequest.send("submission=deleteTask&task_id=" + id);
}
