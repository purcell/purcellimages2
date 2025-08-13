function nav_click(id) { document.getElementById(id)?.click(); }
function nav_up() { nav_click("nav-up"); }
function nav_next() { nav_click("nav-next"); }
function nav_prev() { nav_click("nav-prev"); }
document.addEventListener("keyup", function (event) {
  if (event.metaKey || event.altKey || event.ctrlKey) return;
  if (event.key == 'ArrowLeft') return nav_prev();
  if (event.key == 'ArrowRight') return nav_next();
  if (event.key == 'Escape') return nav_up();
});
var touches = {};
document.addEventListener("touchstart", function(event) {
  var touch = event.changedTouches[0];
  touches[event.changedTouches[0].identifier] = function(end_touch) {
    var dx = end_touch.screenX - touch.screenX;
    var dy = end_touch.screenY - touch.screenY;
    if ( Math.abs(dy) > Math.abs(dx) ) return;
    if ( dx < -40 ) return nav_next();
    if ( dx >  40 ) return nav_prev();
  };
});
document.addEventListener("touchend", function(event) {
  var touch = event.changedTouches[0];
  touches[touch.identifier](touch);
});
document.addEventListener("touchcancel", function(event) {
  touches.removeAttribute(event.target.changedTouches[0]);
});
