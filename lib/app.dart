// ประกอบ provider ธีม และเส้นทางหน้าจอของแอป
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'models/book_model.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/edit_profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_room_screen.dart';
import 'screens/customer/book_detail/book_detail_screen.dart';
import 'screens/customer/book_list/book_list_screen.dart';
import 'screens/customer/cart/cart_screen.dart';
import 'screens/customer/checkout/checkout_screen.dart';
import 'screens/customer/order_history/order_history_screen.dart';
import 'screens/owner/book_manage/book_manage_form_screen.dart';
import 'screens/owner/book_manage/book_manage_list_screen.dart';
import 'screens/owner/coupon_manage/coupon_manage_screen.dart';
import 'screens/owner/dashboard/dashboard_screen.dart';
import 'screens/owner/order_manage/order_manage_screen.dart';
import 'screens/profile/profile_screen.dart';

class MainApp extends StatelessWidget {
	const MainApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MultiProvider(
			providers: [
				ChangeNotifierProvider(create: (_) => AuthProvider()),
				ChangeNotifierProvider(create: (_) => BookProvider()),
				ChangeNotifierProvider(create: (_) => CartProvider()),
			],
			child: MaterialApp(
			title: 'Mobile Micro Commerce',
			theme: AppTheme.light,
			initialRoute: AppRoutes.login,
			routes: {
				AppRoutes.login: (_) => const LoginScreen(),
				AppRoutes.register: (_) => const RegisterScreen(),
				AppRoutes.editProfile: (_) => const EditProfileScreen(),
				AppRoutes.customerBooks: (_) => const BookListScreen(),
				AppRoutes.customerBookDetail: (context) {
					final book = ModalRoute.of(context)?.settings.arguments;
					if (book is BookModel) return BookDetailScreen(book: book);
					return Scaffold(
						appBar: AppBar(title: const Text('รายละเอียดหนังสือ')),
						body: const Center(child: Text('ไม่พบข้อมูลหนังสือ')),
					);
				},
				AppRoutes.customerCart: (_) => const CartScreen(),
				AppRoutes.customerCheckout: (_) => const CheckoutScreen(),
				AppRoutes.customerOrderHistory: (_) => const OrderHistoryScreen(),
				AppRoutes.ownerDashboard: (_) => const DashboardScreen(),
				AppRoutes.ownerBooks: (_) => const BookManageListScreen(),
				AppRoutes.ownerBookForm: (_) => const BookManageFormScreen(),
				AppRoutes.ownerOrders: (_) => const OrderManageScreen(),
				AppRoutes.ownerCoupons: (_) => const CouponManageScreen(),
				AppRoutes.chats: (_) => const ChatListScreen(),
				AppRoutes.chatRoom: (_) => const ChatRoomScreen(),
				AppRoutes.profile: (_) => const ProfileScreen(),
			},
			),
		);
	}
}