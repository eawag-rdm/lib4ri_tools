// get the js object from the handed over flask parameter
//
// @param string param
//   the jsonised flask parameter
//
// @return object
//   the javascript object
function get_object_from_flaskparam(param) {
  if (param == '') {
    return param;
  }
  const htmlDecode = innerHTML => Object.assign(document.createElement('textarea'), {innerHTML}).value
  decoded_param = htmlDecode(param).replace(/False/g, 'false').replace(/True/g, 'true').replace(/None/g, '""');
  return JSON.parse(decoded_param);
};

// render the main page
function lib4riPage() {
  // title
  var title = document.createElement("h2");
  title.style.color = "blue";
  title.innerHTML = "Process a Scopus alert";
  document.body.appendChild(title);
  
  // Instructions
  var info = document.createElement("div");
  info.innerHTML = "Please select an institute...";
  document.body.appendChild(info);
  
  // attach the upload selector
  var form1 = document.createElement("form");
  form1.setAttribute("enctype", "multipart/form-data");
  form1.setAttribute("action", "/upload");
  form1.setAttribute("method", "post");
  document.body.appendChild(form1);

  // select institute
  var selected_inst = document.createElement("input");
  selected_inst.setAttribute("type", "hidden");
  selected_inst.setAttribute("name", "institute");
  if (typeof(institute) == 'string' && institutes.indexOf(institute) >= 0) {
    selected_inst.setAttribute("value", institute);
  }
  else {
    institute = "";
  }
  form1.appendChild(selected_inst);
  var instselect = document.createElement("select");
  var instselectoptions = [];
  var tmpopt = document.createElement("option");
  tmpopt.setAttribute("value", "");
  tmpopt.setAttribute("selected", true);
  tmpopt.setAttribute("disabled", true);
  tmpopt.innerHTML = "";
  instselectoptions.push(tmpopt);
  institutes.forEach(function(inst){
    var tmpopt = document.createElement("option");
    tmpopt.innerHTML = inst;
    instselectoptions.push(tmpopt);
  });
  instselectoptions.forEach(function(option){
    instselect.appendChild(option);
  });
  instselect.onchange = function(){
    var inst = instselect.value;
    institute = inst;
    selected_inst.setAttribute("value", inst);
    form1.removeChild(instselect);
    for (var i=0; i<ans.children.length; i++) { // clear error messages
      ans.children[0].remove();
    }
    make_upload_form();
  };
  instselect.appendChild(document.createElement("br"));
  if (institute == "") {
    form1.appendChild(instselect);
  }
  else {
    make_upload_form();
  }

  // renders the upload form for the files necessary for the selected institute
  function make_upload_form(){
    var inst = selected_inst.value;
    info.innerHTML = "Please upload or replace the following files for <b>" + inst + "</b>:<br/>";
    var outdated = document.createElement("div");
    outdated.style.display = 'none';
    outdated.style.color = 'red';
    outdated.innerHTML = "<sup>*</sup>) File older than a month; consider updating it...";
    var fileinputs = [];
    $create_file_upload_line = function (file){
      var tmpdiv = document.createElement("div");
      var tmpinnerdiv = document.createElement("div");
      tmpinnerdiv.style.display = 'table-cell';
      tmpinnerdiv.style.width = '12em';
      tmpinnerdiv.innerHTML = file['name'] + ": ";
      tmpdiv.appendChild(tmpinnerdiv);
      tmpinnerdiv = document.createElement("div");
      tmpinnerdiv.style.display = 'table-cell';
      tmpinnerdiv.style.width = '15em';
      var tmpinput = document.createElement("input");
      tmpinput.setAttribute("type", "file");
      tmpinput.setAttribute("name", file['name']);
      tmpinput.onchange = function (){
        var submit = (this.value != "")
        if (submit && this.value != this.name) { // alert if different file name
          submit = confirm("Are you sure you selected the correct file?\n(I expected '" + this.name + "', but you want to upload '" + this.value + "')")
        }
        if (submit) {
          form1.setAttribute("action", "/upload");
          form1.submit();
        }
      };
      tmpinnerdiv.appendChild(tmpinput);
      tmpdiv.appendChild(tmpinnerdiv);
      tmpinnerdiv = document.createElement("div");
      tmpinnerdiv.style.display = 'table-cell';
      tmpinnerdiv.style.width = '25em';
      var tmpdate = file['date'];
      if (tmpdate != false) {
        tmpdate = new Date(tmpdate);
        tmpinnerdiv.innerHTML = "(last updated: " + tmpdate.toLocaleString() + ")";
        if (Date.now() - tmpdate > 1000*3600*24*30.4375) { // alert if file older than a month
          tmpinnerdiv.innerHTML += "<sup>*</sup>";
          tmpinnerdiv.style.color = 'red';
          outdated.style.display = 'block';
        }
      }
      tmpdiv.appendChild(tmpinnerdiv);
      return tmpdiv;
    };

    processable = true;
    for (var key in files[inst]) {
      fileinputs.push($create_file_upload_line(files[inst][key]));
      processable = processable && !!files[inst][key]['date'];
    }
    for (var key in files['*']) {
      fileinputs.push($create_file_upload_line(files['*'][key]));
      processable = processable && !!files['*'][key]['date'];
    }
    for (var key in files['.']) {
      fileinputs.push($create_file_upload_line(files['.'][key]));
      processable = processable && !!files['.'][key]['date'];
    }
    fileinputs.forEach(function(input){
      form1.appendChild(input);
    });
    form1.appendChild(outdated);
    var process = document.createElement("button")
    process.innerHTML = "Process..."
    process.onclick = function() {
      form1.setAttribute("action", "/process");
      form1.submit();
    }
    if (processable) {
      form1.appendChild(process);
    }
  };

  //message section
  var ans = document.createElement("div");
  document.body.appendChild(ans);

  if (errormsgs != []) {
    errormsgs.forEach(function (msg){
      d = document.createElement("div");
      d.innerHTML = msg;
      ans.appendChild(d);
    });
  }
};

// renders the error page if another session is active
function lib4riTokenErrorPage() {
  // title
  var title = document.createElement("h2");
  title.style.color = "red";
  title.innerHTML = "Someone else seems to be using the app right now!";
  document.body.appendChild(title);
  
  // instructions
  var info = document.createElement("div");
  var expiresdate = false
  if (expires) {
    expiresdate = new Date(expires)
  }
  var showform = false;
  info.innerHTML = "Please try again later";
  if (expiresdate) {
    if (expiresdate && Date.now() - expiresdate > 0) {
      showform = true;
      info.innerHTML = "You can press the button below to reset the server (but the other user will not be able to continue their work!!!)."
    }
    else {
      info.innerHTML += " (if the other user stays idle until " + expiresdate.toLocaleString() + ", their session will expire).";
    }
  }
  else {
    info.innerHTML += ".";
  }
  document.body.appendChild(info);

  // attach the reset-form
  var form2 = document.createElement("form");
  form2.setAttribute("enctype", "multipart/form-data");
  form2.setAttribute("action", "/"); // do nothing by default
  form2.setAttribute("method", "post");
  if (showform) {
    document.body.appendChild(form2);
  }

  var otinput = document.createElement("input");
  otinput.setAttribute("type", "hidden");
  otinput.setAttribute("name", "oldtoken");
  otinput.setAttribute("value", oldtoken);
  form2.appendChild(otinput);

  var ntinput = document.createElement("input");
  ntinput.setAttribute("type", "hidden");
  ntinput.setAttribute("name", "newtoken");
  ntinput.setAttribute("value", newtoken);
  form2.appendChild(ntinput);

  var button = document.createElement("button");
  button.innerHTML = "Reset server";
  button.onclick = function() {
    if (confirm("Are you sure you want to disable the other user?")) {
      form2.setAttribute("action", "/reset");
      form2.submit();
    }
  };
  form2.appendChild(button);

  //message section
  var ans = document.createElement("div");
  document.body.appendChild(document.createElement("br"));
  document.body.appendChild(ans);

  if (errormsgs != []) {
    errormsgs.forEach(function (msg){
      d = document.createElement("div");
      d.innerHTML = msg;
      ans.appendChild(d);
    });
  }
};

// renders the page that returns the processed data
function lib4riProcessPage() {
  var start_over_innerHTML = "You can start over by pressing <a href='" + nexturl + "'>here</a> (Do not use the back or reload buttons!).";

  // title
  var title = document.createElement("h2");
  var notstr = "";
  if (!success) {
    title.style.color = "red";
    notstr = "not "
  }
  title.innerHTML = "Processing the files was " + notstr + "successful!";
  document.body.appendChild(title);

  // info + instructions
  var info = document.createElement("div");
  var info_head = document.createElement("div");
  info_head.innerHTML = "Below you find the output of the scripts.";
  if (!success) {
    info_head.innerHTML = " Maybe you can see what went wrong.";
  }
  info.appendChild(info_head)
  function px2num(val) {
    if (val.endsWith("px")) {
      return val.substr(0, val.length-2);
    }
    return val;
  }
  function mkoutputtextarea(output) {
    result = document.createElement("textarea");
    result.setAttribute("cols", 100);
    result.setAttribute("style", "white-space : pre; overflow : scroll; min-height: 50px; max-height: 400px;");
    result.value = output;
    result.adjustheight = function () {
      var targetheight = this.scrollHeight + 10;
      targetheight = Math.min(px2num(this.style.maxHeight), targetheight)
      targetheight = Math.max(px2num(this.style.minHeight), targetheight)
      this.style.height = targetheight + 'px';
    }
    return result;
  };
  var info_stdout = document.createElement("div");
  info_stdout.innerHTML = "stdout:";
  info.appendChild(info_stdout);
  var info_stdout_ta = mkoutputtextarea(stdout);
  info.appendChild(info_stdout_ta);
  var info_stderr = document.createElement("div");
  info_stderr.innerHTML = "stderr:";
  info.appendChild(info_stderr);
  var info_stderr_ta = mkoutputtextarea(stderr);
  info.appendChild(info_stderr_ta);
  var info_foot = document.createElement("div");
  if (success) {
    info_foot.innerHTML = "You can press the button below to retrieve the resulting file.";
  }
  else {
    info_foot.innerHTML = start_over_innerHTML;
  }
  info.appendChild(info_foot);

  document.body.appendChild(info);
  info_stdout_ta.adjustheight();
  info_stderr_ta.adjustheight();

  // attach the retrieve-form
  var form3 = document.createElement("form");
  form3.setAttribute("enctype", "multipart/form-data");
  form3.setAttribute("action", "/"); // do nothing by default
  form3.setAttribute("method", "post");

  var filenameinput = document.createElement("input");
  filenameinput.setAttribute("type", "text");
  filenameinput.setAttribute("name", "filename");
  filenameinput.setAttribute("value", filename);
  form3.appendChild(filenameinput);

  var button = document.createElement("button");
  button.innerHTML = "Retrieve file";
  button.onclick = function() { // we make this button inoperational upon first click
    button.innerHTML = "Redirecting...";
    button.onclick = function() {
      window.location = nexturl;
      return false;
    };
    window.setTimeout(function(){
			window.location = nexturl;
		      }, 3000);
    form3.setAttribute("action", "/retrieve");
    form3.submit();
  };
  form3.appendChild(button);

  if (success) {
    document.body.appendChild(form3);
  }

  //final comments
  if (success) {
    var comment = document.createElement("div")
    comment.innerHTML = start_over_innerHTML;
    document.body.appendChild(comment);
  }

  //message section
  var ans = document.createElement("div");
  document.body.appendChild(document.createElement("br"));
  document.body.appendChild(ans);

  if (errormsgs != []) {
    errormsgs.forEach(function (msg){
      d = document.createElement("div");
      d.innerHTML = msg;
      ans.appendChild(d);
    });
  }
};
