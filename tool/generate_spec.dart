import 'dart:io';

import 'parts/css.dart';
import 'parts/cover_toc.dart';
import 'parts/section1_functional.dart';
import 'parts/section2_modules.dart';
import 'parts/section3_global_class.dart';
import 'parts/section4_detailed_classes.dart';
import 'parts/section5_data_model.dart';
import 'parts/section6_complementary_diagrams.dart';
import 'parts/section7_main_scenario.dart';
import 'parts/section8_alternative_scenarios.dart';
import 'parts/section9_tech_architecture.dart';
import 'parts/section10_business_rules.dart';
import 'parts/section11_conclusion.dart';

void main() async {
  print('=== MediTrack Specification Builder ===');

  final fullHtml = '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MediTrack — Conception Fonctionnelle et Technique Complète UML 2.5</title>
  $documentCss
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <script>
    document.addEventListener("DOMContentLoaded", function() {
      mermaid.initialize({
        startOnLoad: true,
        theme: 'base',
        themeVariables: {
          fontFamily: 'Inter, Segoe UI, sans-serif',
          fontSize: '12px',
          primaryColor: '#e0f2fe',
          primaryBorderColor: '#0284c7',
          primaryTextColor: '#0f172a',
          lineColor: '#334155',
          secondaryColor: '#f8fafc',
          tertiaryColor: '#ffffff',
          edgeLabelBackground: '#ffffff',
          noteBkgColor: '#fef3c7',
          noteTextColor: '#92400e',
          noteBorderColor: '#f59e0b',
          actorBkg: '#e0f2fe',
          actorBorder: '#0284c7',
          actorTextColor: '#0f172a',
          signalColor: '#0f172a',
          signalTextColor: '#0f172a'
        },
        flowchart: { useMaxWidth: true, htmlLabels: true, curve: 'basis' },
        sequence: { useMaxWidth: true, mirrorActors: false, actorMargin: 40, boxMargin: 10 },
        class: { useMaxWidth: true }
      });
    });
  </script>
</head>
<body>
  $coverAndTocHtml
  $section1FunctionalHtml
  $section2ModulesHtml
  $section3GlobalClassHtml
  $section4DetailedClassesHtml
  $section5DataModelHtml
  $section6ComplementaryDiagramsHtml
  $section7MainScenarioHtml
  $section8AlternativeScenariosHtml
  $section9TechArchitectureHtml
  $section10BusinessRulesHtml
  $section11ConclusionHtml
</body>
</html>
''';

  final htmlFile = File('tool/meditrack_spec.html');
  await htmlFile.writeAsString(fullHtml);
  print('HTML specification generated at: ${htmlFile.path} (${htmlFile.lengthSync()} bytes)');

  final currentDir = Directory.current.path;
  final htmlPath = '$currentDir/tool/meditrack_spec.html'.replaceAll('/', '\\');
  final pdfPath = '$currentDir/MediTrack_Conception_Complete_UML.pdf'.replaceAll('/', '\\');

  const edgeExecutable = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe';
  print('Compiling PDF via Headless Edge: $edgeExecutable ...');

  final stopwatch = Stopwatch()..start();
  final result = await Process.run(edgeExecutable, [
    '--headless=new',
    '--disable-gpu',
    '--run-all-compositor-stages-before-draw',
    '--virtual-time-budget=15000',
    '--no-pdf-header-footer',
    '--print-to-pdf=$pdfPath',
    htmlPath,
  ]);

  stopwatch.stop();
  print('Edge process completed in ${stopwatch.elapsedMilliseconds} ms with code ${result.exitCode}');

  final pdfFile = File(pdfPath);
  if (await pdfFile.exists()) {
    final size = await pdfFile.length();
    print('SUCCESS! MediTrack_Conception_Complete_UML.pdf generated successfully!');
    print('Path: $pdfPath');
    print('File size: $size bytes (${(size / 1024).toStringAsFixed(1)} KB)');
  } else {
    print('ERROR: PDF file was not created!');
    if (result.stderr.toString().isNotEmpty) {
      print('Edge stderr: ${result.stderr}');
    }
  }
}
