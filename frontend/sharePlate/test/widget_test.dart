import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shareplate/models/verification_document_model.dart';
import 'package:shareplate/widgets/shared/profile_widgets.dart';

void main() {
  testWidgets('ProfileHeader renders initials and name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileHeader(
            initials: 'AF',
            name: 'Aasha Foundation',
            subtitle: 'Recipient · NGO',
          ),
        ),
      ),
    );

    expect(find.text('Aasha Foundation'), findsOneWidget);
    expect(find.text('Recipient · NGO'), findsOneWidget);
    expect(find.text('AF'), findsOneWidget);
  });

  test('VerificationDocumentModel default documents exist and copyWith works', () {
    final docs = VerificationDocumentModel.defaultBusinessDocuments();
    expect(docs.isNotEmpty, isTrue);

    final first = docs.first;
    final updated = first.copyWith(
      fileName: 'updated_certificate.png',
      status: VerificationDocumentStatus.pending,
    );

    expect(updated.fileName, 'updated_certificate.png');
    expect(updated.status, VerificationDocumentStatus.pending);
    expect(updated.id, first.id);
  });
}
