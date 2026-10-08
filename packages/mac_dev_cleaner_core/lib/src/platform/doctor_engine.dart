import '../doctor/doctor_service.dart';
import '../scanner/scan_log.dart';

/// Host-specific environment checks before scan/clean.
abstract class DoctorEngine {
  Future<List<DoctorIssue>> runAll({ScanProgressCallback? onProgress});
}
