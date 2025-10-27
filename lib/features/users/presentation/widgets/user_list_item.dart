import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/user_list_entity.dart';

class UserListItem extends StatelessWidget {
  final UserListEntity user;
  final VoidCallback onTap;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              backgroundImage: user.avatar != null
                  ? CachedNetworkImageProvider(user.avatar!)
                  : null,
              child: user.avatar == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            if (user.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                user.phoneNumber!,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
            if (!user.isOnline && user.lastSeen != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last seen: ${_formatLastSeen(user.lastSeen!)}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.video_call),
          color: Theme.of(context).primaryColor,
          iconSize: 32,
          onPressed: onTap,
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 7) {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
