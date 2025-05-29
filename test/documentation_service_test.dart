import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ebk_app/services/documentation_service.dart';
import 'package:ebk_app/models/documentation_item.dart';

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
      test('should parse sitemap XML and return documentation items', () async {
        // Mock sitemap XML content
        const mockXmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://doku.eigenbaukombinat.de/doku.php?id=bereiche</loc>
    <lastmod>2024-01-01T00:00:00+00:00</lastmod>
  </url>
  <url>
    <loc>https://doku.eigenbaukombinat.de/doku.php?id=bereiche:3d_drucker</loc>
    <lastmod>2024-01-01T00:00:00+00:00</lastmod>
  </url>
  <url>
    <loc>https://doku.eigenbaukombinat.de/doku.php?id=geraete</loc>
    <lastmod>2024-01-01T00:00:00+00:00</lastmod>
  </url>
  <url>
    <loc>https://doku.eigenbaukombinat.de/doku.php?id=wiki:welcome</loc>
    <lastmod>2024-01-01T00:00:00+00:00</lastmod>
  </url>
</urlset>''';

        // Compress the XML content as it would be served
        final compressedBytes = gzip.encode(utf8.encode(mockXmlContent));

        // Mock HTTP response
        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/?do=sitemap'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response.bytes(
              compressedBytes,
              200,
              headers: {'content-type': 'application/x-gzip'},
            ));

        final result = await service.getDocumentationStructure();

        // Verify results
        expect(result, isNotEmpty);

        // Should exclude wiki:welcome based on exclusion rules
        expect(result.where((item) => item.id == 'wiki:welcome'), isEmpty);

        // Should include bereiche items
        final bereicheItems =
            result.where((item) => item.id.startsWith('bereiche'));
        expect(bereicheItems, isNotEmpty);

        // Verify that namespaces come before pages (based on organization)
        final namespaces = result.where((item) => item.isNamespace).toList();
        final pages = result.where((item) => item.isPage).toList();

        if (namespaces.isNotEmpty && pages.isNotEmpty) {
          final firstNamespaceIndex = result.indexOf(namespaces.first);
          final firstPageIndex = result.indexOf(pages.first);
          expect(firstNamespaceIndex, lessThan(firstPageIndex));
        }
      });

      test('should handle HTTP errors gracefully', () async {
        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/?do=sitemap'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Not Found', 404));

        expect(
          () => service.getDocumentationStructure(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle malformed XML gracefully', () async {
        const malformedXml = 'not valid xml content';
        final compressedBytes = gzip.encode(utf8.encode(malformedXml));

        when(mockClient.get(
          Uri.parse('https://doku.eigenbaukombinat.de/?do=sitemap'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response.bytes(compressedBytes, 200));

        final result = await service.getDocumentationStructure();

        // Should return empty list for malformed XML
        expect(result, isEmpty);
      });
    });

    group('getDirectPageUrl', () {
      test('should return DokuWiki URLs unchanged', () {
        const inputUrl =
            'https://doku.eigenbaukombinat.de/doku.php?id=bereiche';
        final result = service.getDirectPageUrl(inputUrl);
        expect(result, equals(inputUrl));
      });

      test('should handle URLs with idx parameter', () {
        const inputUrl =
            'https://doku.eigenbaukombinat.de/doku.php?idx=bereiche';
        final result = service.getDirectPageUrl(inputUrl);
        expect(result,
            equals('https://doku.eigenbaukombinat.de/doku.php?id=bereiche'));
      });
    });
  });
}
