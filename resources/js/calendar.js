// Here is where the javascript code that handles rendering a calender for calendar.html is put

// The general layout (7 days and 6 weeks) is already in place in the html file
var monthName = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
var weekDates = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

function generateCalendar(month, year) {

    // Append month and year info in appriopriate spots
    document.getElementById("month").appendChild(document.createTextNode(monthName[month]));
    document.getElementById("year").appendChild(document.createTextNode(year));

    var datesList = document.getElementsByClassName("calendarDates")[0];
    // Create first date on the given month as starting point
    var date = new Date(year, month, 1, 0,0,0,0);
    date.setDate(date.getDay() - date.getDay() -1);
    var i;
    // First iterate through the spaces that would be the previous month, depends on day of the week that current month starts at
    for (; date.getMonth() != month; date.setDate(date.getDate()+1)) {
        var dNode = document.createElement("UL");
        dNode.setAttribute("class", "date past");
        var dList = document.createElement("LI");
        dList.setAttribute("id", "number");
        dList.appendChild(document.createTextNode(date.getDate()));
        dNode.appendChild(dList);
        datesList.appendChild(dNode);
    }    
    // Now iterate through each date through the month

    for (;date.getMonth() == month; date.setDate(date.getDate()+1)) {
        var dNode = document.createElement("UL");
        dNode.setAttribute("class", "date");
        var dList = document.createElement("LI");
        dList.setAttribute("id", "number");
        dList.appendChild(document.createTextNode(date.getDate()));
        dNode.appendChild(dList);
        datesList.appendChild(dNode);
    
    }
    // Now iterate through the spaces that would be the next month
    // First iterate through the spaces that would be the previous month, depends on day of the week that current month starts at
    
    for (; date.getDay() > 0; date.setDate(date.getDate()+1)) {
        var dNode = document.createElement("UL");
        dNode.setAttribute("class", "date");
        var dList = document.createElement("LI");
        dList.setAttribute("id", "number");
        dList.appendChild(document.createTextNode(date.getDate()));
        dNode.appendChild(dList);
        datesList.appendChild(dNode);
    }    
}


// Script function called when the html page has loaded, handles loading the page content
async function loadContent()  {
    var today = new Date();
    // Default loading is to current month and year
    generateCalendar(today.getMonth(), today.getFullYear());
}
