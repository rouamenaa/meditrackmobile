const String coverAndTocHtml = r'''
<!-- COVER PAGE -->
<div class="cover-container">
  <div>
    <div class="cover-badge">Spécification d'Ingénierie Logicielle — Health Systems</div>
    <h1 class="cover-title">MediTrack<span>Mobile</span></h1>
    <div class="cover-subtitle">Dossier de Conception Fonctionnelle & Technique Complète<br>Modélisation UML 2.5, Modèle Relationnel 3NF & Architecture Cible Flutter</div>
    <div class="cover-divider"></div>
  </div>

  <div>
    <div class="cover-meta-grid">
      <div class="cover-meta-item">
        <span class="cover-meta-label">Rôle & Auteur</span>
        <span class="cover-meta-val">Architecte Logiciel Senior Systèmes de Santé & Flutter</span>
      </div>
      <div class="cover-meta-item">
        <span class="cover-meta-label">Version du Document</span>
        <span class="cover-meta-val">Version 2.0 — Spécification Cible Complète</span>
      </div>
      <div class="cover-meta-item">
        <span class="cover-meta-label">Cadre Normatif</span>
        <span class="cover-meta-val">UML 2.5 • RGPD / Données de Santé • Offline-First</span>
      </div>
      <div class="cover-meta-item">
        <span class="cover-meta-label">Technologies Cibles</span>
        <span class="cover-meta-val">Flutter 3.x • Clean Architecture • SQLite / SQLCipher • BLoC</span>
      </div>
      <div class="cover-meta-item">
        <span class="cover-meta-label">Date d'Émission</span>
        <span class="cover-meta-val">Octobre 2026</span>
      </div>
      <div class="cover-meta-item">
        <span class="cover-meta-label">Statut du Livrable</span>
        <span class="cover-meta-val" style="color: #4ade80;">Validé pour Référence & Implémentation</span>
      </div>
    </div>
  </div>

  <div class="cover-footer">
    <span>Projet MediTrack Mobile — Système Autonome d'Assistance Thérapeutique & d'Activité</span>
    <span>Document d'Architecture Technique Globale</span>
  </div>
</div>

<!-- PAGE BREAK: TABLE OF CONTENTS -->
<div class="page-break"></div>

<div class="avoid-break">
  <h1><span class="chapter-num">0</span> Sommaire Exécutif</h1>
  <p>Ce document constitue le référentiel d'ingénierie logicielle pour l'application mobile <strong>MediTrack</strong>. Il définit une modélisation conceptuelle, relationnelle et technique exhaustive, indépendamment des limites du code préexistant.</p>
</div>

<ul class="toc-list">
  <li class="toc-item level-1">
    <span class="toc-title">1. Présentation Fonctionnelle & Vision du Système</span>
    <span class="toc-page">Section 1</span>
  </li>
  <li class="toc-item level-2"><span>1.1 Contexte Médical et Problématique de l'Observance Thérapeutique</span></li>
  <li class="toc-item level-2"><span>1.2 Objectifs Stratégiques et Philosophie « Offline-First »</span></li>
  <li class="toc-item level-2"><span>1.3 Typologie des Utilisateurs et Besoins Cliniques</span></li>
  <li class="toc-item level-2"><span>1.4 Principes d'Ingénierie & Frontières du Système</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">2. Périmètre Complet des Cinq Modules Obligatoires</span>
    <span class="toc-page">Section 2</span>
  </li>
  <li class="toc-item level-2"><span>2.1 Module 1 — Utilisateurs, Authentification, Profil Médical et Confidentialité</span></li>
  <li class="toc-item level-2"><span>2.2 Module 2 — Activité Physique, Métriques et Moteur Métabolique MET</span></li>
  <li class="toc-item level-2"><span>2.3 Module 3 — Médicaments et Armoire à Pharmacie Personnelle</span></li>
  <li class="toc-item level-2"><span>2.4 Module 4 — Traitements, Prescriptions, Planning et Observance Thérapeutique</span></li>
  <li class="toc-item level-2"><span>2.5 Module 5 — Rendez-vous Médicaux, Praticiens et Consultations Réalisées</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">3. Diagramme Global de Classes UML 2.5</span>
    <span class="toc-page">Section 3</span>
  </li>
  <li class="toc-item level-2"><span>3.1 Vue Systémique Globale des Entités Métier</span></li>
  <li class="toc-item level-2"><span>3.2 Dictionnaire des Associations Inter-Modules et Justification des Cardinalités</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">4. Diagrammes Détaillés par Module & Architecture Technique</span>
    <span class="toc-page">Section 4</span>
  </li>
  <li class="toc-item level-2"><span>4.1 Diagramme Détaillé Module 1 : Authentification & Sécurité</span></li>
  <li class="toc-item level-2"><span>4.2 Diagramme Détaillé Module 2 : Activité Physique & Métriques</span></li>
  <li class="toc-item level-2"><span>4.3 Diagramme Détaillé Module 3 : Médicaments & Inventaire</span></li>
  <li class="toc-item level-2"><span>4.4 Diagramme Détaillé Module 4 : Traitements & Planning d'Observance</span></li>
  <li class="toc-item level-2"><span>4.5 Diagramme Détaillé Module 5 : Rendez-vous & Praticiens</span></li>
  <li class="toc-item level-2"><span>4.6 Diagramme Technique : Services Applicatifs et Repositories</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">5. Modélisation des Données Relationnelles (3NF)</span>
    <span class="toc-page">Section 5</span>
  </li>
  <li class="toc-item level-2"><span>5.1 Diagramme Entité-Association Relationnel (ERD)</span></li>
  <li class="toc-item level-2"><span>5.2 Dictionnaire Détaillé des 14 Tables SQL & Contraintes d'Intégrité</span></li>
  <li class="toc-item level-2"><span>5.3 Politiques de Clés Étrangères et Stratégie de Soft Delete</span></li>
  <li class="toc-item level-2"><span>5.4 Analyse Différentielle : Entités Métier vs Services vs Tables BDD</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">6. Diagrammes UML Complémentaires</span>
    <span class="toc-page">Section 6</span>
  </li>
  <li class="toc-item level-2"><span>6.1 Diagramme Global de Cas d'Utilisation (Use Cases)</span></li>
  <li class="toc-item level-2"><span>6.2 Diagrammes de Séquence Systémiques (4 scénarios fondamentaux)</span></li>
  <li class="toc-item level-2"><span>6.3 Diagramme d'Activité : Cycle Quotidien du Patient</span></li>
  <li class="toc-item level-2"><span>6.4 Diagrammes d'États (Traitement, Prise Prévue, Rendez-vous)</span></li>
  <li class="toc-item level-2"><span>6.5 Diagramme de Composants : Architecture en Couches Flutter</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">7. Scénario Principal Complet (Cycle de Vie en 12 Étapes)</span>
    <span class="toc-page">Section 7</span>
  </li>
  <li class="toc-item level-2"><span>7.1 Description Exhaustive Étape par Étape (Acteurs, Classes, Services, I/O BDD, Dégradé)</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">8. Scénarios Alternatifs et Gestion des Erreurs</span>
    <span class="toc-page">Section 8</span>
  </li>
  <li class="toc-item level-2"><span>8.1 Analyse des 11 Cas Alternatifs, Conflits et Résilience Système</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">9. Architecture Technique Cible & Implémentation Flutter</span>
    <span class="toc-page">Section 9</span>
  </li>
  <li class="toc-item level-2"><span>9.1 Organisation Clean Architecture (Presentation, Domain, Data, Core)</span></li>
  <li class="toc-item level-2"><span>9.2 Gestion d'État Réactive (Flutter BLoC / Cubit)</span></li>
  <li class="toc-item level-2"><span>9.3 Persistance Chiffrée SQLCipher (AES-256) & Secure Storage</span></li>
  <li class="toc-item level-2"><span>9.4 Moteur d'Alarmes Exactes & Notifications Locales Prioritaires</span></li>
  <li class="toc-item level-2"><span>9.5 Gestion Fonctionnelle des Erreurs (Either Pattern) & Synchronisation Dégradée</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">10. Règles Métier, Sécurité et Décisions de Conception</span>
    <span class="toc-page">Section 10</span>
  </li>
  <li class="toc-item level-2"><span>10.1 Cloisonnement des Données, ACID & Gestion Universelle UTC</span></li>
  <li class="toc-item level-2"><span>10.2 Algorithme Déterministe Anti-Doublons & Conformité RGPD/HDS</span></li>
  <li class="toc-item level-2"><span>10.3 Décharge Légale et Responsabilité Éthique</span></li>

  <li class="toc-item level-1">
    <span class="toc-title">11. Conclusion Récapitulative & Matrice de Traçabilité</span>
    <span class="toc-page">Section 11</span>
  </li>
</ul>
''';
