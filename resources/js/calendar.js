// Here is where the javascript code that handles rendering a calender for calendar.html is put

// The general layout (7 days and 6 weeks) is already in place in the html file
var monthName = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
var weekDates = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
var now = new Date(); // variable to hold what the current date is
var currentMonth = new Date(); // variable to hold what the displayed month is which may not be today's month

// variables to contain common Nodes for less repetitive declarations  
var monthTag = document.getElementById("month")
var yearTag = document.getElementById("year")
var datesObj = document.getElementsByClassName("calendarDates")[0];

function generateCalendar(month, year) {
    // First empty the Nodes of children if they are not empty
    monthTag.innerHTML = '';
    yearTag.innerHTML = '';
    datesObj.innerHTML = '';

    // Append month and year info in appriopriate spots
    monthTag.appendChild(document.createTextNode(monthName[month]));
    yearTag.appendChild(document.createTextNode(year));

    // Create variable that is first date on the given month as starting reference point and using for iteration
    var date = new Date(year, month, 1, 0,0,0,0);

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
    }    
}


// Script function called when the html page has loaded, handles loading the page content
async function loadContent()  {
    // Default loading is to current month and year
    generateCalendar(now.getMonth(), now.getFullYear());
}

// Function called by navigation buttons that move forward or backward by one month
function changeMonth(forward) {
    if (forward) {
        currentMonth.setMonth(currentMonth.getMonth() + 1);
    }
    else {
        currentMonth.setMonth(currentMonth.getMonth() - 1);
    }
    generateCalendar(currentMonth.getMonth(), currentMonth.getFullYear());
}