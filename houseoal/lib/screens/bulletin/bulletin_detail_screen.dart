import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class BulletinDetailScreen extends StatefulWidget {
  const BulletinDetailScreen({super.key});

  @override
  State<BulletinDetailScreen> createState() => _BulletinDetailScreenState();
}

class _BulletinDetailScreenState extends State<BulletinDetailScreen> {
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> shoppingItems = [];
  Map<String, dynamic>? houseData;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      
      currentUserId = await AuthService.getFirebaseUserId();
      final houseId = await AuthService.getFirebaseHouseId();
      
      if (houseId == null || houseId.isEmpty) {
        setState(() => isLoading = false);
        return;
      }
      
      final notesData = await FirestoreService.getNotesByHouse(houseId);
      final shoppingData = await FirestoreService.getShoppingItemsByHouse(houseId);
      final house = await FirestoreService.getHouseById(houseId);
      
      setState(() {
        notes = notesData;
        shoppingItems = shoppingData;
        houseData = house;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép!'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wifiPassword = houseData?['wifiPassword'] ?? '---';
    final landlordPhone = houseData?['landlordPhone'] ?? '---';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Green Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.black),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _loadData,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.refresh, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bảng tin chung',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thông tin & danh sách mua sắm',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  // Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          icon: Icons.wifi_rounded,
                          title: 'WIFI password',
                          info: wifiPassword,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          icon: Icons.phone_rounded,
                          title: 'Chủ nhà',
                          info: landlordPhone,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Ghi chú section
                        Row(
                          children: [
                            const Icon(Icons.push_pin_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Ghi chú', style: AppTextStyles.h4.copyWith(fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${notes.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.pushNamed(context, '/add-note');
                                if (result == true) _loadData();
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (notes.isEmpty)
                          _buildEmptyState(Icons.note_outlined, 'Chưa có ghi chú nào')
                        else
                          ...notes.map((note) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildNoteCard(note),
                          )),
                        
                        const SizedBox(height: 24),
                        
                        // Shopping list section
                        Row(
                          children: [
                            const Icon(Icons.shopping_cart_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Danh sách mua sắm', style: AppTextStyles.h4.copyWith(fontSize: 16)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${shoppingItems.where((i) => i['isPurchased'] != true).length}', 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.pushNamed(context, '/add-shopping-item');
                                if (result == true) _loadData();
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (shoppingItems.isEmpty)
                          _buildEmptyState(Icons.shopping_cart_outlined, 'Chưa có món nào cần mua')
                        else
                          ...shoppingItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildShoppingItem(item),
                          )),
                        
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String info,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
              GestureDetector(
                onTap: () => _copyToClipboard(context, info),
                child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final title = note['title'] ?? 'Ghi chú';
    final content = note['content'] ?? '';
    final authorName = note['authorName'] ?? 'Unknown';
    final isPinned = note['isPinned'] == true;
    final noteId = note['id'] as String?;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPinned ? AppColors.warning : const Color(0xFFE0E0E0),
          width: isPinned ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPinned) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.push_pin, size: 12, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text('Ghim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (noteId != null)
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteNote(noteId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(content, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : '?', 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text(authorName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Item';
    final addedByName = item['addedByName'] ?? 'Unknown';
    final isPurchased = item['isPurchased'] == true;
    final itemId = item['id'] as String?;
    final priority = item['priority'] ?? 'normal';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPurchased ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isPurchased,
            onChanged: itemId != null ? (value) => _togglePurchased(itemId, value ?? false) : null,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isPurchased ? TextDecoration.lineThrough : null,
                          color: isPurchased ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    if (priority == 'high' && !isPurchased)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Cần gấp', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isPurchased ? '✓ Đã mua • $addedByName' : 'Thêm bởi: $addedByName',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (itemId != null)
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _deleteShoppingItem(itemId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: const Text('Bạn có chắc muốn xóa ghi chú này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await FirestoreService.deleteNote(noteId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa ghi chú')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  Future<void> _deleteShoppingItem(String itemId) async {
    try {
      await FirestoreService.deleteShoppingItem(itemId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _togglePurchased(String itemId, bool isPurchased) async {
    try {
      await FirestoreService.updateShoppingItem(itemId, {'isPurchased': isPurchased});
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}
