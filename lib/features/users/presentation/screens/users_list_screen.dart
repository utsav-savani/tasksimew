import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/user_list_item.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().loadUsers();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<UsersProvider>().loadMoreUsers();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<UsersProvider>().refreshUsers();
  }

  void _onSearch(String query) {
    context.read<UsersProvider>().searchUsers(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.meeting_room),
            tooltip: 'Join Meeting by ID',
            onPressed: () {
              Navigator.pushNamed(context, RouteConstants.meetingJoin);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, RouteConstants.login);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<UsersProvider>().clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),

          // Users List
          Expanded(
            child: Consumer<UsersProvider>(
              builder: (context, usersProvider, child) {
                if (usersProvider.status == UsersStatus.loading &&
                    usersProvider.users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (usersProvider.status == UsersStatus.error &&
                    usersProvider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          usersProvider.errorMessage ?? 'An error occurred',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (usersProvider.users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          usersProvider.searchQuery.isEmpty
                              ? 'No users found'
                              : 'No users match your search',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: usersProvider.users.length +
                        (usersProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == usersProvider.users.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final user = usersProvider.users[index];
                      return UserListItem(
                        user: user,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteConstants.videoCall,
                            arguments: user,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
