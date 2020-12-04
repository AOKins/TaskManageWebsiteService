// File for both home and agenda pages to load content

// Function called when the user has submitted to create a task through the form that has id "createTask"
var formObj = document.getElementById("createTask");
if (formObj != null) {
    formObj.addEventListener("submit", async function(event) {
        // Preventing default reload
        event.preventDefault();
        // Get the form object in the document
        
        // Iterate through the form data, appending onto a string
        var i, s_content;
    
        s_content = "";
        for (i = 0; i < formObj.length-2; i++) {
            s_content += formObj[i].id + "=" + formObj[i].value + "&";
            formObj[i].value = "";
        }
        s_content += formObj[formObj.length-2].id + "=" + formObj[formObj.length-2].value;
        // Submit data
        alert(s_content);
    
        // Send the new task to the server as a POST request
        var myRequest = new XMLHttpRequest();
        myRequest.open("POST", "home.html", true);
        myRequest.setRequestHeader("Content-type", "text/plain");
        myRequest.send("submission=createTask&" + s_content);
    
        loadContent();
    });
    
}

// Input: listStart - node to start of the list
//        task - json of the task object needing to be added
function appendTask(listStart, task) {
    
    // Created element that is to contain the task
    var taskContainer = document.createElement("LI");
    taskContainer.setAttribute("class", "task " + !task.checked);

    // Id is equal to the id of the task in the database
    taskContainer.setAttribute("id", task.task_id);

    // Appending the task to the list
    listStart.appendChild(taskContainer);

    // Appending button, title, description, and time to the task container 
    var taskPart = document.createElement("BUTTON");
    taskPart.setAttribute("label", "check");
    taskPart.setAttribute("class", "check");
    taskPart.setAttribute("onclick", "taskButtonHandler(" + task.task_id + ")")
    taskContainer.appendChild(taskPart);

    taskPart = document.createElement("DIV");
    taskPart.setAttribute("id", "title");
    taskPart.appendChild(document.createTextNode(task.title));
    taskContainer.appendChild(taskPart);    

    taskPart = document.createElement("DIV");
    taskPart.setAttribute("id", "time");
    taskPart.appendChild(document.createTextNode(task.due));
    taskContainer.appendChild(taskPart);

    taskPart = document.createElement("DIV");
    taskPart.setAttribute("id", "description");
    taskPart.appendChild(document.createTextNode(task.desc));
    taskContainer.appendChild(taskPart);
    // Resulting task object is now on top of the task list
}

// Function to add task content as a JSON file into the main_list 
// Calls appendTask function for each task
function outputTasks(jsonContent) {
    // Get list element and empty if contains content
    // object for list of nodes that are of class "Tasklist"
    // Reference for seeing iterating over elements by class name
    //https://stackoverflow.com/questions/3871547/js-iterating-over-result-of-getelementsbyclassname-using-array-foreach
    var listOfLists = document.getElementsByClassName("Tasklist");
    Array.prototype.forEach.call(listOfLists, function(list, i_list) {
        list.innerHTML = "";
        for (i_task in jsonContent.taskLists[i_list].tasks) {
            // Need to add what if it's empty/undefined/null
            
            appendTask(list, jsonContent.taskLists[i_list].tasks[i_task]);
        }
            
    });
    
}

// Script function called when the html body has loaded, handles loading the page's tasks
async function loadContent()  {
    // Fetch the data and wait for response
    let data = await fetch(location.protocol + "//" + location.host + ":80" + '/test_data/today.json');
    if (!data.ok) {
        alert("Could not establish connection to server");
    }
    // If received teh data okay, call outputTasks with JSON parsing of the content
    else {
        data.text().then((content) => outputTasks(JSON.parse(content)));
    }
    
    return 1;
}


// Function to handle the event of a task's button being called, argument is the task's id value 
function taskButtonHandler(id) {
    // Get Node for task with id
    var this_task = document.getElementById(id);
    var task_checked = this_task.classList.contains("true");
    // Update locally the task's status
    if (task_checked) {
        this_task.setAttribute("class", "task false");
    }
    else {
        this_task.setAttribute("class", "task true");    
    }
    // Update the database's task data using a POST request
    var myRequest = new XMLHttpRequest();
    myRequest.open("POST", "home.html", true);
    myRequest.setRequestHeader("Content-type", "text/plain");
    myRequest.send("submission=updateTask&task_id=" + id + "&checked=" + task_checked);
}
