// Schema.org structured data for ISIA Urbino
(function() {
  const script = document.createElement('script');
  script.type = 'application/ld+json';
  script.text = JSON.stringify({
    "@context": "https://schema.org",
    "@type": "EducationalOrganization",
    "name": "ISIA Urbino",
    "alternateName": "Istituto Superiore per le Industrie Artistiche di Urbino",
    "url": "https://www.isiaurbino.net",
    "logo": "https://guidadocenti.isiaurbino.net/images/ISIAU_logo-light.png",
    "description": "Istituto Superiore per le Industrie Artistiche di Urbino - Alta formazione artistica e musicale in design, comunicazione visiva e multimedia",
    "address": {
      "@type": "PostalAddress",
      "streetAddress": "Via Santa Chiara, 36",
      "addressLocality": "Urbino",
      "postalCode": "61029",
      "addressRegion": "PU",
      "addressCountry": "IT"
    },
    "contactPoint": {
      "@type": "ContactPoint",
      "telephone": "+39-0722-320195",
      "contactType": "Segreteria Didattica",
      "email": "segreteria.didattica@isiaurbino.net",
      "availableLanguage": "Italian"
    },
    "sameAs": [
      "https://www.instagram.com/isiaurbino/",
      "https://www.facebook.com/isiaurbino"
    ]
  });
  document.head.appendChild(script);
})();