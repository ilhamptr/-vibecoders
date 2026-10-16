import 'package:flutter/material.dart';

class RoleSelectionCard extends StatelessWidget {
  const RoleSelectionCard({
    super.key,
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String image;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? const Color(0xFFBDEFFC) : const Color(0xFFE8EAEB),
          width: 1,
        ),
      ),
      elevation: selected ? 0 : 1,
      shadowColor: const Color(0x12000000),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE5FAFF), Colors.white],
                  )
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
          child: Stack(
            children: [
              Image.asset(image, width: 32, height: 32),
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF20252B)
                        : const Color(0xFF20252B),
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Positioned(
                top: 1,
                right: 0,
                child: _SelectionIndicator(selected: selected),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? const Color(0xFF3BA6D3) : Colors.transparent,
      border: selected
          ? null
          : Border.all(color: const Color(0xFF8E969A), width: 1),
    ),
  );
}
