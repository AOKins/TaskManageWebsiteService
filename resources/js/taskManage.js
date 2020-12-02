// Here is where for both main/home and agenda pages should have their task manage related loading functions placed

// Determine which page we are loading (home or agenda)
var fileName = location.pathname.substring(location.pathname.lastIndexOf("/")+1);

function appendTask(listStart, task) {
    var taskContainer = document.createElement("DIV");
    taskContainer.setAttribute("class", "task " + !task.checked);
    taskContainer.setAttribute("id", task.task_id);
    listStart.appendChild(taskContainer);
    
    var taskPart = document.createElement("BUTTON");
    taskPart.setAttribute("label", "check");
    taskPart.setAttribute("class", "check");
    taskPart.setAttribute("onclick", "buttonHandler(" + task.task_id + ")")
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
}



function outputTasks(content) {
    var jsonContent = JSON.parse(content);
    console.log(jsonContent);
    
    for (i_task in jsonContent.tasks) {
        appendTask(document.getElementById("main_list"), jsonContent.tasks[i_task]);
    }
    
}


// Script function called when the html page has loaded, handles loading the page content
async function loadContent()  {
    if (fileName == "home.html") {
        let data = await fetch(location.protocol + "//" + location.host + ":80" + '/test_data/today.json');
        if (!data.ok) {
            alert("Could not establish connection to server");
        }
        else {
            data.text().then((content) => outputTasks(content));
        }
    
    }
    return 1;
}





function buttonHandler(id) {
    var this_task = document.getElementById(id);
    if (this_task.classList.contains("true")) {
        this_task.setAttribute("class", "task false");
    }
    else {
        this_task.setAttribute("class", "task true");    
    }
}
