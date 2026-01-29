import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../data/models/shopping_list.dart';
import '../widgets/shopping_list_card.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  bool _isLoading = false;
  List<ShoppingList> _lists = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    
    try {
      final repo = context.read<FavoritesRepository>();
      final lists = await repo.getShoppingLists();
      setState(() {
        _lists = lists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar listas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de Compras'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _lists.isEmpty
              ? EmptyState(
                  icon: Icons.list_alt,
                  title: 'Nenhuma Lista',
                  message: 'Crie listas para organizar suas compras',
                  actionText: 'Criar Lista',
                  onActionPressed: _showCreateListDialog,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lists.length,
                  itemBuilder: (context, index) {
                    final list = _lists[index];
                    return ShoppingListCard(
                      list: list,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShoppingListDetailScreen(
                              list: list,
                            ),
                          ),
                        );
                        _loadLists();
                      },
                      onDelete: () => _showDeleteDialog(list),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateListDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova Lista'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showCreateListDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nova Lista'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome da lista',
              hintText: 'Ex: Pedido Mensal',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite um nome para a lista')),
                  );
                  return;
                }
                
                Navigator.pop(dialogContext);
                
                try {
                  final repo = context.read<FavoritesRepository>();
                  await repo.createList(controller.text.trim());
                  await _loadLists();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lista criada com sucesso')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao criar lista: $e')),
                    );
                  }
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir Lista'),
          content: Text('Deseja excluir a lista "${list.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                try {
                  final repo = context.read<FavoritesRepository>();
                  await repo.deleteList(list.id);
                  await _loadLists();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lista excluída')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir lista: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Excluir',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}


