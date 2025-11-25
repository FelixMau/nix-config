{
  config,
  lib,
  pkgs,
  ...
}:
let
  service = "landing-page";
  cfg = config.homelab.services.${service};
  homelab = config.homelab;

  # Logo file
  logoFile = ./logo.png;

  # Public landing page with logo
  landingPageSite = pkgs.runCommand "landing-page" {} ''
    mkdir -p $out

    # Copy logo
    cp ${logoFile} $out/logo.png

    # Create index.html
    cat > $out/index.html << 'EOF'
    <!DOCTYPE html>
    <html lang="de">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${cfg.name} - ${cfg.title}</title>
      <link rel="icon" type="image/png" href="/logo.png">
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
          background: #f5f7fa;
          min-height: 100vh;
          color: #333;
          line-height: 1.6;
        }
        .hero {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          padding: 4rem 2rem;
          text-align: center;
          color: white;
          position: relative;
        }
        .hero-content {
          max-width: 800px;
          margin: 0 auto;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 2rem;
          flex-wrap: wrap;
        }
        .logo {
          width: 120px;
          height: 120px;
          animation: float 3s ease-in-out infinite;
        }
        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-10px); }
        }
        .hero-text {
          flex: 1;
          min-width: 300px;
        }
        .hero h1 {
          font-size: 3rem;
          margin-bottom: 0.5rem;
          font-weight: 700;
        }
        .hero .title {
          font-size: 1.3rem;
          opacity: 0.9;
          margin-bottom: 1.5rem;
        }
        .hero .tagline {
          font-size: 1.1rem;
          opacity: 0.85;
          margin-bottom: 1.5rem;
        }
        .profile-links {
          display: flex;
          justify-content: center;
          gap: 1rem;
          flex-wrap: wrap;
        }
        .profile-links a {
          color: white;
          text-decoration: none;
          padding: 0.5rem 1rem;
          border: 2px solid rgba(255,255,255,0.5);
          border-radius: 25px;
          transition: all 0.3s;
          font-size: 0.9rem;
        }
        .profile-links a:hover {
          background: rgba(255,255,255,0.2);
          border-color: white;
        }
        .container {
          max-width: 1000px;
          margin: 0 auto;
          padding: 3rem 2rem;
        }
        .section {
          background: white;
          border-radius: 12px;
          padding: 2.5rem;
          margin-bottom: 2rem;
          box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }
        .section h2 {
          color: #333;
          margin-bottom: 1.5rem;
          font-size: 1.4rem;
          font-weight: 600;
        }
        .about p {
          color: #555;
          line-height: 1.8;
          margin-bottom: 1rem;
        }
        .about p:last-child {
          margin-bottom: 0;
        }
        .skills {
          display: flex;
          flex-wrap: wrap;
          gap: 0.75rem;
        }
        .skill {
          background: #667eea;
          color: white;
          padding: 0.5rem 1rem;
          border-radius: 20px;
          font-size: 0.85rem;
          font-weight: 500;
        }
        .experience-item {
          margin-bottom: 2rem;
          padding-bottom: 2rem;
          border-bottom: 1px solid #eee;
        }
        .experience-item:last-child {
          border-bottom: none;
          margin-bottom: 0;
          padding-bottom: 0;
        }
        .experience-item h3 {
          color: #333;
          margin-bottom: 0.25rem;
          font-size: 1.1rem;
        }
        .experience-item .company {
          color: #667eea;
          font-weight: 600;
          font-size: 0.95rem;
        }
        .experience-item .period {
          color: #888;
          font-size: 0.85rem;
          margin-bottom: 0.75rem;
        }
        .experience-item p {
          color: #555;
          font-size: 0.9rem;
          line-height: 1.7;
        }
        .projects-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
          gap: 1.5rem;
        }
        .project-card {
          background: #f8f9fa;
          border-radius: 8px;
          padding: 1.5rem;
          border: 1px solid #e9ecef;
        }
        .project-card h3 {
          color: #333;
          margin-bottom: 0.5rem;
          font-size: 1rem;
        }
        .project-card p {
          color: #666;
          font-size: 0.85rem;
          line-height: 1.6;
        }
        .project-card {
          text-decoration: none;
          color: inherit;
          display: block;
          transition: transform 0.2s, box-shadow 0.2s;
        }
        .project-card:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .project-disabled {
          opacity: 0.7;
          cursor: not-allowed;
        }
        .project-disabled:hover {
          transform: none;
          box-shadow: none;
        }
        .coming-soon {
          display: inline-block;
          background: #ffc107;
          color: #333;
          padding: 0.25rem 0.75rem;
          border-radius: 12px;
          font-size: 0.75rem;
          font-weight: 600;
          margin-top: 0.5rem;
        }
        .documents-section {
          background: #f8f9fa;
          border-radius: 8px;
          padding: 1.5rem;
          margin-top: 1rem;
        }
        .documents-section p {
          color: #666;
          font-size: 0.9rem;
          margin-bottom: 1rem;
        }
        .documents-section .note {
          color: #888;
          font-size: 0.85rem;
          font-style: italic;
        }
        .doc-list {
          list-style: none;
          margin: 1rem 0;
        }
        .doc-list li {
          padding: 0.5rem 0;
          color: #555;
          font-size: 0.9rem;
        }
        .doc-list li::before {
          content: "📄 ";
        }
        .protected-link {
          display: inline-block;
          background: #667eea;
          color: white;
          padding: 0.75rem 1.5rem;
          border-radius: 8px;
          text-decoration: none;
          font-weight: 500;
          margin-top: 1rem;
          transition: background 0.3s;
        }
        .protected-link:hover {
          background: #5a6fd6;
        }
        .services-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 1.5rem;
        }
        .service-card {
          background: #f8f9fa;
          border-radius: 8px;
          padding: 1.5rem;
          text-decoration: none;
          color: inherit;
          transition: transform 0.2s, box-shadow 0.2s;
          border: 1px solid #e9ecef;
          display: block;
        }
        .service-card:hover {
          transform: translateY(-3px);
          box-shadow: 0 5px 20px rgba(0,0,0,0.1);
        }
        .service-card h3 {
          color: #667eea;
          margin-bottom: 0.5rem;
          font-size: 1rem;
        }
        .service-card p {
          color: #666;
          font-size: 0.85rem;
        }
        .impressum {
          background: #f8f9fa;
          padding: 2rem;
          margin-top: 2rem;
          border-radius: 8px;
          font-size: 0.85rem;
          color: #666;
        }
        .impressum h3 {
          color: #333;
          margin-bottom: 1rem;
          font-size: 1rem;
        }
        .footer {
          text-align: center;
          padding: 2rem;
          color: #888;
          font-size: 0.85rem;
        }
        .footer-logo {
          width: 60px;
          height: 60px;
          opacity: 0.3;
          margin: 1rem auto 0;
        }
        @media (max-width: 768px) {
          .hero h1 {
            font-size: 2rem;
          }
          .hero {
            padding: 3rem 1.5rem;
          }
          .logo {
            width: 80px;
            height: 80px;
          }
          .container {
            padding: 2rem 1rem;
          }
          .section {
            padding: 1.5rem;
          }
        }
      </style>
    </head>
    <body>
      <header class="hero">
        <div class="hero-content">
          <img src="/logo.png" alt="Logo" class="logo">
          <div class="hero-text">
            <h1>${cfg.name}</h1>
            <div class="title">${cfg.title}</div>
            <p class="tagline">${cfg.tagline}</p>
            <div class="profile-links">
              ${lib.optionalString (cfg.github != "") ''<a href="https://github.com/${cfg.github}">GitHub</a>''}
              ${lib.optionalString (cfg.linkedin != "") ''<a href="https://linkedin.com/in/${cfg.linkedin}">LinkedIn</a>''}
              ${lib.optionalString (cfg.xing != "") ''<a href="https://xing.com/profile/${cfg.xing}">Xing</a>''}
            </div>
          </div>
        </div>
      </header>

      <div class="container">
        <section class="section about">
          <h2>Über mich</h2>
          <p>${cfg.about}</p>
        </section>

        <section class="section">
          <h2>Kompetenzen</h2>
          <div class="skills">
            ${lib.concatMapStringsSep "\n            " (skill: ''<span class="skill">${skill}</span>'') cfg.skills}
          </div>
        </section>

        <section class="section">
          <h2>Berufserfahrung</h2>
          ${lib.concatMapStringsSep "\n          " (exp: ''
          <div class="experience-item">
            <h3>${exp.role}</h3>
            <div class="company">${exp.company}</div>
            <div class="period">${exp.period}</div>
            <p>${exp.description}</p>
          </div>
          '') cfg.experience}
        </section>

        <section class="section">
          <h2>Projekte</h2>
          <div class="projects-grid">
            ${lib.concatMapStringsSep "\n            " (proj: ''
            <a href="${proj.url}" class="project-card ${if proj.url == "#" then "project-disabled" else ""}">
              <h3>${proj.name}</h3>
              <p>${proj.description}</p>
            ${if proj.url == "#" then "<span class='coming-soon'>Coming Soon</span>" else ""}
            </a>
            '') cfg.projects}
          </div>
        </section>

        <section class="section">
          <h2>Bewerbungsunterlagen & Kontakt</h2>
          <div class="documents-section">
            <p>Meine vollständigen Bewerbungsunterlagen sowie meine Kontaktdaten (E-Mail, Telefon) stelle ich Ihnen gerne zur Verfügung:</p>
            <ul class="doc-list">
              <li>Lebenslauf (PDF)</li>
              <li>Zeugnisse und Zertifikate</li>
              <li>Kontaktdaten (E-Mail & Telefon)</li>
            </ul>
            <a href="/bewerbung/" class="protected-link">Zum geschützten Bereich</a>
            <p class="note" style="margin-top: 1rem;">Der Zugang ist passwortgeschützt. Das Passwort erhalten Sie über LinkedIn oder auf Anfrage.</p>
          </div>
        </section>

        <section class="section">
          <h2>Self-Hosted Services</h2>
          <div class="services-grid">
            ${lib.concatMapStringsSep "\n            " (svc: ''
            <a href="${svc.url}" class="service-card">
              <h3>${svc.name}</h3>
              <p>${svc.description}</p>
            </a>
            '') cfg.services}
          </div>
        </section>

        <div class="impressum">
          <h3>Impressum</h3>
          <p>
            <strong>${cfg.name}</strong><br>
            ${cfg.address}
          </p>
        </div>
      </div>

      <footer class="footer">
        <p>Diese Website wird auf meiner eigenen Infrastruktur mit NixOS gehostet.</p>
        <img src="/logo.png" alt="Logo" class="footer-logo">
      </footer>
    </body>
    </html>
EOF
  '';

  # Protected area with contact info
  protectedSite = pkgs.runCommand "bewerbung" {} ''
    mkdir -p $out

    cat > $out/index.html << 'EOF'
    <!DOCTYPE html>
    <html lang="de">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Bewerbungsunterlagen - ${cfg.name}</title>
      <link rel="icon" type="image/png" href="/logo.png">
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
          background: #f5f7fa;
          min-height: 100vh;
          color: #333;
          line-height: 1.6;
          padding: 2rem;
        }
        .container {
          max-width: 800px;
          margin: 0 auto;
        }
        .header {
          text-align: center;
          margin-bottom: 2rem;
        }
        .header h1 {
          font-size: 2rem;
          color: #667eea;
          margin-bottom: 0.5rem;
        }
        .header p {
          color: #666;
        }
        .section {
          background: white;
          border-radius: 12px;
          padding: 2rem;
          margin-bottom: 1.5rem;
          box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }
        .section h2 {
          color: #333;
          margin-bottom: 1rem;
          font-size: 1.2rem;
          font-weight: 600;
        }
        .contact-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 1.5rem;
        }
        .contact-item {
          text-align: center;
          padding: 1rem;
          background: #f8f9fa;
          border-radius: 8px;
        }
        .contact-item .label {
          color: #888;
          font-size: 0.8rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 0.5rem;
        }
        .contact-item a, .contact-item span {
          color: #667eea;
          text-decoration: none;
          font-weight: 500;
          font-size: 0.95rem;
        }
        .contact-item a:hover {
          text-decoration: underline;
        }
        .doc-list {
          list-style: none;
        }
        .doc-list li {
          padding: 1rem;
          background: #f8f9fa;
          border-radius: 8px;
          margin-bottom: 0.75rem;
        }
        .doc-list li:last-child {
          margin-bottom: 0;
        }
        .doc-list .desc {
          color: #888;
          font-size: 0.85rem;
          margin-top: 0.25rem;
        }
        .back-link {
          display: inline-block;
          color: #667eea;
          text-decoration: none;
          margin-bottom: 2rem;
        }
        .back-link:hover {
          text-decoration: underline;
        }
        .note {
        .admin-button {
          display: inline-block;
          background: #28a745;
          color: white;
          padding: 0.75rem 1.5rem;
          border-radius: 8px;
          text-decoration: none;
          font-weight: 500;
          margin-top: 1rem;
          transition: background 0.2s;
        }
        .admin-button:hover {
          background: #218838;
        }
        .download-link {
          display: inline-block;
          background: #667eea;
          color: white;
          padding: 0.5rem 1rem;
          border-radius: 6px;
          text-decoration: none;
          font-size: 0.9rem;
          margin-top: 0.5rem;
        }
        .download-link:hover {
          background: #5568d3;
        }
          background: #fff3cd;
          border: 1px solid #ffc107;
          border-radius: 8px;
          padding: 1rem;
          font-size: 0.9rem;
          color: #856404;
        }
      </style>
          <a href="/bewerbung/admin.php" class="admin-button">📁 Dokumente verwalten (Admin)</a>
    </head>
    <body>
      <div class="container">
        <a href="/" class="back-link">← Zurück zur Hauptseite</a>

        <div class="header">
          <h1>Bewerbungsunterlagen</h1>
          <p>${cfg.name} - ${cfg.title}</p>
        </div>

        <section class="section">
          <h2>Kontaktdaten</h2>
          <div class="contact-grid">
            <div class="contact-item">
              <div class="label">E-Mail</div>
              <a href="mailto:${cfg.email}">${cfg.email}</a>
            </div>
            <div class="contact-item">
              <div class="label">Telefon</div>
              <a href="tel:${cfg.phone}">${cfg.phone}</a>
            </div>
            <div class="contact-item">
              <div class="label">Standort</div>
              <span>${cfg.location}</span>
            </div>
          </div>
        </section>

        <section class="section">
          <p style="margin-bottom: 1rem;">Alle hochgeladenen Dokumente sind im Dokumentenbereich verfügbar.</p>
          <a href="/bewerbung/documents/" class="download-link">📄 Zum Dokumentenbereich</a>
          </ul>
        </section>
      </div>
    </body>
    </html>
EOF
  '';
in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption {
      description = "Enable personal landing page";
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = homelab.baseDomain;
      description = "URL for the landing page";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "Felix Maurer";
    };
    title = lib.mkOption {
      type = lib.types.str;
      default = "Data Architect & Energy Systems Engineer";
    };
    tagline = lib.mkOption {
      type = lib.types.str;
      default = "Energiesystemingenieur mit Leidenschaft für Datenarchitektur und die Digitalisierung der Energiewende";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "fmau@posteo.de";
    };
    phone = lib.mkOption {
      type = lib.types.str;
      default = "+49 176 60333285";
    };
    location = lib.mkOption {
      type = lib.types.str;
      default = "Berlin";
    };
    address = lib.mkOption {
      type = lib.types.str;
      default = "Gürtelstraße 11<br>13088 Berlin";
    };
    github = lib.mkOption {
      type = lib.types.str;
      default = "FelixMau";
    };
    linkedin = lib.mkOption {
      type = lib.types.str;
      default = "felix-maurer-0825341ba";
    };
    xing = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    cloudflared.credentialsFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to cloudflared credentials file";
    };
    cloudflared.tunnelId = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflare tunnel ID";
    };
    about = lib.mkOption {
      type = lib.types.str;
      default = ''
        Willkommen auf meiner persönlichen Bewerbungsseite! Ich bin Energiesystemingenieur mit über 4 Jahren Erfahrung in Python-Entwicklung, Datenarchitektur und Automatisierung. Derzeit schließe ich meinen M.Sc. in Regenerativen Energiesystemen an der TU Berlin ab und arbeite parallel an Datenarchitekturen für Energiesystemmodellierung am Fraunhofer IEE.

        Meine Stärken liegen in der Konzeptionierung und Implementierung von Datenpipelines für komplexe Energiesysteme sowie in der eigenständigen Problemlösung. Ich bringe nicht nur technische Expertise mit, sondern auch eine offene Kommunikationsweise, die zu einem produktiven Arbeitsumfeld beiträgt.

        Neben meiner beruflichen Tätigkeit betreibe ich eine eigene Homelab-Infrastruktur mit NixOS und Infrastructure as Code – ein Beweis für meine Begeisterung für Systemadministration und moderne DevOps-Praktiken.
      '';
    };
    skills = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "Python"
        "Datenarchitektur"
        "Git"
        "Docker"
        "NixOS"
        "Energiesysteme"
        "Datenmanagement"
        "Infrastructure as Code"
        "Data Governance"
        "IoT"
      ];
    };
    experience = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          role = lib.mkOption { type = lib.types.str; };
          company = lib.mkOption { type = lib.types.str; };
          period = lib.mkOption { type = lib.types.str; };
          description = lib.mkOption { type = lib.types.str; };
        };
      });
      default = [
        {
          role = "Werkstudent";
          company = "Fraunhofer Institute IEE";
          period = "Sept 2024 - heute";
          description = "Entwicklung von Datenarchitekturen für Energiesystem-Modellierung in Python. Konzeptionierung und Implementierung von Datenstrukturen für komplexe Energiesysteme.";
        }
        {
          role = "Werkstudent";
          company = "Reiner-Lemoine-Institut gGmbH";
          period = "März 2022 - Aug 2024";
          description = "Energiesystem-Modellierung mit Python im SEDOS Projekt. Eigenständige Entwicklung von Datenpipelines und Automatisierung. Datenbankpflege, Datenqualitätssicherung und Data Governance.";
        }
        {
          role = "Werkstudent";
          company = "Tecomon GmbH";
          period = "Okt 2020 - Okt 2021";
          description = "API-Datenabfragen, Datenumwandlung und Datenintegration. Python-Entwicklung für Datenverarbeitung.";
        }
      ];
    };
    projects = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          url = lib.mkOption {
            type = lib.types.str;
            default = "#";
          };
          description = lib.mkOption { type = lib.types.str; };
        };
      });
      default = [
        {
          name = "Home Server & Cloud Infrastructure";
          description = "Systemadministration mit NixOS, Docker-Container und Infrastructure as Code für verschiedene Self-Hosted Services.";
        }
        {
          name = "IoT & Automatisierung";
          description = "Automatisierung und Digitalisierung verschiedener Systeme mit Mikrocontrollern, z.B. IoT-Anbindung einer Kaffeemaschine.";
        }
      ];
    };
    services = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          url = lib.mkOption { type = lib.types.str; };
          description = lib.mkOption { type = lib.types.str; };
        };
      });
      default = [
        {
          name = "Nextcloud";
          url = "https://cloud.${homelab.baseDomain}";
          description = "Cloud-Speicher und Kollaboration";
        }
        {
          name = "Vaultwarden";
          url = "https://pass.${homelab.baseDomain}";
          description = "Passwort-Management";
        }
      ];
    };
  };
  config = lib.mkIf cfg.enable {
    # Enable PHP-FPM for document management
    services.phpfpm.pools.bewerbung = {
      user = "caddy";
      group = "caddy";
      settings = {
        "listen.owner" = "caddy";
        "listen.group" = "caddy";
        "pm" = "dynamic";
        "pm.max_children" = 5;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 3;
        "php_admin_value[upload_max_filesize]" = "10M";
        "php_admin_value[post_max_size]" = "10M";
      };
    };

    services.caddy.virtualHosts.":8080" = {
      extraConfig = ''
        handle /bewerbung/admin.php* {
          basic_auth {
            # Only felix can access admin page
            felix $2y$05$BBFogg5Q5XBuDpJfg4Jwc.9fJ9N18r8RD2TTA7yf5PCkjLGPGot0.
          }
          root * /var/www/bewerbung
          php_fastcgi unix/${config.services.phpfpm.pools.bewerbung.socket}
        }

        handle /bewerbung/documents/* {
          basic_auth {
            import ${config.age.secrets.landingPageHtpasswd.path}
          }
          root * /var/www/bewerbung
          file_server
        }

        handle /bewerbung/* {
          basic_auth {
            import ${config.age.secrets.landingPageHtpasswd.path}
          }
          root * ${protectedSite}
          uri strip_prefix /bewerbung
          file_server
        }

        handle {
          root * ${landingPageSite}
          file_server
        }
      '';
    };

    services.cloudflared = {
      enable = true;
      tunnels.${cfg.cloudflared.tunnelId} = {
        credentialsFile = cfg.cloudflared.credentialsFile;
        default = "http_status:404";
        ingress."${cfg.url}".service = "http://127.0.0.1:8080";
      };
    };
  };
}
