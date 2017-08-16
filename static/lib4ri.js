function lib4riPage() {
  // title
  var title = document.createElement("h2");
  title.style.color = "blue";
  title.innerHTML = "A test application for our friends at the library";
  document.body.appendChild(title);
  
  // Instructions
  var info = document.createElement("div");
  info.innerHTML = "Select the file to be transformed:";
  document.body.appendChild(info);
  
  // attach the upload selector
  var form1 = document.createElement("form");
  form1.setAttribute("enctype", "multipart/form-data");
  form1.setAttribute("action", "/upload");
  form1.setAttribute("method", "post");
  document.body.appendChild(form1);

  // upload
  var fileinput = document.createElement("input");
  fileinput.setAttribute("type", "file");
  fileinput.setAttribute("name", "file");
  form1.appendChild(fileinput);
  fileinput.onchange = function (){
    fileinput.setAttribute("name", fileinput.value);
    form1.submit();
    ans.innerHTML = "PROCESSING ...";
  };
  
  //message section
  var ans = document.createElement("div");
  document.body.appendChild(ans); 
}
