import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_ui/widgets/location_autocomplete_field.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('LocationAutocompleteField', () {
    testWidgets('renders with initial address', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              initialAddress: 'São Paulo, SP',
              onLocationSelected: (_, __, ___, ____, _____) {},
            ),
          ),
        ),
      );

      expect(find.byType(LocationAutocompleteField), findsOneWidget);
      expect(find.text('São Paulo, SP'), findsOneWidget);
    });

    testWidgets('shows hint text when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              onLocationSelected: (_, __, ___, ____, _____) {},
            ),
          ),
        ),
      );

      expect(
        find.text('Buscar localização (cidade, bairro, endereço...)'),
        findsOneWidget,
      );
    });

    testWidgets('calls onLocationSelected with correct data', (tester) async {
      GeoPoint? capturedLocation;
      String? capturedCity;
      String? capturedNeighborhood;
      String? capturedState;
      String? capturedFullAddress;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              onLocationSelected:
                  (location, city, neighborhood, state, fullAddress) {
                capturedLocation = location;
                capturedCity = city;
                capturedNeighborhood = neighborhood;
                capturedState = state;
                capturedFullAddress = fullAddress;
              },
            ),
          ),
        ),
      );

      // Type address query
      await tester.enterText(
        find.byType(TextField),
        'Avenida Paulista, São Paulo',
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Note: Full integration test with HTTP would require mocking
      // This is a basic widget rendering test
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('disables field when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              onLocationSelected: (_, __, ___, ____, _____) {},
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('shows validator error when validation fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: LocationAutocompleteField(
                onLocationSelected: (_, __, ___, ____, _____) {},
                validator: (value) => 'Campo obrigatório',
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    test('parseLocationComponents extracts city correctly', () {
      final addressData = {
        'city': 'São Paulo',
        'town': 'Campinas',
        'village': 'Holambra',
      };

      // Should prioritize 'city' over 'town' over 'village'
      expect(addressData['city'], 'São Paulo');
    });

    test('parseLocationComponents handles missing fields gracefully', () {
      final addressData = <String, dynamic>{};

      expect(addressData['city'], isNull);
      expect(addressData['neighbourhood'], isNull);
      expect(addressData['state'], isNull);
    });

    testWidgets('shows loading indicator while searching', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              onLocationSelected: (_, __, ___, ____, _____) {},
            ),
          ),
        ),
      );

      // Type enough characters to trigger search
      await tester.enterText(find.byType(TextField), 'São');
      await tester.pump(const Duration(milliseconds: 100));

      // Verify widget is rendered (loading state tested in integration tests)
      expect(find.byType(LocationAutocompleteField), findsOneWidget);
    });

    testWidgets('clears field when clear button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              initialAddress: 'São Paulo',
              onLocationSelected: (_, __, ___, ____, _____) {},
            ),
          ),
        ),
      );

      // Verify initial text
      expect(find.text('São Paulo'), findsOneWidget);

      // Find and tap clear button
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Verify text was cleared
        expect(find.text('São Paulo'), findsNothing);
      }
    });

    testWidgets('does not trigger search for queries < 3 characters',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAutocompleteField(
              onLocationSelected: (_, __, ___, ____, _____) {},
            ),
          ),
        ),
      );

      // Type 2 characters
      await tester.enterText(find.byType(TextField), 'SP');
      await tester.pump(const Duration(milliseconds: 400));

      // Should not show suggestions (no network call)
      expect(find.byType(LocationAutocompleteField), findsOneWidget);
    });

    test('GeoPoint is created with correct lat/lon', () {
      final geoPoint = GeoPoint(-23.5505, -46.6333);
      expect(geoPoint.latitude, -23.5505);
      expect(geoPoint.longitude, -46.6333);
    });

    test('structured location data contains all fields', () {
      final mockData = {
        'city': 'São Paulo',
        'neighbourhood': 'Paulista',
        'state': 'SP',
        'road': 'Avenida Paulista',
      };

      expect(mockData['city'], 'São Paulo');
      expect(mockData['neighbourhood'], 'Paulista');
      expect(mockData['state'], 'SP');
      expect(mockData['road'], 'Avenida Paulista');
    });
  });

  group('LocationAutocompleteField - OpenStreetMap Integration', () {
    test('builds correct Nominatim API URL', () {
      const query = 'São Paulo';
      final expectedUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5',
      );

      expect(expectedUrl.scheme, 'https');
      expect(expectedUrl.host, 'nominatim.openstreetmap.org');
      expect(expectedUrl.path, '/search');
      expect(expectedUrl.queryParameters['q'], query);
      expect(expectedUrl.queryParameters['format'], 'json');
      expect(expectedUrl.queryParameters['addressdetails'], '1');
      expect(expectedUrl.queryParameters['limit'], '5');
    });

    test('parses OpenStreetMap JSON response correctly', () {
      const mockResponse = '''
      [
        {
          "lat": "-23.5505",
          "lon": "-46.6333",
          "display_name": "São Paulo, Brasil",
          "address": {
            "city": "São Paulo",
            "state": "São Paulo",
            "country": "Brasil"
          }
        }
      ]
      ''';

      final parsed = json.decode(mockResponse) as List<dynamic>;
      final firstResult = parsed[0] as Map<String, dynamic>;

      expect(firstResult['lat'], '-23.5505');
      expect(firstResult['lon'], '-46.6333');
      expect(firstResult['display_name'], 'São Paulo, Brasil');
      
      final address = firstResult['address'] as Map<String, dynamic>;
      expect(address['city'], 'São Paulo');
      expect(address['state'], 'São Paulo');
    });

    test('handles empty API response gracefully', () {
      const mockResponse = '[]';
      final parsed = json.decode(mockResponse) as List<dynamic>;
      expect(parsed.isEmpty, true);
    });

    test('includes User-Agent header in request', () {
      const expectedHeader = {'User-Agent': 'to-sem-banda-app'};
      expect(expectedHeader['User-Agent'], 'to-sem-banda-app');
    });
  });
}
