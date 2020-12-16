// Here is where the javascript code that handles rendering a calender for calendar.html is put

// The general layout (7 days and 6 weeks) is already in place in the html file
var monthName = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
var now = new Date(); // variable to hold what the current date is
var currentMonth = new Date(); // variable to hold what the displayed month is which may not be today's month

// variables to contain common Nodes for less repetitive declarations  
var monthTag = document.getElementById("month")
var yearTag = document.getElementById("year")
var datesObj = document.getElementById("calendarDates");

// Function to append list task items into a calendar date
// Input: node for where the current date item is
//        date for what the date is to access the correct tasks
function loadTasksForDate(node, date, jsonData) {
    var dateS = date.getFullYear() + "-" + (date.getMonth()+1) + "-" + (date.getDate());
    console.log("Finding tasks for " + dateS)
    var listItem;
    
    // Want to for a given date check the json's previous and next days along with this date's
    for (i = -1; i <= 1; i++) {    
        // Set what 
        var UTCDate = new Date();
        
        UTCDate.setDate(date.getDate() + i);

        var checkDate_S = UTCDate.getFullYear() + "-" + (UTCDate.getMonth()+1) + "-" + (UTCDate.getDate());
        
        for (task in jsonData[checkDate_S]) {
            var this_task = jsonData[checkDate_S][task];

            
            var year = this_task.date.toString().substring(0,4);
            var month = this_task.date.toString().substring(5,7);
            var day = this_task.date.toString().substring(8,10);
            var hour = this_task.time.toString().substring(0,2);
            var minute = this_task.time.toString().substring(3,5);

            // Construct a date object using the task's dateTime
            var UTCDate = new Date(Date.UTC(year, month-1,day, hour-(now.getTimezoneOffset() % 60) ,minute))

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


            console.log(this_task.title + " -> " + localDate + " vs. " + dateS)

            if (localDate == dateS) {
                listItem = document.createElement("LI");
                listItem.appendChild(document.createTextNode(this_task.title));
    
                if (this_task.checked == "true") {
                    listItem.style.display = "none"; // Hide in date object this task (but kept in for date selection the data isn't lost)
                }
    
                node.appendChild(listItem);
            }
        }    
    }
}

async function generateCalendar(month, year, content) {
    // Fetch the data and wait for response
        // First empty the Nodes of children if they are not empty
    jsonContent = JSON.parse(content);
    monthTag.innerHTML = '';
    yearTag.innerHTML = '';
    datesObj.innerHTML = '';

    // Append month and year info in appriopriate spots
    monthTag.appendChild(document.createTextNode(monthName[month]));
    yearTag.appendChild(document.createTextNode(year));

    // Create variable that is first date on the given month as starting reference point and using for iteration
    var date = new Date(year, month, 1, now.getHours(), now.getMinutes(), 0,0);

    // Offset backwards to start of week (for example, Monday would have 1 day before which is Sunday)
    date.setDate(date.getDate() - date.getDay());
    // First iterate through the spaces that would be the previous month, depends on day of the week that current month starts at

    for (; date.getMonth() != month; date.setDate(date.getDate()+1)) {
        var dNode = document.createElement("UL");
        dNode.setAttribute("class", "date past"); // Previous month dates are given the class called past
        var dList = document.createElement("LI");
        dList.setAttribute("id", "number");
        dList.appendChild(document.createTextNode(date.getDate()));
        dNode.appendChild(dList);

        datesObj.appendChild(dNode);

        // Append tasks for this date here
        loadTasksForDate(dList, date, jsonContent);
    }
    // Now iterate through each date through the month, CSS handles the individual weeks
    for (; date.getMonth() == month; date.setDate(date.getDate()+1)) {
        var dNode = document.createElement("UL");
        dNode.setAttribute("class", "date");
        if (date.toDateString() == now.toDateString()) {
            dNode.setAttribute("class", "date today")
        }
        var dList = document.createElement("LI");
        dList.setAttribute("id", "number");
        dList.appendChild(document.createTextNode(date.getDate()));
        dNode.appendChild(dList);
        datesObj.appendChild(dNode);
    
        // Append tasks for this date here
        loadTasksForDate(dList, date, jsonContent);
    }

    // Now iterate through the spaces that would be the next month for the rest of the week if this month ended before Saturday
    for (; date.getDay() > 0; date.setDate(date.getDate()+1)) {
        var dNode = document.createElement("UL");
        dNode.setAttribute("class", "date future"); // Next month dates are given the class called future
        var dList = document.createElement("LI");
        dList.setAttribute("id", "number");
        dList.appendChild(document.createTextNode(date.getDate()));
        dNode.appendChild(dList);
        datesObj.appendChild(dNode);

        // Append tasks for this date here
        loadTasksForDate(dList, date, jsonContent);
    }    
}


// Script function called when the html page has loaded, handles loading the page content
async function loadContent()  {
    var request = "submission=getTask&";
    // Set the start border to be the previous month's 22nd (22nd as a reasonable buffer back for what could possibly viewed in the calendar's previous dates)
    var start_S = currentMonth.getFullYear() +"-"+ (currentMonth.getMonth()) + "-22";
    // Set the end border to be the next month's 7thd (7th as a reasonable buffer forward for what could possibly viewed in the calendar's future dates)
    var NextMonthS = ((currentMonth.getMonth()+2) % 12).toString();
    var yearS = currentMonth.getFullYear();

    if (NextMonthS == "1") { // If the next month is january, will need to incrmeent the year value for the end (otherwise the end is actually the past!)
        yearS = currentMonth.getFullYear()+1;
    }
    var end_S =  yearS + "-" + NextMonthS + "-07";
    request += "startDate=" + start_S;
    request += "&endDate=" + end_S;
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
        data.text().then((content) => generateCalendar(currentMonth.getMonth(), currentMonth.getFullYear(), content));
    }
}

// Function called by navigation buttons that move forward or backward by one month
async function changeMonth(forward) {
    if (forward) {
        currentMonth.setMonth(currentMonth.getMonth() + 1);
    }
    else {
        currentMonth.setMonth(currentMonth.getMonth() - 1);
    }
    loadContent();
}
