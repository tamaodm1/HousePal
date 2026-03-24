import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class BulletinScreen extends StatefulWidget {
  const BulletinScreen({super.key});

  @override
  State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data từ Firebase
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> shoppingList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final houseId = await AuthService.getFirebaseHouseId();
      if (houseId == null || houseId.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Chưa tham gia phòng nào';
        });
        return;
      }

      final notesData = await FirestoreService.getNotesByHouse(houseId);
      final shoppingData =
          await FirestoreService.getShoppingItemsByHouse(houseId);

      setState(() {
        notes = notesData;
        shoppingList = shoppingData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Bảng tin chung',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              color: AppColors.textWhite,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textWhite,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textWhite,
          indicatorWeight: 3,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.6),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Ghi chú'),
            Tab(text: 'Danh sách mua'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lỗi: $errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotesTab(),
                    _buildShoppingTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddNoteDialog();
          } else {
            _showAddItemDialog();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.textWhite),
        label: Text(
          _tabController.index == 0 ? 'Thêm ghi chú' : 'Thêm món',
          style: const TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    final pinnedNotes =
        notes.where((note) => note['isPinned'] == true).toList();
    final regularNotes =
        notes.where((note) => note['isPinned'] != true).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pinnedNotes.isNotEmpty) ...[
          const Row(
            children: [
              Icon(
                Icons.push_pin,
                size: 20,
                color: AppColors.warning,
              ),
              SizedBox(width: 8),
              Text(
                'Ghim',
                style: AppTextStyles.h4,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pinnedNotes.map((note) => _buildNoteCardFromMap(note, true)),
          const SizedBox(height: 24),
        ],
        if (regularNotes.isNotEmpty) ...[
          const Text(
            'Ghi chú khác',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 12),
          ...regularNotes.map((note) => _buildNoteCardFromMap(note, false)),
        ],
        if (notes.isEmpty)
          _buildEmptyState(
            icon: Icons.note_outlined,
            title: 'Chưa có ghi chú nào',
            subtitle: 'Thêm ghi chú quan trọng cho nhà',
          ),
      ],
    );
  }

  Widget _buildShoppingTab() {
    final pendingItems =
        shoppingList.where((item) => item['isPurchased'] != true).toList();
    final purchasedItems =
        shoppingList.where((item) => item['isPurchased'] == true).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.info, Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: AppColors.textWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cần mua',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pendingItems.length} món',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (pendingItems.isNotEmpty) ...[
          const Text(
            'Chưa mua',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 12),
          ...pendingItems.map((item) => _buildShoppingItemCardFromMap(item)),
          const SizedBox(height: 24),
        ],
        if (purchasedItems.isNotEmpty) ...[
          Text(
            'Đã mua',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...purchasedItems.map((item) => _buildShoppingItemCardFromMap(item)),
        ],
        if (shoppingList.isEmpty)
          _buildEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Chưa có món nào',
            subtitle: 'Thêm những thứ cần mua cho nhà',
          ),
      ],
    );
  }

  Widget _buildNoteCard(BulletinNote note, bool isPinned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: isPinned
            ? Border.all(color: AppColors.warning.withOpacity(0.3), width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showNoteDetail(note);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isPinned) ...[
                      const Icon(
                        Icons.push_pin,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        note.title,
                        style: AppTextStyles.h4.copyWith(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showNoteOptions(note),
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.content,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: note.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép!'),
                            duration: Duration(seconds: 2),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        (note.createdByName ?? '').isNotEmpty
                            ? (note.createdByName![0]).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      note.createdByName ?? 'Unknown',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(note.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingItemCard(ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.isPurchased,
            onChanged: (value) {
              setState(() {
                // Toggle purchased state
              });
            },
            activeColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    decoration:
                        item.isPurchased ? TextDecoration.lineThrough : null,
                    color: item.isPurchased
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.isPurchased
                      ? '${item.purchasedByName} đã mua'
                      : '${item.addedByName} đã thêm',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (!item.isPurchased)
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteCardFromMap(Map<String, dynamic> note, bool isPinned) {
    final title = note['title'] ?? '';
    final content = note['content'] ?? '';
    final createdByName = note['createdByName'] ?? 'Unknown';
    final createdAt = note['createdAt'] is DateTime
        ? note['createdAt'] as DateTime
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: isPinned
            ? Border.all(color: AppColors.warning.withOpacity(0.3), width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoteDetailFromMap(note),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isPinned) ...[
                      const Icon(
                        Icons.push_pin,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.h4.copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        createdByName.isNotEmpty
                            ? createdByName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      createdByName,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteDetailFromMap(Map<String, dynamic> note) {
    final title = (note['title'] ?? 'Ghi chú').toString();
    final content = (note['content'] ?? '').toString();
    final author = (note['createdByName'] ?? 'Unknown').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: AppTextStyles.h3)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              Text('Bởi: $author', style: AppTextStyles.caption),
              const SizedBox(height: 12),
              Text(content, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingItemCardFromMap(Map<String, dynamic> item) {
    final itemId = item['id'] as String?;
    final name = item['name'] ?? '';
    final isPurchased = item['isPurchased'] == true;
    final addedByName = item['addedByName'] ?? '';
    final purchasedByName = item['purchasedByName'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: isPurchased,
            onChanged: (value) async {
              if (itemId == null) return;
              try {
                final userName = await AuthService.getCurrentUserName();
                await FirestoreService.updateShoppingItem(itemId, {
                  'isPurchased': value ?? false,
                  'purchasedByName': value == true ? userName : null,
                });
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            activeColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    decoration: isPurchased ? TextDecoration.lineThrough : null,
                    color: isPurchased
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPurchased
                      ? '$purchasedByName đã mua'
                      : '$addedByName đã thêm',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (!isPurchased)
            IconButton(
              onPressed: () async {
                if (itemId == null) return;
                try {
                  await FirestoreService.deleteShoppingItem(itemId);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hôm nay';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showNoteOptions(BulletinNote note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa ghi chú',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteNote(note.id.toString());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirestoreService.deleteNote(noteId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ghi chú đã xóa')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showNoteDetail(BulletinNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: AppTextStyles.h3,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.content,
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            (note.createdByName ?? '').isNotEmpty
                                ? (note.createdByName![0]).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.createdByName ?? 'Unknown',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(note.createdAt),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isPinned = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Thêm ghi chú mới',
                              style: AppTextStyles.h3),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tiêu đề
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề *',
                          hintText: 'Ví dụ: Nhắc nhở quan trọng',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nội dung
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Nội dung *',
                          hintText: 'Ghi chú chi tiết...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ghim
                      CheckboxListTile(
                        value: isPinned,
                        onChanged: (v) =>
                            setModalState(() => isPinned = v ?? false),
                        title: const Text('Ghim ghi chú'),
                        subtitle:
                            const Text('Ghi chú quan trọng sẽ hiện lên đầu'),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.warning,
                      ),
                      const SizedBox(height: 20),

                      CustomButton(
                        text: 'Thêm ghi chú',
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty ||
                              contentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Vui lòng nhập đủ tiêu đề và nội dung')),
                            );
                            return;
                          }

                          try {
                            final houseId =
                                await AuthService.getFirebaseHouseId();
                            final userId =
                                await AuthService.getFirebaseUserId();
                            final userName =
                                await AuthService.getCurrentUserName();

                            if (houseId == null || houseId.isEmpty) {
                              throw Exception('Chưa tham gia phòng nào');
                            }

                            await FirestoreService.createNote({
                              'houseId': houseId,
                              'userId': userId,
                              'title': titleController.text.trim(),
                              'content': contentController.text.trim(),
                              'createdByName': userName ?? 'Unknown',
                              'isPinned': isPinned,
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Đã thêm ghi chú!')),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thêm món mua', style: AppTextStyles.h3),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tên món
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên món *',
                      hintText: 'Ví dụ: Sữa, Bánh mì',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.shopping_basket),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Số lượng
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'Thêm món',
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Vui lòng nhập tên món')),
                        );
                        return;
                      }

                      try {
                        final houseId = await AuthService.getFirebaseHouseId();
                        final userId = await AuthService.getFirebaseUserId();
                        final userName = await AuthService.getCurrentUserName();

                        if (houseId == null || houseId.isEmpty) {
                          throw Exception('Chưa tham gia phòng nào');
                        }

                        await FirestoreService.createShoppingItem({
                          'houseId': houseId,
                          'name': nameController.text.trim(),
                          'quantity':
                              int.tryParse(quantityController.text) ?? 1,
                          'addedByUserId': userId,
                          'addedByName': userName ?? 'Unknown',
                          'isPurchased': false,
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã thêm món!')),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
