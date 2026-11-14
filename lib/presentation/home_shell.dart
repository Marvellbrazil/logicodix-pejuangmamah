import 'package:flutter/material.dart';

import '../application/ask_assistant.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'applications_screen.dart';
import 'assistant_screen.dart';
import 'chats_screen.dart';
import 'home_feed_screen.dart';
import 'post_job_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.state,
    required this.askAssistant,
  });

  final AppState state;
  final AskAssistant askAssistant;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _assistantOpen = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final profile = state.profile;
        final employer = profile?.isEmployer ?? false;
        final tabs = employer
            ? const <_TabSpec>[
                _TabSpec(Icons.dashboard_outlined, Icons.dashboard, 'Beranda'),
                _TabSpec(Icons.inbox_outlined, Icons.inbox, 'Pelamar'),
                _TabSpec(Icons.chat_bubble_outline, Icons.chat_bubble, 'Pesan'),
                _TabSpec(Icons.person_outline, Icons.person, 'Profil'),
              ]
            : const <_TabSpec>[
                _TabSpec(Icons.home_outlined, Icons.home, 'Beranda'),
                _TabSpec(Icons.search, Icons.search, 'Cari'),
                _TabSpec(Icons.send_outlined, Icons.send, 'Lamaran'),
                _TabSpec(Icons.chat_bubble_outline, Icons.chat_bubble, 'Pesan'),
                _TabSpec(Icons.person_outline, Icons.person, 'Profil'),
              ];

        final index = state.tabIndex.clamp(0, tabs.length - 1);
        final screens = employer
            ? <Widget>[
                HomeFeedScreen(
                  state: state,
                  onOpenAssistant: () => _openAssistant(),
                ),
                ApplicationsScreen(state: state, onOpenChat: (_) {}),
                ChatsScreen(state: state),
                ProfileScreen(state: state),
              ]
            : <Widget>[
                HomeFeedScreen(
                  state: state,
                  onOpenAssistant: () => _openAssistant(),
                ),
                SearchScreen(state: state),
                ApplicationsScreen(state: state, onOpenChat: (_) {}),
                ChatsScreen(state: state),
                ProfileScreen(state: state),
              ];

        return Scaffold(
          backgroundColor: Surfaces.base,
          body: IndexedStack(index: index, children: screens),
          floatingActionButton: employer && index == 0
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PostJobScreen(state: state),
                      ),
                    );
                    await state.refreshFeed(mine: true);
                  },
                  backgroundColor: Accent.teal,
                  foregroundColor: Accent.tealInk,
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text(
                    'Pasang',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              : null,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Surfaces.lineSoft)),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: state.selectTab,
              destinations: [
                for (var i = 0; i < tabs.length; i++)
                  NavigationDestination(
                    icon: _NavIcon(
                      icon: tabs[i].icon,
                      badge: i == _chatTabIndex(employer)
                          ? state.unreadChats
                          : 0,
                    ),
                    selectedIcon: _NavIcon(
                      icon: tabs[i].selectedIcon,
                      active: true,
                      badge: i == _chatTabIndex(employer)
                          ? state.unreadChats
                          : 0,
                    ),
                    label: tabs[i].label,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _chatTabIndex(bool employer) => employer ? 2 : 3;

  Future<void> _openAssistant() async {
    if (_assistantOpen) return;
    _assistantOpen = true;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => AssistantScreen(
          state: widget.state,
          askAssistant: widget.askAssistant,
        ),
        transitionsBuilder: (_, animation, _, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
    _assistantOpen = false;
  }
}

class _TabSpec {
  const _TabSpec(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.active = false, this.badge = 0});

  final IconData icon;
  final bool active;
  final int badge;

  @override
  Widget build(BuildContext context) {
    if (badge <= 0) return Icon(icon);
    return Badge(
      backgroundColor: Accent.danger,
      textColor: Colors.white,
      label: Text(badge > 9 ? '9+' : '$badge'),
      child: Icon(icon),
    );
  }
}
