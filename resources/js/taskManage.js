// Here is where for both main/home and agenda pages should have their task manage related loading functions placed

// object that holds basic task info to add with some default empty/initial values to hold
var taskObject = {
    id : 0,
    checked: false,
    title: "",
    desc: "",
    due: "",
    shared: false
};

// Determine which page we are loading (home or agenda)
var fileName = location.pathname.substring(location.pathname.lastIndexOf("/")+1);

// Connect to database, making appriopriate queries using cookie as verification of access (and identifier of user)
    // For home, we only need to ask for tasks that have due dates that are today
    // For agenda, we need today, the next two days, and the rest of the week (thinking probably have those be seperate queries or have this script check through?)

// Iterate through the response data, creating/adding task elements into the document with the info in the correct spots



// Now to add interactivity, need click handling to identify elements being clicked on

    // Need to consider how to add/create/edit tasks
    // Filter option as well

document.addEventListener("click", clickHandler, false);

function clickHandler(event) {
    var item = event.target;
    // Iterate up the tree to determine if a check button was selected
    while (item) {
        if (item.nodeName == "BUTTON" && /check/.test(item.className)) {
            handleCheck(event);
            break;
        }
        item = item.parentNode;
    }
}


function handleCheck(button) {
    alert("A check button was clicked on and this function was called");
}