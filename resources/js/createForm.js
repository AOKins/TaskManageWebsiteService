var showButtonNode = document.getElementById("display");
var formNode = document.getElementById("createForm");
var show = false;

showButtonNode.addEventListener("click", function() {
    if (!show) {
        formNode.style.top = -formNode.style.height;
        show = true;
    }
    else {
        formNode.style.top = formNode.style.height;
        show = false;
    }
});