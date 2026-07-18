import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../screens/splash_screen.dart';

class EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onSaved;

  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.onSaved,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController name;
  late TextEditingController email;
  late TextEditingController phone;
  late TextEditingController address;
  late TextEditingController birthDate;

  late TextEditingController allergies;
  late TextEditingController medicalHistory;

  late TextEditingController emergencyName;
  late TextEditingController emergencyPhone;

  String? gender;
  String? bloodGroup;

  bool saving = false;

  final genders = const ['Homme', 'Femme'];
  final bloodGroups = const [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();

    final user = widget.profile['user'] ?? {};
    final patient = widget.profile['patient'] ?? {};

    name = TextEditingController(text: user['name'] ?? '');
    email = TextEditingController(text: user['email'] ?? '');
    phone = TextEditingController(text: patient['phone'] ?? '');
    address = TextEditingController(text: patient['address'] ?? '');
    birthDate = TextEditingController(text: patient['birth_date'] ?? '');

    allergies = TextEditingController(text: patient['allergies'] ?? '');
    medicalHistory =
        TextEditingController(text: patient['medical_history'] ?? '');

    emergencyName =
        TextEditingController(text: patient['emergency_contact_name'] ?? '');
    emergencyPhone =
        TextEditingController(text: patient['emergency_contact_phone'] ?? '');

    gender = patient['gender'];
    bloodGroup = patient['blood_group'];
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    birthDate.dispose();
    allergies.dispose();
    medicalHistory.dispose();
    emergencyName.dispose();
    emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial;
    try {
      initial = birthDate.text.isEmpty
          ? DateTime(2000, 1, 1)
          : DateTime.parse(birthDate.text);
    } catch (_) {
      initial = DateTime(2000, 1, 1);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: MediQueueTheme.primary,
            onPrimary: Colors.white,
            surface: MediQueueTheme.surface,
            onSurface: MediQueueTheme.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: MediQueueTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MediQueueTheme.radiusLg),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: MediQueueTheme.surface,
            headerBackgroundColor: MediQueueTheme.primarySurface,
            headerForegroundColor: MediQueueTheme.primary,
            todayBorder: BorderSide(color: MediQueueTheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MediQueueTheme.radiusLg),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: MediQueueTheme.primary,
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        birthDate.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return 'Sélectionner une date';
    try {
      final d = DateTime.parse(raw);
      const months = [
        'jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin',
        'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expirée")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await ApiService.updateProfile(auth.token!, {
        "name": name.text,
        "email": email.text,
        "phone": phone.text,
        "address": address.text,
        "birth_date": birthDate.text,
        "gender": gender,
        "blood_group": bloodGroup,
        "allergies": allergies.text,
        "medical_history": medicalHistory.text,
        "emergency_contact_name": emergencyName.text,
        "emergency_contact_phone": emergencyPhone.text,
      });

      if (!mounted) return;

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la mise à jour"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: MediQueueTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MediQueueTheme.radiusLg),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22, 12, 22,
          MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            _header(),
            const SizedBox(height: 24),

            _label("Informations générales"),
            const SizedBox(height: 12),
            _field(name, "Nom complet", Icons.person_outline),
            const SizedBox(height: 12),
            _field(email, "Email", Icons.mail_outline,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(phone, "Téléphone", Icons.phone_outlined,
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _field(address, "Adresse", Icons.location_on_outlined),
            const SizedBox(height: 12),
            _dateField(),
            const SizedBox(height: 12),
            _genderSelector(),

            const SizedBox(height: 24),
            _label("Données médicales"),
            const SizedBox(height: 12),
            _bloodGroupSelector(),
            const SizedBox(height: 12),
            _field(allergies, "Allergies", Icons.warning_amber_outlined),
            const SizedBox(height: 12),
            _field(medicalHistory, "Antécédents médicaux",
                Icons.medical_services_outlined, maxLines: 3),

            const SizedBox(height: 24),
            _label("Contact d'urgence"),
            const SizedBox(height: 12),
            _field(emergencyName, "Nom du contact", Icons.person_pin_outlined),
            const SizedBox(height: 12),
            _field(emergencyPhone, "Téléphone du contact",
                Icons.phone_in_talk_outlined,
                keyboard: TextInputType.phone),

            const SizedBox(height: 28),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  // ── Pieces ────────────────────────────────

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 22),
          decoration: BoxDecoration(
            color: MediQueueTheme.divider,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _header() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MediQueueTheme.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MediQueueTheme.divider),
            ),
            child: const Icon(Icons.edit_outlined,
                color: MediQueueTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Modifier le profil",
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MediQueueTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: MediQueueTheme.textHint),
          ),
        ],
      );

  Widget _label(String text) => Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: MediQueueTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MediQueueTheme.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        color: MediQueueTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: MediQueueTheme.textSecondary,
        ),
        prefixIcon: Icon(icon, size: 19, color: MediQueueTheme.textHint),
        filled: true,
        fillColor: MediQueueTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          borderSide: BorderSide(color: MediQueueTheme.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          borderSide: BorderSide(color: MediQueueTheme.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          borderSide: BorderSide(color: MediQueueTheme.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: MediQueueTheme.background,
          borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          border: Border.all(color: MediQueueTheme.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 19, color: MediQueueTheme.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatDate(birthDate.text),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: birthDate.text.isEmpty
                      ? MediQueueTheme.textHint
                      : MediQueueTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.calendar_today_rounded,
                size: 16, color: MediQueueTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _genderSelector() {
    return Wrap(
      spacing: 8,
      children: genders.map((g) {
        final selected = gender == g;
        return ChoiceChip(
          label: Text(
            g,
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : MediQueueTheme.textPrimary,
            ),
          ),
          selected: selected,
          onSelected: (_) => setState(() => gender = g),
          selectedColor: MediQueueTheme.primary,
          backgroundColor: MediQueueTheme.background,
          side: BorderSide(
            color: selected ? MediQueueTheme.primary : MediQueueTheme.divider,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
  }

  Widget _bloodGroupSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bloodGroups.map((b) {
        final selected = bloodGroup == b;
        return GestureDetector(
          onTap: () => setState(() => bloodGroup = b),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? MediQueueTheme.primary : MediQueueTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? MediQueueTheme.primary : MediQueueTheme.divider,
              ),
            ),
            child: Text(
              b,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : MediQueueTheme.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: MediQueueTheme.primary,
          disabledBackgroundColor: MediQueueTheme.primary.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MediQueueTheme.radiusMd),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                "Enregistrer les modifications",
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}