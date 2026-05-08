import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../models/models.dart';
import '../services/community_service.dart';
import '../theme/glass_widgets.dart';
import '../widgets/responsive.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isPublic = true;
  bool _requiresSubscription = false;
  bool _generateInvite = true;
  bool _isSubmitting = false;
  bool _isSearching = false;

  int? _maxUses;
  int? _expiresInDays;

  final List<User> _searchResults = [];
  final List<User> _selectedUsers = [];
  final Set<String> _selectedUserIds = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer au moins 2 caracteres'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);
    final results = await CommunityService.instance.searchUsers(
      query: query,
      limit: 10,
    );
    if (!mounted) return;
    setState(() {
      _searchResults
        ..clear()
        ..addAll(results);
      _isSearching = false;
    });
  }

  void _toggleUser(User user) {
    if (_selectedUserIds.contains(user.id)) {
      _selectedUserIds.remove(user.id);
      _selectedUsers.removeWhere((u) => u.id == user.id);
    } else {
      _selectedUserIds.add(user.id);
      _selectedUsers.add(user);
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final group = await CommunityService.instance.createGroup(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      isPublic: _isPublic,
      requiresSubscription: _requiresSubscription,
    );

    if (!mounted) return;

    if (group == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la creation du groupe'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    int addedCount = 0;
    for (final user in _selectedUsers) {
      final added = await CommunityService.instance.addMember(
        groupId: group.id,
        userId: user.id,
      );
      if (added) addedCount += 1;
    }

    Map<String, dynamic>? invite;
    if (_generateInvite) {
      invite = await CommunityService.instance.createInvite(
        groupId: group.id,
        expiresInDays: _expiresInDays,
        maxUses: _maxUses,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount membre(s) ajoute(s)'),
          backgroundColor: AppColors.successColor,
        ),
      );
    }

    if (invite != null) {
      final link = (invite['inviteUrl'] as String?) ?? '';
      final token = (invite['token'] as String?) ?? '';
      final displayValue = link.isNotEmpty ? link : token;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Lien d\'invitation'),
            content: SelectableText(
              displayValue.isNotEmpty
                  ? displayValue
                  : 'Lien indisponible, utilisez le code.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (displayValue.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: displayValue));
                  }
                  Navigator.pop(context);
                },
                child: const Text('Copier'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.headline3,
    );
  }

  Widget _userRow(User user) {
    final isSelected = _selectedUserIds.contains(user.id);
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.beigeLight,
        backgroundImage:
            user.avatarFullUrl.isNotEmpty ? NetworkImage(user.avatarFullUrl) : null,
        child: user.avatarFullUrl.isEmpty
            ? Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
      title: Text(
        user.fullName.isNotEmpty ? user.fullName : user.username,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: Text(
        user.username,
        style: AppTextStyles.bodySmall,
      ),
      trailing: Icon(
        isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline,
        color: isSelected ? AppColors.successColor : AppColors.primary,
      ),
      onTap: () => _toggleUser(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sidePadding = Responsive.sidePadding(context, maxWidth: 720);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Nouveau groupe', style: AppTextStyles.headline2),
                    const Spacer(),
                    GlassButton(
                      label: 'Creer',
                      isLoading: _isSubmitting,
                      width: 110,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeSlideIn(
                          child: _sectionTitle('Infos du groupe'),
                        ),
                        const SizedBox(height: 10),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: GlassCard(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Nom du groupe',
                                    border: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().length < 3) {
                                      return 'Le nom doit contenir au moins 3 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const Divider(height: 1),
                                TextFormField(
                                  controller: _descController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Description (optionnel)',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: _sectionTitle('Visibilite'),
                        ),
                        const SizedBox(height: 10),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: GlassCard(
                            child: Column(
                              children: [
                                SwitchListTile(
                                  value: _isPublic,
                                  onChanged: (v) => setState(() => _isPublic = v),
                                  title: const Text('Groupe public'),
                                  subtitle: const Text('Visible dans la liste des communautes'),
                                  activeColor: AppColors.primary,
                                ),
                                const Divider(height: 1),
                                SwitchListTile(
                                  value: _requiresSubscription,
                                  onChanged: (v) => setState(() => _requiresSubscription = v),
                                  title: const Text('Souscription requise'),
                                  subtitle: const Text('Rejoindre exige une souscription active'),
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 250),
                          child: _sectionTitle('Ajouter des membres'),
                        ),
                        const SizedBox(height: 10),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: const InputDecoration(
                                          hintText: 'Rechercher par nom ou email',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _isSearching ? null : _searchUsers,
                                      icon: _isSearching
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : const Icon(Icons.search_rounded),
                                    ),
                                  ],
                                ),
                                if (_selectedUsers.isNotEmpty) ...[
                                  const Divider(height: 1),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedUsers
                                        .map(
                                          (u) => Chip(
                                            label: Text(
                                              u.fullName.isNotEmpty
                                                  ? u.fullName
                                                  : u.username,
                                            ),
                                            deleteIcon: const Icon(Icons.close_rounded),
                                            onDeleted: () => _toggleUser(u),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                                if (_searchResults.isNotEmpty) ...[
                                  const Divider(height: 1),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _searchResults.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      return _userRow(_searchResults[index]);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 350),
                          child: _sectionTitle('Lien d\'invitation'),
                        ),
                        const SizedBox(height: 10),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 400),
                          child: GlassCard(
                            child: Column(
                              children: [
                                SwitchListTile(
                                  value: _generateInvite,
                                  onChanged: (v) => setState(() => _generateInvite = v),
                                  title: const Text('Generer un lien d\'invitation'),
                                  subtitle: const Text('Partagez un lien pour ajouter des membres'),
                                  activeColor: AppColors.primary,
                                ),
                                if (_generateInvite) ...[
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 12,
                                    ),
                                    child: Column(
                                      children: [
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'Nombre d\'utilisations (optionnel)',
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (value) {
                                            final parsed = int.tryParse(value.trim());
                                            _maxUses = parsed;
                                          },
                                        ),
                                        const Divider(height: 1),
                                        TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'Expiration en jours (optionnel)',
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (value) {
                                            final parsed = int.tryParse(value.trim());
                                            _expiresInDays = parsed;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
