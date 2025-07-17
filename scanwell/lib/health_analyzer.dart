// lib/health_analyzer.dart

class HealthAnalysisResult {
  final bool isHealthy;
  final String message;
  final int healthScore;
  final List<String> warnings;
  final Map<String, String> detectedNutrients; // Store raw detected nutrients

  HealthAnalysisResult({
    required this.isHealthy,
    required this.message,
    this.healthScore = 5, // Default score
    this.warnings = const [],
    this.detectedNutrients = const {},
  });
}

class HealthAnalyzer {
  HealthAnalysisResult analyzeProduct(String ocrText) {
    // Convert text to lowercase for easier matching
    final lowerCaseText = ocrText.toLowerCase();

    // 1. Extract Nutritional Data (Simplified - this will be the most complex part to make robust)
    // We'll use simple regex or string searching for now.
    // Real-world OCR text can be very messy, so this is a starting point.
    Map<String, String> detectedNutrients = {};
    int calories = 0;
    double sugar = 0.0;
    double totalFat = 0.0;
    double transFat = 0.0; // Assume 0 unless found
    double sodium = 0.0;
    double fiber = 0.0;

    // --- Calorie Extraction ---
    RegExp caloriesRegex = RegExp(r'calories[:\s]*(\d+)');
    Match? calMatch = caloriesRegex.firstMatch(lowerCaseText);
    if (calMatch != null) {
      calories = int.tryParse(calMatch.group(1)!) ?? 0;
      detectedNutrients['Calories'] = calories.toString();
    }

    // --- Sugar Extraction (in grams) ---
    // Example: "sugar 10g", "sugars: 5.2g"
    RegExp sugarRegex = RegExp(r'sugar(?:s)?[:\s]*([\d.]+)(?:g)?');
    Match? sugarMatch = sugarRegex.firstMatch(lowerCaseText);
    if (sugarMatch != null) {
      sugar = double.tryParse(sugarMatch.group(1)!) ?? 0.0;
      detectedNutrients['Sugar'] = '${sugar}g';
    }

    // --- Total Fat Extraction ---
    RegExp totalFatRegex = RegExp(r'total fat[:\s]*([\d.]+)(?:g)?');
    Match? totalFatMatch = totalFatRegex.firstMatch(lowerCaseText);
    if (totalFatMatch != null) {
      totalFat = double.tryParse(totalFatMatch.group(1)!) ?? 0.0;
      detectedNutrients['Total Fat'] = '${totalFat}g';
    }

    // --- Trans Fat Check ---
    // Look for "trans fat" or "transfats" keyword
    if (lowerCaseText.contains('trans fat') || lowerCaseText.contains('transfats')) {
      transFat = 1.0; // Just indicating presence, actual quantity harder to parse reliably for now
      detectedNutrients['Trans Fat'] = 'Present';
    }

    // --- Sodium Extraction ---
    RegExp sodiumRegex = RegExp(r'sodium[:\s]*([\d.]+)(?:mg)?'); // In milligrams
    Match? sodiumMatch = sodiumRegex.firstMatch(lowerCaseText);
    if (sodiumMatch != null) {
      sodium = double.tryParse(sodiumMatch.group(1)!) ?? 0.0;
      detectedNutrients['Sodium'] = '${sodium}mg';
    }

    // --- Fiber Extraction ---
    RegExp fiberRegex = RegExp(r'fiber[:\s]*([\d.]+)(?:g)?');
    Match? fiberMatch = fiberRegex.firstMatch(lowerCaseText);
    if (fiberMatch != null) {
      fiber = double.tryParse(fiberMatch.group(1)!) ?? 0.0;
      detectedNutrients['Fiber'] = '${fiber}g';
    }

    // 2. Analyze based on simple rules and assign score
    bool isHealthy = true;
    int healthScore = 10; // Start with healthy score
    List<String> warnings = [];
    String message = 'Looks good!';

    // Rule: Trans fats are unhealthy
    if (transFat > 0) {
      isHealthy = false;
      warnings.add('Contains trans fats!');
      healthScore -= 4; // Significant deduction
    }

    // Rule: High sugar (example thresholds)
    if (sugar > 15.0) { // More than 15g sugar per serving is high
      isHealthy = false;
      warnings.add('High in sugar (>${sugar.toStringAsFixed(1)}g)!');
      healthScore -= 3;
    } else if (sugar > 5.0) { // Moderate sugar
      warnings.add('Moderate sugar content (${sugar.toStringAsFixed(1)}g).');
      healthScore -= 1;
    }

    // Rule: High sodium (example thresholds, daily recommended is ~2300mg)
    if (sodium > 400.0) { // More than 400mg per serving is high
      isHealthy = false;
      warnings.add('High in sodium (>${sodium.toStringAsFixed(0)}mg)!');
      healthScore -= 2;
    } else if (sodium > 150.0) { // Moderate sodium
      warnings.add('Moderate sodium content (${sodium.toStringAsFixed(0)}mg).');
      healthScore -= 1;
    }

    // Rule: High total fat (example thresholds)
    if (totalFat > 20.0) { // More than 20g total fat per serving
      isHealthy = false;
      warnings.add('High in total fat (>${totalFat.toStringAsFixed(1)}g)!');
      healthScore -= 2;
    }

    // Rule: High fiber (positive indicator)
    if (fiber > 3.0) { // More than 3g fiber per serving is good
      message += ' Good source of fiber!';
      healthScore += 1; // Bonus for fiber
    }

    // Final health determination
    if (healthScore <= 4) {
      message = 'Unhealthy!';
    } else if (healthScore <= 7) {
      message = 'Moderately Healthy.';
    } else {
      message = 'Healthy!';
    }

    healthScore = healthScore.clamp(0, 10); // Keep score between 0 and 10

    return HealthAnalysisResult(
      isHealthy: isHealthy,
      message: message,
      healthScore: healthScore,
      warnings: warnings,
      detectedNutrients: detectedNutrients,
    );
  }
}