// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


function handleResponse(documentObject,stringToEvaluate) {
window.eval(stringToEvaluate);
if (documentObject.location){ // Should be usefull for IE only .. but I cannot test it
if(documentObject.location != "") documentObject.location.replace('about:blank');
}
}

