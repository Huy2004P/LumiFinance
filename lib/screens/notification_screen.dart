import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/apple_design.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Hàm đánh dấu đã đọc khi người dùng nhấn vào hoặc vào xem
  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  // Hàm xoá thông báo
  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray, // Nền xám nhạt Apple
      appBar: AppBar(
        backgroundColor: AppleColors.lightGray,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppleColors.nearBlack,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Thông báo",
          style: AppleTextStyles.displayHero.copyWith(
            fontSize: 26,
          ), // Style hầm hố
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Lắng nghe liên tục từ Firestore
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where(
              'uid',
              isEqualTo: currentUserId,
            ) // Sử dụng isEqualTo thay cho '=='
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitThreeBounce(color: Color(0xFF1459B3), size: 30),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return _buildNotificationItem(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(String id, Map<String, dynamic> data) {
    bool isRead = data['isRead'] ?? false;
    bool isDanger = data['type'] == 'danger'; // Cảnh báo vượt hạn mức

    // Format thời gian
    String timeStr = "";
    if (data['createdAt'] != null) {
      DateTime dt = (data['createdAt'] as Timestamp).toDate();
      timeStr = DateFormat('HH:mm - dd/MM').format(dt);
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () => _markAsRead(id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppleColors.pureWhite,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            // Thanh màu xanh LumiCare bên cạnh nếu chưa đọc
            border: isRead
                ? null
                : const Border(
                    left: BorderSide(color: Color(0xFF1459B3), width: 5),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon biểu thị mức độ cảnh báo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDanger ? Colors.red : const Color(0xFF1C7AD6))
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDanger
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_none_rounded,
                  color: isDanger ? Colors.red : const Color(0xFF1C7AD6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['title'] ?? "Thông báo",
                          style: AppleTextStyles.body.copyWith(
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['message'] ?? "",
                      style: TextStyle(
                        color: isRead ? Colors.black38 : Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Colors.black26,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 15),
          Text(
            "Hộp thư trống rỗng",
            style: AppleTextStyles.body.copyWith(color: Colors.black26),
          ),
        ],
      ),
    );
  }
}
