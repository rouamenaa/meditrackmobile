const String documentCss = r'''
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap');

  @page {
    size: A4 portrait;
    margin: 18mm 15mm 18mm 15mm;
    @top-left {
      content: "MediTrack — Dossier de Conception Fonctionnelle et Technique UML 2.5";
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 7.5pt;
      color: #64748b;
      font-weight: 500;
    }
    @top-right {
      content: "Spécification Cible Complète";
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 7.5pt;
      color: #64748b;
      font-weight: 500;
    }
    @bottom-left {
      content: "Usage Exclusif & Médical — Document de Référence v2.0";
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 7.5pt;
      color: #94a3b8;
    }
    @bottom-right {
      content: "Page " counter(page);
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 7.5pt;
      color: #0284c7;
      font-weight: 700;
    }
  }

  @page :first {
    margin: 0;
    @top-left { content: normal; }
    @top-right { content: normal; }
    @bottom-left { content: normal; }
    @bottom-right { content: normal; }
  }

  @page landscape-section {
    size: A4 landscape;
    margin: 14mm 15mm 16mm 15mm;
    @top-left {
      content: "MediTrack — Modélisation UML 2.5 & Architecture Technique (Vue Étendue)";
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 7.5pt;
      color: #64748b;
    }
    @top-right {
      content: "Diagrammes Systémiques & Relations Inter-Modules";
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 7.5pt;
      color: #64748b;
    }
    @bottom-left {
      content: "Système de Santé Mobile Offline-First";
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 7.5pt;
      color: #94a3b8;
    }
    @bottom-right {
      content: "Page " counter(page);
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 7.5pt;
      color: #0284c7;
      font-weight: 700;
    }
  }

  * {
    box-sizing: border-box;
  }

  body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    color: #1e293b;
    background-color: #ffffff;
    line-height: 1.55;
    font-size: 9.5pt;
    margin: 0;
    padding: 0;
  }

  .landscape {
    page: landscape-section;
    break-before: page;
    break-after: page;
  }

  .page-break {
    break-before: page;
  }

  .avoid-break {
    break-inside: avoid;
  }

  /* Cover Page Styling */
  .cover-container {
    width: 210mm;
    min-height: 297mm;
    background: linear-gradient(135deg, #091322 0%, #0f172a 45%, #1e293b 100%);
    color: #ffffff;
    padding: 28mm 22mm 24mm 22mm;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    box-sizing: border-box;
  }

  .cover-badge {
    display: inline-block;
    padding: 6px 16px;
    background: rgba(14, 165, 233, 0.15);
    border: 1px solid #0284c7;
    border-radius: 20px;
    color: #38bdf8;
    font-size: 8.5pt;
    font-weight: 600;
    letter-spacing: 1px;
    text-transform: uppercase;
    margin-bottom: 24px;
  }

  .cover-title {
    font-size: 32pt;
    font-weight: 800;
    letter-spacing: -0.5px;
    line-height: 1.15;
    margin: 0 0 12px 0;
    color: #ffffff;
  }

  .cover-title span {
    color: #38bdf8;
  }

  .cover-subtitle {
    font-size: 14pt;
    font-weight: 400;
    color: #94a3b8;
    line-height: 1.4;
    margin: 0 0 35px 0;
    max-width: 90%;
  }

  .cover-divider {
    height: 4px;
    width: 80px;
    background: linear-gradient(90deg, #0284c7, #38bdf8);
    border-radius: 2px;
    margin-bottom: 35px;
  }

  .cover-meta-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    background: rgba(255, 255, 255, 0.04);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 20px 24px;
    margin-bottom: 30px;
  }

  .cover-meta-item {
    display: flex;
    flex-direction: column;
  }

  .cover-meta-label {
    font-size: 7.5pt;
    text-transform: uppercase;
    letter-spacing: 0.8px;
    color: #64748b;
    font-weight: 600;
    margin-bottom: 4px;
  }

  .cover-meta-val {
    font-size: 9.5pt;
    color: #f1f5f9;
    font-weight: 500;
  }

  .cover-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
    padding-top: 16px;
    font-size: 8pt;
    color: #64748b;
  }

  /* Typography */
  h1 {
    font-size: 18pt;
    font-weight: 800;
    color: #0f172a;
    letter-spacing: -0.3px;
    margin-top: 0;
    margin-bottom: 14px;
    padding-bottom: 8px;
    border-bottom: 2.5px solid #0284c7;
    break-after: avoid;
    display: flex;
    align-items: center;
  }

  .chapter-num {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    background: #0284c7;
    color: white;
    width: 26px;
    height: 26px;
    border-radius: 6px;
    font-size: 10pt;
    font-weight: 700;
    margin-right: 10px;
  }

  h2 {
    font-size: 13pt;
    font-weight: 700;
    color: #0369a1;
    margin-top: 20px;
    margin-bottom: 10px;
    padding-bottom: 4px;
    border-bottom: 1px solid #e2e8f0;
    break-after: avoid;
  }

  h3 {
    font-size: 10.5pt;
    font-weight: 600;
    color: #0f172a;
    margin-top: 16px;
    margin-bottom: 8px;
    break-after: avoid;
  }

  h4 {
    font-size: 9.5pt;
    font-weight: 600;
    color: #475569;
    margin-top: 12px;
    margin-bottom: 6px;
    break-after: avoid;
  }

  p {
    margin: 0 0 10px 0;
    text-align: justify;
  }

  ul, ol {
    margin: 0 0 12px 0;
    padding-left: 22px;
  }

  li {
    margin-bottom: 4px;
  }

  /* Tables */
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 12px 0 16px 0;
    font-size: 8.5pt;
    break-inside: avoid;
  }

  table th {
    background-color: #0f172a;
    color: #ffffff;
    font-weight: 600;
    text-align: left;
    padding: 7px 10px;
    border: 1px solid #1e293b;
    font-size: 8.5pt;
    letter-spacing: 0.2px;
  }

  table td {
    padding: 6px 10px;
    border: 1px solid #cbd5e1;
    vertical-align: top;
  }

  table tr:nth-child(even) td {
    background-color: #f8fafc;
  }

  table tr:hover td {
    background-color: #f1f5f9;
  }

  /* Badges */
  .badge {
    display: inline-block;
    padding: 2px 7px;
    border-radius: 4px;
    font-size: 7.5pt;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }

  .badge-primary { background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; }
  .badge-success { background: #dcfce7; color: #15803d; border: 1px solid #bbf7d0; }
  .badge-warning { background: #fef3c7; color: #b45309; border: 1px solid #fde68a; }
  .badge-danger { background: #fee2e2; color: #b91c1c; border: 1px solid #fecaca; }
  .badge-neutral { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; }

  /* Callouts */
  .callout {
    padding: 10px 14px;
    border-radius: 6px;
    margin: 12px 0 14px 0;
    font-size: 9pt;
    break-inside: avoid;
    border-left: 4px solid;
  }

  .callout-info {
    background: #f0f9ff;
    border-color: #0284c7;
    color: #0369a1;
  }

  .callout-warning {
    background: #fffbeb;
    border-color: #f59e0b;
    color: #92400e;
  }

  .callout-danger {
    background: #fef2f2;
    border-color: #ef4444;
    color: #991b1b;
  }

  .callout-tip {
    background: #f0fdf4;
    border-color: #10b981;
    color: #166534;
  }

  .callout-tech {
    background: #f8fafc;
    border-color: #64748b;
    color: #334155;
  }

  .callout-title {
    font-weight: 700;
    margin-bottom: 4px;
    display: flex;
    align-items: center;
    gap: 6px;
  }

  /* Diagram Box */
  .diagram-container {
    background: #ffffff;
    border: 1px solid #cbd5e1;
    border-radius: 8px;
    padding: 14px;
    margin: 14px 0 18px 0;
    break-inside: avoid;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  }

  .diagram-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-bottom: 8px;
    margin-bottom: 12px;
    border-bottom: 1px solid #e2e8f0;
  }

  .diagram-title {
    font-size: 9.5pt;
    font-weight: 700;
    color: #0f172a;
  }

  .diagram-type {
    font-size: 7.5pt;
    font-weight: 600;
    background: #e2e8f0;
    color: #475569;
    padding: 2px 8px;
    border-radius: 4px;
    text-transform: uppercase;
  }

  .diagram-caption {
    font-size: 8pt;
    color: #64748b;
    font-style: italic;
    margin-top: 10px;
    text-align: center;
    padding-top: 6px;
    border-top: 1px dashed #e2e8f0;
  }

  .mermaid {
    width: 100%;
    display: flex;
    justify-content: center;
    overflow: visible;
  }

  .mermaid svg {
    max-width: 100% !important;
    height: auto !important;
  }

  /* Code block */
  code {
    font-family: 'JetBrains Mono', Consolas, monospace;
    font-size: 8.5pt;
    background: #f1f5f9;
    padding: 2px 5px;
    border-radius: 4px;
    color: #0f172a;
  }

  pre {
    background: #0f172a;
    color: #f8fafc;
    padding: 12px 14px;
    border-radius: 6px;
    overflow-x: auto;
    font-family: 'JetBrains Mono', Consolas, monospace;
    font-size: 8pt;
    line-height: 1.45;
    margin: 10px 0 14px 0;
    break-inside: avoid;
  }

  pre code {
    background: transparent;
    color: inherit;
    padding: 0;
  }

  /* Table of Contents */
  .toc-list {
    list-style: none;
    padding: 0;
    margin: 16px 0;
  }

  .toc-item {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    padding: 5px 0;
    border-bottom: 1px dotted #cbd5e1;
    font-size: 9.5pt;
  }

  .toc-item.level-1 {
    font-weight: 700;
    color: #0f172a;
    padding-top: 8px;
    border-bottom: 1px solid #cbd5e1;
  }

  .toc-item.level-2 {
    padding-left: 18px;
    color: #334155;
    font-weight: 500;
  }

  .toc-title {
    flex-grow: 1;
  }

  .toc-page {
    font-weight: 600;
    color: #0284c7;
    margin-left: 8px;
  }

  /* Step Card for Scenarios */
  .step-card {
    border: 1px solid #cbd5e1;
    border-radius: 8px;
    margin: 12px 0 16px 0;
    break-inside: avoid;
    background: #ffffff;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  }

  .step-header {
    background: #f8fafc;
    border-bottom: 1px solid #e2e8f0;
    padding: 8px 12px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .step-title {
    font-weight: 700;
    font-size: 9.5pt;
    color: #0f172a;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .step-badge {
    background: #0284c7;
    color: white;
    padding: 2px 8px;
    border-radius: 12px;
    font-size: 7.5pt;
    font-weight: 600;
  }

  .step-body {
    padding: 10px 12px;
  }

  .step-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px 16px;
    font-size: 8.5pt;
  }

  .step-field-label {
    font-weight: 600;
    color: #475569;
  }

  .step-field-val {
    color: #0f172a;
  }

  .step-full-row {
    grid-column: 1 / -1;
    padding-top: 6px;
    border-top: 1px dashed #e2e8f0;
  }
</style>
''';
