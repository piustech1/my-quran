import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum AvatarVariant { login, signup }

class PopOutClipper extends CustomClipper<Path> {
  const PopOutClipper();

  @override
  Path getClip(Size size) {
    const cx = 80.0;
    const cy = 102.0;
    const r = 64.0;

    final path = Path()
      ..moveTo(cx - r, cy)
      ..lineTo(cx - r, 0)
      ..lineTo(cx + r, 0)
      ..lineTo(cx + r, cy)
      ..arcToPoint(
        const Offset(cx - r, cy),
        radius: const Radius.circular(r),
        clockwise: false,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class PopOutAvatarBadge extends StatelessWidget {
  final AvatarVariant variant;

  const PopOutAvatarBadge({
    super.key,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    const wrapW = 160.0;
    const wrapH = 166.0;
    const ringSize = 128.0;
    const cx = wrapW / 2; // 80.0
    const cy = wrapH - ringSize / 2; // 102.0
    const r = ringSize / 2; // 64.0

    final isLogin = variant == AvatarVariant.login;
    final imageAsset = isLogin
        ? 'assets/avatars/hijab_avatar_login.png'
        : 'assets/avatars/hijab_avatar_signup.png';

    // Offsets from noor-sanctuary spec:
    // login: width 176, x: -8, y: 16 -> left = (160 - 176)/2 - 8 = -16
    // signup: width 176, x: -13, y: 16 -> left = (160 - 176)/2 - 13 = -21
    final imgLeft = isLogin ? -16.0 : -21.0;
    const imgTop = 16.0;
    const imgWidth = 176.0;

    return SizedBox(
      width: wrapW,
      height: wrapH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Dual gold border ring with ambient glow
          Positioned(
            left: cx - r,
            top: cy - r,
            width: ringSize,
            height: ringSize,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: NoorColors.gold.withOpacity(0.60),
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40D4AF37),
                    blurRadius: 25,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NoorColors.gold.withOpacity(0.35),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Pop-out clipped Avatar illustration
          Positioned.fill(
            child: ClipPath(
              clipper: const PopOutClipper(),
              child: Stack(
                children: [
                  Positioned(
                    left: imgLeft,
                    top: imgTop,
                    width: imgWidth,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
