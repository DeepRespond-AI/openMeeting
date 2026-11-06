import 'package:flutter/material.dart';

import '../theme/context_extensions.dart';
import 'brand_logo.dart';

/// Shown at `/` while the session is being restored; the router redirects away.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: BrandLogo(height: context.sizes.logoLg, withTagline: true)),
    );
  }
}
