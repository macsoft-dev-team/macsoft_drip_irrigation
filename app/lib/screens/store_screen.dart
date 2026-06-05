import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_loading_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/status_chip.dart';
import 'support_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadProducts();
      context.read<AppState>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderListScreen()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              Consumer<AppState>(
                builder: (context, state, _) {
                  final cartCount = state.cart.values.fold(0, (sum, val) => sum + val);
                  if (cartCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              )
            ],
          )
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.productsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = [
            {'id': 'all', 'label': 'All Products'},
            {'id': 'masterController', 'label': 'Controllers'},
            {'id': 'valve', 'label': 'Valves'},
            {'id': 'accessory', 'label': 'Accessories'},
            {'id': 'servicePackages', 'label': 'Services'},
            {'id': 'spareParts', 'label': 'Spare Parts'},
          ];

          final filteredProducts = _selectedCategory == 'all'
              ? state.products
              : state.products.where((p) => p.type == _selectedCategory).toList();

          return Column(
            children: [
              // Categories tab bar
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final isSelected = _selectedCategory == cat['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['id']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2D7A3A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF546E7A),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Product grid list
              Expanded(
                child: filteredProducts.isEmpty
                    ? const EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No Products',
                        description: 'We could not find any products in this category.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, i) {
                          final prod = filteredProducts[i];
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(product: prod),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.settings_suggest_outlined, size: 40, color: Color(0xFF2D7A3A)),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      prod.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'SKU: ${prod.sku}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF8A958A)),
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${prod.price.toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF2D7A3A)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_shopping_cart, size: 18, color: Color(0xFF2D7A3A)),
                                          onPressed: () {
                                            state.addToCart(prod);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${prod.name} added to cart'),
                                                backgroundColor: const Color(0xFF2D7A3A),
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.settings_suggest, size: 80, color: Color(0xFF2D7A3A)),
            ),
            const SizedBox(height: 20),
            Text(
              product.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
            ),
            const SizedBox(height: 6),
            Text('SKU: ${product.sku} · Category: ${product.type.toUpperCase()}', style: const TextStyle(color: Color(0xFF8A958A), fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              '₹${product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D7A3A)),
            ),
            const Divider(height: 32, thickness: 0.8),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              product.description ?? 'No description details available for this product.',
              style: const TextStyle(color: Color(0xFF546E7A), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      state.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.name} added to cart'), backgroundColor: const Color(0xFF2D7A3A)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D7A3A),
                      side: const BorderSide(color: Color(0xFF2D7A3A)),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      state.addToCart(product);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                    child: const Text('Buy Now'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.cart.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart is Empty',
              description: 'Browse the store catalog and add devices to your shopping cart.',
              actionLabel: 'Shop Now',
              onAction: () => Navigator.pop(context),
            );
          }

          final cartItems = state.cart.entries.toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: cartItems.length,
                  itemBuilder: (context, i) {
                    final item = cartItems[i];
                    final prod = state.products.firstWhere((p) => p.id == item.key);
                    final quantity = item.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.settings_suggest, color: Color(0xFF2D7A3A)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('₹${prod.price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF2D7A3A), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () => state.updateCartQty(prod, quantity - 1),
                                ),
                                Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () => state.updateCartQty(prod, quantity + 1),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, -4))],
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: '₹${state.cartSubtotal.toStringAsFixed(2)}'),
                    _SummaryRow(label: 'Platform Fee', value: '₹${state.cartPlatformFee.toStringAsFixed(2)}'),
                    _SummaryRow(label: 'GST (18%)', value: '₹${state.cartTaxAmount.toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    _SummaryRow(label: 'Total Amount', value: '₹${state.cartTotalAmount.toStringAsFixed(2)}', isTotal: true),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                        );
                      },
                      child: const Text('Proceed to Checkout'),
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter delivery address.')));
      return;
    }

    setState(() => _isLoading = true);
    final ok = await context.read<AppState>().checkout();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Color(0xFF2D7A3A)),
      );
      // pop twice to go back to store page
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Farmer & Contact Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${state.user?.name ?? "Farmer"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Phone: ${state.user?.phone ?? "N/A"}'),
                    if (state.user?.email != null) Text('Email: ${state.user!.email}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            AppTextField(
              label: 'Address',
              hint: 'Enter your full delivery address',
              controller: _addressController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: '₹${state.cartSubtotal.toStringAsFixed(2)}'),
                    _SummaryRow(label: 'Platform Fee', value: '₹${state.cartPlatformFee.toStringAsFixed(2)}'),
                    _SummaryRow(label: 'GST (18%)', value: '₹${state.cartTaxAmount.toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    _SummaryRow(label: 'Total Amount', value: '₹${state.cartTotalAmount.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            AppLoadingButton(
              label: 'Place Order',
              isLoading: _isLoading,
              onPressed: _placeOrder,
              color: const Color(0xFF2D7A3A),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.ordersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No Orders Yet',
              description: 'You have not placed any orders yet. Check out the store to purchase items.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: state.orders.length,
            itemBuilder: (context, i) {
              final Order ord = state.orders[i];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailScreen(orderId: ord.id),
                      ),
                    );
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ord.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                      StatusChip(status: ord.orderStatus),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Total: ₹${ord.totalAmount.toStringAsFixed(0)} · Date: ${ord.createdAt.toLocal().toString().substring(0, 10)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A)),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCBD5E1)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ordIdx = state.orders.indexWhere((o) => o.id == orderId);
    if (ordIdx == -1) return const Scaffold(body: Center(child: Text('Order not found')));
    final Order ord = state.orders[ordIdx];

    return Scaffold(
      appBar: AppBar(
        title: Text(ord.orderNumber),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                StatusChip(status: ord.orderStatus),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _SpecRow(label: 'Order Date', value: ord.createdAt.toLocal().toString().substring(0, 16)),
                    _SpecRow(label: 'Payment Status', value: ord.paymentStatus.toUpperCase()),
                    _SpecRow(label: 'Shipping Status', value: ord.orderStatus.toUpperCase()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ord.items.length,
              itemBuilder: (context, i) {
                final item = ord.items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Qty: ${item.quantity} · Price: ₹${item.unitPrice.toStringAsFixed(0)}'),
                    trailing: Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: '₹${ord.subtotal.toStringAsFixed(2)}'),
                    _SummaryRow(label: 'Platform Fee', value: '₹${ord.platformFee.toStringAsFixed(2)}'),
                    _SummaryRow(label: 'GST (18%)', value: '₹${ord.taxAmount.toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    _SummaryRow(label: 'Total Paid', value: '₹${ord.totalAmount.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice download placeholder triggered.')),
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download Invoice'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SupportTicketFormScreen(
                      initialTitle: 'Installation assistance for Order ${ord.orderNumber}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.construction_rounded),
              label: const Text('Request Installation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D7A3A),
                side: const BorderSide(color: Color(0xFF2D7A3A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF1E2A1F) : const Color(0xFF8A958A),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
              color: isTotal ? const Color(0xFF2D7A3A) : const Color(0xFF1E2A1F),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F))),
        ],
      ),
    );
  }
}
