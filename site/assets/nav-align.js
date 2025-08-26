// Offerteshock - nav-align v2
(function(){
  function norm(s){ return (s||"").toString().trim().toLowerCase().replace(/\s+/g," "); }
  const rules = [
    { re: /\bprivacy\b|^privac/i, href: "./privacy.html", label: "Privacy" },
    { re: /\btermini\b|\bterm\b|\bcondizioni\b|\bterms?\b/i, href: "./termini.html", label: "Termini" },
    { re: /\bcontatt/i, href: "./contatti.html", label: "Contatti" }
  ];
  function alignLinks(root){
    const as = (root || document).querySelectorAll("a");
    as.forEach(a => {
      const t = norm(a.textContent);
      for (const r of rules){
        if (r.re.test(t)){
          a.setAttribute("href", r.href);
          if (!new RegExp("^" + r.label.toLowerCase()).test(t)) a.textContent = r.label;
          a.setAttribute("data-nav-aligned","1");
          break;
        }
      }
    });
  }
  if (document.readyState === "loading"){
    document.addEventListener("DOMContentLoaded", () => alignLinks(document));
  } else {
    alignLinks(document);
  }
})();
