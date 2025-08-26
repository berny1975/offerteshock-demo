// Offerteshock - nav-clean v1
(function(){
  function norm(s){ return (s||"").toString().trim().toLowerCase().replace(/\s+/g," "); }
  var matchers = [
    {key:"privacy",   re:/\bprivacy\b|^privac/i},
    {key:"termini",   re:/\btermini\b|\bterms?\b|\bcondizioni\b/i},
    {key:"contatti",  re:/\bcontatt/i}
  ];

  function killNavLinks(){
    var roots = Array.prototype.slice.call(document.querySelectorAll("nav, header, .navbar, .menu, .burger, [role='navigation']"));
    roots.forEach(function(root){
      var links = Array.prototype.slice.call(root.querySelectorAll("a, button"));
      links.forEach(function(el){
        var txt = norm(el.textContent);
        for (var i=0;i<matchers.length;i++){
          if (matchers[i].re.test(txt)){
            var victim = el.closest("li") || el;
            if (victim && victim.parentNode) victim.parentNode.removeChild(victim);
            break;
          }
        }
      });
    });
  }

  function killModals(){
    var dialogs = Array.prototype.slice.call(document.querySelectorAll(".modal, [role='dialog'], .dialog, .modal-dialog, .modal-container, .mdc-dialog, .uk-modal"));
    dialogs.forEach(function(d){
      var text = norm((d.textContent||"").slice(0,200));
      var hasMatch = false;
      for (var i=0;i<matchers.length;i++){
        if (matchers[i].re.test(text)){ hasMatch = true; break; }
      }
      if (!hasMatch){
        var head = d.querySelector("h1,h2,h3,h4,[aria-label]");
        if (head){
          var htxt = norm((head.getAttribute("aria-label")||head.textContent||"").slice(0,80));
          for (var j=0;j<matchers.length;j++){
            if (matchers[j].re.test(htxt)){ hasMatch = true; break; }
          }
        }
      }
      if (hasMatch && d.parentNode){
        d.parentNode.removeChild(d);
      }
    });

    var triggers = Array.prototype.slice.call(document.querySelectorAll("a[href^='#'],[data-target],[data-bs-target]"));
    triggers.forEach(function(t){
      var href = (t.getAttribute("href")||"") + " " + (t.getAttribute("data-target")||"") + " " + (t.getAttribute("data-bs-target")||"");
      href = href.toLowerCase();
      if (href.indexOf("privacy")>=0 || href.indexOf("termini")>=0 || href.indexOf("terms")>=0 || href.indexOf("condizioni")>=0 || href.indexOf("contatt")>=0){
        var vic = t.closest("li") || t;
        if (vic && vic.parentNode) vic.parentNode.removeChild(vic);
      }
    });
  }

  function run(){ killNavLinks(); killModals(); }
  if (document.readyState === "loading"){ document.addEventListener("DOMContentLoaded", run); } else { run(); }
})();
