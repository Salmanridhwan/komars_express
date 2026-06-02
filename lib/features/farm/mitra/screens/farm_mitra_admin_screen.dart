import 'package:flutter/material.dart';
import 'package:komars_express/core/constants/app_colors.dart';
import 'package:komars_express/core/database/database_helper.dart';
import 'farm_mitra_form_screen.dart';
import '../models/mitra_model.dart';

/// Layar daftar mitra untuk Admin KomarFarm.
/// Menampilkan semua mitra yang bekerja sama beserta detail PT.
class FarmMitraAdminScreen extends StatefulWidget {
  final bool embedded;
  const FarmMitraAdminScreen({super.key, this.embedded = false});

  @override
  State<FarmMitraAdminScreen> createState() => _FarmMitraAdminScreenState();
}

class _FarmMitraAdminScreenState extends State<FarmMitraAdminScreen> {
  List<MitraPartnership> _mitras = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMitra();
  }

  Future<void> _loadMitra() async {
    setState(() => _loading = true);
    try {
      await DatabaseHelper.instance.database; // ensure init
      final dao = DatabaseHelper.instance.mitraDao;
      await dao.seedDefaultMitra();
      final list = await dao.getAll();
      if (mounted)
        setState(() {
          _mitras = list;
          _loading = false;
        });
    } catch (e) {
      debugPrint('Error loading mitra: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Mitra Kerja Sama',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmMitraFormScreen(),
                ),
              );
              if (result == true) _loadMitra();
            },
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Tambah Mitra',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Header Banner ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar perusahaan mitra yang bekerja sama\ndengan Komars Farm',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeaderBadge(
                      icon: Icons.handshake_rounded,
                      label: '${_mitras.length} Mitra',
                    ),
                    const SizedBox(width: 10),
                    _HeaderBadge(
                      icon: Icons.verified_rounded,
                      label: '${_mitras.where((m) => m.isActive).length} Aktif',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : _mitras.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadMitra,
                    color: AppColors.primaryGreen,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _mitras.length,
                      itemBuilder: (ctx, i) =>
                          _MitraCard(mitra: _mitras[i], onRefresh: _loadMitra),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada mitra terdaftar',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Badge ──────────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mitra Card ────────────────────────────────────────────────────────────────

class _MitraCard extends StatelessWidget {
  final MitraPartnership mitra;
  final VoidCallback onRefresh;
  const _MitraCard({required this.mitra, required this.onRefresh});

  IconData _resolveIcon(String? logoIcon) {
    switch (logoIcon) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'store':
        return Icons.store_rounded;
      case 'factory':
        return Icons.factory_rounded;
      default:
        return Icons.business_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: mitra.isActive
                ? AppColors.primaryGreen.withValues(alpha: 0.25)
                : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _resolveIcon(mitra.logoIcon),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mitra.mitraName,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: mitra.isActive
                                    ? AppColors.primaryGreenSurface
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                mitra.isActive ? 'Aktif' : 'Tidak Aktif',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: mitra.isActive
                                      ? AppColors.primaryGreenDark
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          mitra.companyName,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 12,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              mitra.category,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            // ── Footer ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.lightCard,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bergabung: ${mitra.joinedDate}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.alternate_email_rounded,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mitra.contact,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MitraDetailSheet(mitra: mitra, onRefresh: onRefresh),
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _MitraDetailSheet extends StatelessWidget {
  final MitraPartnership mitra;
  final VoidCallback onRefresh;
  const _MitraDetailSheet({required this.mitra, required this.onRefresh});

  Future<void> _deleteMitra(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mitra'),
        content: Text('Apakah Anda yakin ingin menghapus kerjasama dengan ${mitra.mitraName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.mitraDao.delete(mitra.id!);
        onRefresh();
        if (context.mounted) Navigator.pop(context); // close sheet
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (ctx, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mitra.mitraName,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          mitra.companyName,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        onTap: () async {
                          // Allow sheet to close or wait?
                          Future.delayed(Duration.zero, () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => FarmMitraFormScreen(mitra: mitra),
                              ),
                            );
                            if (result == true) {
                              onRefresh();
                              Navigator.pop(context); // close sheet
                            }
                          });
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Edit Data'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () => Future.delayed(Duration.zero, () => _deleteMitra(context)),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Hapus Mitra', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailItem(Icons.category_rounded, 'Kategori Bisnis', mitra.category),
              _detailItem(Icons.phone_rounded, 'Kontak Kerjasama', mitra.contact),
              _detailItem(Icons.calendar_month_rounded, 'Tanggal Bergabung', mitra.joinedDate),
              const Divider(height: 32),
              const Text(
                'Deskripsi & Lingkup Kerjasama',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mitra.description ?? 'Tidak ada deskripsi tambahan.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 18),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
