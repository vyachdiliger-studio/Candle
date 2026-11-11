import "package:candle_frontend/l10n/localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "/core/constants/app_colors.dart";
import "/core/constants/sizes.dart";

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(context.l10n.privacyPolicy),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go("/login"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.large, vertical: Sizes.medium),
        children: [
          _Intro(),
          SizedBox(height: Sizes.large),
          _Section(
            title: context.l10n.privacyCollectionTitle,
            paragraphs: [
              context.l10n.privacyAccount,
              context.l10n.privacyGoogle,
              context.l10n.privacyTelegram,
              context.l10n.privacyContent,
              context.l10n.privacyLocation,
              context.l10n.privacyModeration,
              context.l10n.privacyTechnical,
            ],
          ),
          _Section(
            title: context.l10n.privacyUsageTitle,
            paragraphs: [
              context.l10n.privacyUsage,
            ],
          ),
          _Section(
            title: context.l10n.privacySharingTitle,
            paragraphs: [
              context.l10n.privacySharing,
            ],
          ),
          _Section(
            title: context.l10n.privacyRetentionTitle,
            paragraphs: [
              context.l10n.privacyRetention,
            ],
          ),
          _Section(
            title: context.l10n.privacyChoicesTitle,
            paragraphs: [
              context.l10n.privacyChoices,
            ],
          ),
          _Section(
            title: context.l10n.privacyChildrenTitle,
            paragraphs: [
              context.l10n.privacyChildren,
            ],
          ),
          _Section(
            title: context.l10n.privacySecurityTitle,
            paragraphs: [
              context.l10n.privacySecurity,
            ],
          ),
          _Section(
            title: context.l10n.privacyChangesTitle,
            paragraphs: [
              context.l10n.privacyChanges,
            ],
          ),
          _Section(
            title: context.l10n.privacyContactTitle,
            paragraphs: [
              context.l10n.privacyContact,
            ],
          ),
          SizedBox(height: Sizes.extraLarge),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.privacyUpdated,
          style: TextStyle(color: AppColors.textSubtle, fontSize: AppFontSizes.label),
        ),
        SizedBox(height: Sizes.medium),
        Text(
          context.l10n.privacyIntro,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: AppFontSizes.bodyCompact,
            height: AppTypography.leadingRelaxed,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sizes.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: AppFontSizes.subtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Sizes.small),
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(top: Sizes.small),
              child: Text(
                paragraph,
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: AppFontSizes.legalBody,
                  height: AppTypography.leadingRelaxed,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
