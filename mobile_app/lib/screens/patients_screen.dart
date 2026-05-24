// ============ FILE: mobile_app/lib/screens/patients_screen.dart ============
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../services/patient_service.dart';
import '../services/prescription_service.dart';
import '../widgets/patient_card.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final PatientService _patientService = PatientService();
  List<Patient> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      _patients = await _patientService.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showPatientDetail(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PatientDetailView(patient: patient)),
    );
  }

  Future<void> _openAddPatient() async {
    final created = await showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddPatientSheet(),
    );

    if (created != null) {
      setState(() => _patients.insert(0, created));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadPatients,
      color: AppTheme.primary,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 56, color: AppTheme.textMuted.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      const Text('Belum ada data lansia', style: TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      const Text('Tambahkan data lansia dari aplikasi', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _openAddPatient,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Lansia'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _patients.length + 1, // +1 for header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Data Lansia',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Tambah Lansia',
                                  onPressed: _openAddPatient,
                                  icon: const Icon(Icons.add, color: AppTheme.primary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_patients.length} pasien',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    final patient = _patients[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PatientCard(
                        patient: patient,
                        onTap: () => _showPatientDetail(patient),
                      ),
                    );
                  },
                ),
    );
  }
}

// ── Add Patient Sheet ─────────────────────────────────────────────
class _AddPatientSheet extends StatefulWidget {
  const _AddPatientSheet();

  @override
  State<_AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends State<_AddPatientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _gender = 'male';
  String _bloodType = '';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final patient = await PatientService().create(
        name: _nameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        gender: _gender,
        address: _addressController.text.trim(),
        bloodType: _bloodType,
        medicalNotes: _notesController.text.trim(),
      );
      if (mounted) Navigator.pop(context, patient);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambah pasien: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tambah Lansia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Nama minimal 2 karakter' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(labelText: 'Tanggal Lahir (YYYY-MM-DD)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Tanggal lahir wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'female', child: Text('Perempuan')),
                ],
                onChanged: _saving ? null : (v) => setState(() => _gender = v ?? 'male'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bloodType,
                decoration: const InputDecoration(labelText: 'Golongan Darah (opsional)'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tidak ada')),
                  DropdownMenuItem(value: 'A', child: Text('A')),
                  DropdownMenuItem(value: 'B', child: Text('B')),
                  DropdownMenuItem(value: 'AB', child: Text('AB')),
                  DropdownMenuItem(value: 'O', child: Text('O')),
                ],
                onChanged: _saving ? null : (v) => setState(() => _bloodType = v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Catatan Medis (opsional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Patient Detail View ─────────────────────────────────────────────
class _PatientDetailView extends StatefulWidget {
  final Patient patient;
  const _PatientDetailView({required this.patient});

  @override
  State<_PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<_PatientDetailView> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  List<Prescription> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    try {
      _prescriptions = await _prescriptionService.getByPatient(widget.patient.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientMedical,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        p.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          p.genderLabel,
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                        ),
                        if (p.address != null)
                          Text(
                            p.address!,
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Medical Notes
            if (p.medicalNotes != null && p.medicalNotes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, size: 18, color: AppTheme.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Catatan Medis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warning)),
                          const SizedBox(height: 2),
                          Text(p.medicalNotes!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Prescriptions
            const Text(
              'Resep Obat',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),

            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primary)))
            else if (_prescriptions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 36, color: AppTheme.textMuted),
                      SizedBox(height: 8),
                      Text('Belum ada resep', style: TextStyle(color: AppTheme.textMuted)),
                      Text('Resep ditambahkan oleh admin/dokter via web', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              )
            else
              ..._prescriptions.map((rx) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: rx.isActive ? AppTheme.primary.withOpacity(0.3) : AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: rx.isActive ? AppTheme.primary.withOpacity(0.1) : AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.medication,
                            color: rx.isActive ? AppTheme.primary : AppTheme.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rx.medicationName ?? 'Obat',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              Text(
                                '${rx.dosage} · ${rx.frequency}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              if (rx.doctorName != null)
                                Text(
                                  'Dr. ${rx.doctorName}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: rx.isActive ? AppTheme.success.withOpacity(0.1) : AppTheme.textMuted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rx.isActive ? 'Aktif' : 'Selesai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: rx.isActive ? AppTheme.success : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
