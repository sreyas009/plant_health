import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  Widget _sectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _sectionCard(Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: child,
      ),
    );
  }

  Widget _listPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  ", style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "DATA COLLECTION GUIDELINES FOR PLANT HEALTH INDEX",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "(Leaf Image + Calibration Card + Brix/NDVI)",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),

          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  "1. Capture Requirements (For Every Image)",
                  context,
                ),
                const SizedBox(height: 8),
                Text(
                  "A. Include Calibration Card",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _listPoint(
                  "Capture the full calibration color grid next to or below the leaf.",
                ),
                _listPoint("Keep the card tilted no more than 20°."),
                const SizedBox(height: 10),
                Text(
                  "B. Camera Distance",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _listPoint("Hold the camera 20–25 cm above the leaf."),
                _listPoint(
                  "Ensure both the leaf and card are sharp and in focus.",
                ),
                const SizedBox(height: 10),
                Text(
                  "C. Leaf Requirements",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _listPoint(
                  "Clean leaf surface with no water droplets, and avoid major folds.",
                ),
                _listPoint(
                  "Ensure the entire target leaf is visible with no self-shading.",
                ),
                const SizedBox(height: 10),
                Text(
                  "D. Metadata to Upload With Image",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _listPoint(
                  "Brix and/or NDVI reading (preferred, at least one is required).",
                ),
                _listPoint("Timestamp (automatic is acceptable)."),
                _listPoint("Crop name and leaf position (top/middle/bottom)."),
                _listPoint("Avoid uploading duplicate captures."),
                const SizedBox(height: 10),
                Text(
                  "NOTE: Upload at least one measurement (Brix OR NDVI). If possible, upload both for richer training data.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("2. Lighting Scenarios to Collect", context),
                const SizedBox(height: 6),
                Text(
                  "Collect images under three lighting conditions to help color correction and nitrogen estimation.",
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Text(
                  "Scenario 1 — Ideal Lighting (Normal Light)",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _listPoint(
                  "Balanced exposure and natural colors with bright daylight or diffused shade.",
                ),
                _listPoint(
                  "No glare, no hard shadows, calibration card looks normal.",
                ),
                _listPoint(
                  "Collect 15–20 samples per leaf type with and without measurements.",
                ),
                const SizedBox(height: 10),
                Text(
                  "Scenario 2 — Overexposed Lighting (High Brightness)",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _listPoint(
                  "Direct sunlight with bright white glare, leaf looks lighter or shiny.",
                ),
                _listPoint("Calibration card appears slightly washed."),
                _listPoint(
                  "Collect 10–15 samples, showing reflection areas and multiple angles.",
                ),
                const SizedBox(height: 10),
                Text(
                  "Scenario 3 — Underexposed Lighting (Low Light / Shade)",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _listPoint(
                  "Low ambient light, darker leaf colors, partial shadows.",
                ),
                _listPoint("Calibration card looks darker than normal."),
                _listPoint(
                  "Collect 10–15 samples, vary shadow direction and leaf coverage.",
                ),
              ],
            ),
          ),

          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  "3. Additional Variations Needed for Robust Dataset",
                  context,
                ),
                const SizedBox(height: 8),
                Text(
                  "A. Angle Variations",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _listPoint("Top-down shots."),
                _listPoint("Slight tilt left/right (10–20°)."),
                _listPoint("45° diagonal shots for select samples."),
                const SizedBox(height: 6),
                Text(
                  "B. Calibration Card Variations",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _listPoint("Card can be left, right, or below the leaf."),
                _listPoint(
                  "Slight rotation (~10°) is acceptable but keep the grid fully visible.",
                ),
                const SizedBox(height: 6),
                Text(
                  "C. Distance Variations",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _listPoint(
                  "20 cm standard, 25–30 cm for wider framing, 15–18 cm for close-ups.",
                ),
                _listPoint("Avoid being too close to prevent distortion."),
                const SizedBox(height: 6),
                Text(
                  "D. Leaf Condition Variations",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _listPoint(
                  "Healthy green, slight chlorosis, yellowish, dark green, damaged, and aging leaves.",
                ),
                _listPoint("These variations improve nitrogen classification."),
              ],
            ),
          ),

          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("4. Minimum Dataset Per Site", context),
                const SizedBox(height: 8),
                _listPoint("Ideal lighting: 20 images."),
                _listPoint("Overexposed: 15 images."),
                _listPoint("Underexposed: 15 images."),
                _listPoint("Angle variations: 10 images."),
                _listPoint("Leaf condition variations: 10 images."),
                const SizedBox(height: 8),
                Text(
                  "Total ≈ 60–70 images per crop per field.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          _sectionCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("5. Final Checklist Before Upload", context),
                const SizedBox(height: 8),
                _listPoint("Calibration card fully visible."),
                _listPoint("Leaf fully visible."),
                _listPoint("Image is sharp and not blurry."),
                _listPoint("Lighting scenario matches metadata."),
                _listPoint("Distance ~20–25 cm."),
                _listPoint("Brix and/or NDVI recorded."),
                _listPoint("No duplicate captures."),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
