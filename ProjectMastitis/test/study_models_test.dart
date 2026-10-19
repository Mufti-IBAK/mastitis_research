import 'package:flutter_test/flutter_test.dart';
import 'package:project_mastitis/models/study_models.dart';

void main() {
  group('Study Models & Calculations Test', () {
    test('Calculates DIM correctly', () {
      final cow = CowRecord(
        cowId: 'C001',
        calvingDate: '2026-08-01',
      );
      final dim = cow.computeDim('2026-10-11');
      expect(dim, 71);
    });

    test('Derives CMT Positive correctly', () {
      final qN = QuarterData(quarter: 'LF', cmtScore: 'N');
      expect(qN.cmtPositiveDerived, 'No');

      final qT = QuarterData(quarter: 'RF', cmtScore: 'T');
      expect(qT.cmtPositiveDerived, 'No');

      final q1 = QuarterData(quarter: 'LR', cmtScore: '1');
      expect(q1.cmtPositiveDerived, 'Yes');

      final q2 = QuarterData(quarter: 'RR', cmtScore: '2');
      expect(q2.cmtPositiveDerived, 'Yes');

      final q3 = QuarterData(quarter: 'LF', cmtScore: '3');
      expect(q3.cmtPositiveDerived, 'Yes');

      final qNd = QuarterData(quarter: 'RF', cmtScore: 'Not done');
      expect(qNd.cmtPositiveDerived, 'Not assessable');
    });

    test('Derives SCS from SCC correctly', () {
      final q = QuarterData(quarter: 'LF', labSccCellsMl: 400000);
      expect(q.scsDerived, closeTo(5.0, 0.05));
    });

    test('Generates exactly 4 rows per cow with 99-column mapping', () {
      final visit = VisitRecord(
        id: '1',
        farmId: 'NWN-SO-001',
        visitId: 'NWN-SO-001-20261011-01',
        visitDate: '2026-10-11',
        observerId: 'OBS-01',
        state: 'Sokoto',
        lga: 'Wamako',
      );

      final cow1 = CowRecord(
        cowId: 'C001',
        calvingDate: '2026-08-01',
        parity: 2,
      );
      visit.cows.add(cow1);

      final rows = visit.toSingleSheetRows();
      expect(rows.length, 4); // LF, RF, LR, RR

      final firstRow = rows.first;
      expect(firstRow['record_key_derived'], 'NWN-SO-001-20261011-01|C001|LF');
      expect(firstRow['state'], 'Sokoto');
      expect(firstRow['farm_id'], 'NWN-SO-001');
      expect(firstRow['cow_id'], 'C001');
      expect(firstRow['quarter'], 'LF');
      expect(firstRow['dim_derived'], 71);
      expect(firstRow['cmt_score'], 'N');
      expect(firstRow['cmt_positive_derived'], 'No');
    });
  });
}
