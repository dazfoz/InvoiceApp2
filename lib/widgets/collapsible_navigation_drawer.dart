import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/theme.dart';

class CollapsibleNavigationDrawer extends StatelessWidget {
  final List<NavigationItem> items;
  final Widget header;
  final Widget? footer;
  final Function(int)? onItemSelected;
  final int selectedIndex;

  const CollapsibleNavigationDrawer({
    Key? key,
    required this.items,
    required this.header,
    this.footer,
    this.onItemSelected,
    this.selectedIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationState>(context);
    final isExpanded = navProvider.isExpanded;

    return GestureDetector(
      // Expand drawer when tapped if it's collapsed
      onTap: isExpanded ? null : () => navProvider.setExpanded(true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isExpanded ? 250 : 70,
        decoration: BoxDecoration(
          color: Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Header
            header,

            // Toggle button - only show when expanded
            if (isExpanded)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: AppTheme.accentColor,
                      ),
                      onPressed: () {
                        navProvider.setExpanded(false);
                      },
                      tooltip: 'Collapse',
                    ),
                  ],
                ),
              ),

            Divider(color: AppTheme.secondaryColor.withOpacity(0.3)),

            // Navigation items
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex;

                  return NavigationItemWidget(
                    item: item,
                    isExpanded: isExpanded,
                    isSelected: isSelected,
                    onTap: () {
                      // If drawer is collapsed, expand it first on item tap
                      if (!isExpanded) {
                        navProvider.setExpanded(true);
                      }

                      if (onItemSelected != null) {
                        onItemSelected!(index);
                      }
                    },
                  );
                },
              ),
            ),

            // Footer
            if (footer != null) ...[
              Divider(color: AppTheme.secondaryColor.withOpacity(0.3)),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String title;
  final String? route;
  final Function()? onTap;

  NavigationItem({
    required this.icon,
    required this.title,
    this.route,
    this.onTap,
  });
}

class NavigationItemWidget extends StatelessWidget {
  final NavigationItem item;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  const NavigationItemWidget({
    Key? key,
    required this.item,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.accentColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppTheme.accentColor.withOpacity(0.2),
          highlightColor: AppTheme.accentColor.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: isExpanded ? 16.0 : 8.0,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected
                        ? AppTheme.accentColor
                        : AppTheme.secondaryColor,
                    size: 24,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.accentColor
                            : AppTheme.darkColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationDrawerHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final bool isExpanded;

  const NavigationDrawerHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.isExpanded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.accentColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(16),
        ),
      ),
      child: isExpanded ? _buildExpandedHeader() : _buildCollapsedHeader(),
    );
  }

  Widget _buildExpandedHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageUrl != null) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(imageUrl!),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : 'B',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedHeader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: imageUrl != null
              ? CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(imageUrl!),
                  backgroundColor: Colors.white,
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : 'B',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
