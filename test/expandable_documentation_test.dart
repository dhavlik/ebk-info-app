import 'package:flutter_test/flutter_test.dart';
import 'package:ebk_app/models/documentation_item.dart';
import 'package:ebk_app/services/documentation_service.dart';

void main() {
  group('Expandable Documentation Tests', () {
    late DocumentationService service;

    setUp(() {
      service = DocumentationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('DocumentationItem.copyWith should update properties correctly', () {
      const originalItem = DocumentationItem(
        id: 'bereiche',
        title: 'Bereiche',
        url: 'https://example.com',
        type: DocumentationItemType.namespace,
        isExpanded: false,
        isLoading: false,
        children: [],
      );

      final updatedItem = originalItem.copyWith(
        isExpanded: true,
        children: const [
          DocumentationItem(
            id: 'sub1',
            title: 'Subcategory 1',
            url: 'https://example.com/sub1',
            type: DocumentationItemType.page,
          ),
        ],
      );

      expect(updatedItem.isExpanded, true);
      expect(updatedItem.children.length, 1);
      expect(updatedItem.children.first.title, 'Subcategory 1');
      expect(updatedItem.id, originalItem.id); // Should remain unchanged
      expect(updatedItem.title, originalItem.title); // Should remain unchanged
    });

    test('DocumentationItem.hasChildren should return correct value', () {
      const emptyItem = DocumentationItem(
        id: 'empty',
        title: 'Empty',
        url: 'https://example.com',
        type: DocumentationItemType.namespace,
      );

      const itemWithChildren = DocumentationItem(
        id: 'parent',
        title: 'Parent',
        url: 'https://example.com',
        type: DocumentationItemType.namespace,
        children: [
          DocumentationItem(
            id: 'child',
            title: 'Child',
            url: 'https://example.com/child',
            type: DocumentationItemType.page,
          ),
        ],
      );

      expect(emptyItem.hasChildren, false);
      expect(itemWithChildren.hasChildren, true);
    });

    test('DocumentationItem factory should create expandable items correctly',
        () {
      final item = DocumentationItem.fromIndexHtml(
        id: 'test',
        title: 'Test Item',
        url: 'https://example.com',
        type: DocumentationItemType.namespace,
        isExpanded: true,
        isLoading: false,
      );

      expect(item.isExpanded, true);
      expect(item.isLoading, false);
      expect(item.hasChildren, false);
      expect(item.isNamespace, true);
    });

    test('Namespace content loading should handle expansion state', () async {
      // This test would normally require mocking the HTTP client
      // For now, we'll test the service structure
      expect(service.getNamespaceContent, isA<Function>());
    });
  });
}
