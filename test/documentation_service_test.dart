import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ebk_app/services/documentation_service.dart';

import 'documentation_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('DocumentationService', () {
    late DocumentationService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      service = DocumentationService(client: mockClient);
    });

    group('getDocumentationStructure', () {
      test('should parse HTML index and return documentation items', () async {
        // Mock HTML index content that matches DokuWiki structure
        const mockHtmlContent = '''
<!DOCTYPE html>
<html>
<head><title>Index</title></head>
<body>
  <div class="content">
    <ul class="idx">
      <li class="level1">
        <div class="li">
          <a href="/doku.php?id=start&amp;idx=bereiche" class="idx_dir">
            <strong>Bereiche</strong>
          </a>
        </div>
      </li>
      <li class="level1">
        <div class="li">
          <a href="/doku.php?id=start&amp;idx=geraete" class="idx_dir">
            <strong>Geräte</strong>
          </a>
        </div>
      </li>
      <li class="level1">
        <div class="li">
          <a href="/doku.php?id=start&amp;idx=howtos" class="idx_dir">
            <strong>How-Tos</strong>
          </a>
        </div>
      </li>
      <li class="level1">
        <div class="li">
          <a href="/doku.php?id=wiki:welcome" class="wikilink1" data-wiki-id="wiki:welcome">Welcome</a>
        </div>
      </li>
    </ul>
  </div>
</body>
</html>''';

        // Mock HTTP response for index page
        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/doku.php?do=index'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(mockHtmlContent, 200));

        final result = await service.getDocumentationStructure();

        // Verify results
        expect(result, isNotEmpty);

        // Should exclude wiki:welcome based on exclusion rules
        expect(result.where((item) => item.id == 'wiki:welcome'), isEmpty);

        // Should include bereiche items
        final bereicheItems = result.where((item) => item.id == 'bereiche');
        expect(bereicheItems, isNotEmpty);

        // Should include geraete items
        final geraeteItems = result.where((item) => item.id == 'geraete');
        expect(geraeteItems, isNotEmpty);

        // Should include howtos namespace (not as page anymore)
        final howtosItems = result.where((item) => item.id == 'howtos');
        expect(howtosItems, isNotEmpty);
        // Verify it's treated as a namespace
        final howtosItem = howtosItems.first;
        expect(howtosItem.isNamespace, isTrue);

        // Verify that only namespaces are returned at top level (no standalone pages)
        final namespaces = result.where((item) => item.isNamespace).toList();
        final pages = result.where((item) => item.isPage).toList();

        // All items should be namespaces
        expect(result.length, equals(namespaces.length));
        expect(pages, isEmpty);
      });

      test('should handle HTTP errors gracefully', () async {
        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/doku.php?do=index'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Not Found', 404));

        expect(
          () => service.getDocumentationStructure(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle malformed HTML gracefully', () async {
        const malformedHtml = '<html><body>incomplete html';

        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/doku.php?do=index'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(malformedHtml, 200));

        final result = await service.getDocumentationStructure();

        // Should return empty list for HTML without index list
        expect(result, isEmpty);
      });
    });

    group('getNamespaceContent', () {
      test('should parse namespace content and return child items', () async {
        // Mock HTML content for a namespace
        const mockNamespaceHtml = '''
<!DOCTYPE html>
<html>
<head><title>Bereiche</title></head>
<body>
  <div class="content">
    <ul class="idx">
      <li class="level1">
        <div class="li">
          <a href="/doku.php?id=start&amp;idx=bereiche:3d_drucker" class="idx_dir">
            <strong>3D Drucker</strong>
          </a>
        </div>
      </li>
      <li class="level1">
        <div class="li">
          <a href="/doku.php?id=start&amp;idx=bereiche:holzwerkstatt" class="idx_dir">
            <strong>Holzwerkstatt</strong>
          </a>
        </div>
      </li>
      <li class="level1">
        <div class="li">
          <a href="/doku.php?id=bereiche:info" class="wikilink1" data-wiki-id="bereiche:info">Bereichs-Info</a>
        </div>
      </li>
    </ul>
  </div>
</body>
</html>''';

        // Mock HTTP response for namespace content
        when(mockClient.get(
          Uri.parse(
              'https://doku.eigenbaukombinat.de/doku.php?id=start&idx=bereiche'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(mockNamespaceHtml, 200));

        final result = await service.getNamespaceContent('bereiche');

        // Verify results
        expect(result, isNotEmpty);

        // Should include sub-namespaces
        final subNamespaces = result.where((item) => item.isNamespace);
        expect(subNamespaces.length, equals(2));
        expect(subNamespaces.any((item) => item.id == 'bereiche:3d_drucker'),
            isTrue);
        expect(subNamespaces.any((item) => item.id == 'bereiche:holzwerkstatt'),
            isTrue);

        // Should include pages
        final pages = result.where((item) => item.isPage);
        expect(pages.length, equals(1));
        expect(pages.any((item) => item.id == 'bereiche:info'), isTrue);
      });

      test('should return empty list for HTTP errors', () async {
        when(mockClient.get(
          Uri.parse(
              'https://doku.eigenbaukombinat.de/doku.php?id=start&idx=nonexistent'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Not Found', 404));

        final result = await service.getNamespaceContent('nonexistent');

        expect(result, isEmpty);
      });
    });

    group('getNamespacePageContent', () {
      test('should extract page content from namespace page', () async {
        // Mock HTML content for a namespace that has a page
        const mockPageHtml = '''
<!DOCTYPE html>
<html>
<head><title>Bereiche</title></head>
<body>
  <div class="page group">
    <h1>Welcome to Bereiche</h1>
    <p>This is the main page for all areas.</p>
    <div id="dw__toc">
      <h3>Table of Contents</h3>
      <ul><li>Some TOC</li></ul>
    </div>
    <h2>Areas Overview</h2>
    <p>Here are all the areas...</p>
  </div>
</body>
</html>''';

        // Mock HTTP response for namespace page
        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/doku.php?id=bereiche'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(mockPageHtml, 200));

        final result = await service.getNamespacePageContent('bereiche');

        // Verify results
        expect(result, isNotNull);
        expect(result!, contains('Welcome to Bereiche'));
        expect(result, contains('Areas Overview'));
        // Should not contain the table of contents
        expect(result, isNot(contains('Table of Contents')));
        // Should be wrapped in proper HTML structure
        expect(result, contains('<!DOCTYPE html>'));
        expect(result, contains('<html>'));
        expect(result, contains('</html>'));
      });

      test('should return null for pages without content', () async {
        // Mock HTML content without page div
        const mockHtmlWithoutContent = '''
<!DOCTYPE html>
<html>
<head><title>No Content</title></head>
<body>
  <div class="content">
    <p>No page content here</p>
  </div>
</body>
</html>''';

        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/doku.php?id=empty'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(mockHtmlWithoutContent, 200));

        final result = await service.getNamespacePageContent('empty');

        expect(result, isNull);
      });

      test('should return null for HTTP errors', () async {
        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/doku.php?id=nonexistent'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Not Found', 404));

        final result = await service.getNamespacePageContent('nonexistent');

        expect(result, isNull);
      });
    });

    group('getDirectPageUrl', () {
      test('should convert idx URLs to id URLs', () {
        const inputUrl =
            'https://doku.eigenbaukombinat.de/doku.php?id=start&idx=bereiche';
        final result = service.getDirectPageUrl(inputUrl);
        expect(result,
            equals('https://doku.eigenbaukombinat.de/doku.php?id=bereiche'));
      });

      test('should return id URLs unchanged', () {
        const inputUrl =
            'https://doku.eigenbaukombinat.de/doku.php?id=bereiche';
        final result = service.getDirectPageUrl(inputUrl);
        expect(result, equals(inputUrl));
      });

      test('should return unrecognized URLs unchanged', () {
        const inputUrl = 'https://example.com/some/path';
        final result = service.getDirectPageUrl(inputUrl);
        expect(result, equals(inputUrl));
      });
    });
  });
}
