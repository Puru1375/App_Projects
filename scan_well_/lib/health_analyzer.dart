// lib/health_analyzer.dart

class HealthAnalysisResult {
  final bool isHealthy;
  final String message;
  final int healthScore;
  final List<String> warnings;

  final String? productName;
  final String? ingredientsList;
  final Map<String, double> nutritionFacts;
  final Map<String, String> rawDetectedText;

  HealthAnalysisResult({
    required this.isHealthy,
    required this.message,
    this.healthScore = 5,
    this.warnings = const [],
    this.productName,
    this.ingredientsList,
    this.nutritionFacts = const {},
    this.rawDetectedText = const {},
  });
}

class HealthAnalyzer {
  HealthAnalysisResult analyzeProduct(String ocrText) {
    final lowerCaseText = ocrText.toLowerCase();
    final List<String> lines = ocrText.split('\n').map((l) => l.trim()).toList();

    String? productName;
    String? ingredientsList;
    Map<String, double> nutritionFacts = {};
    Map<String, String> rawDetectedText = {};

    // --- 1. Basic Product Name Extraction ---
    if (lines.isNotEmpty) {
      productName = lines.firstWhere((line) => line.isNotEmpty, orElse: () => '');
      if (productName!.isEmpty) productName = null;
    }

    // --- 2. Extract Ingredients List ---
    // Find line starting with "ingredients:" and take content until next major section
    int ingredientsStartIndex = -1;
    int nextSectionIndex = lines.length;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().startsWith('ingredients:')) {
        ingredientsStartIndex = i;
      } else if (ingredientsStartIndex != -1 &&
          (lines[i].toLowerCase().contains('nutrition information') ||
              lines[i].toLowerCase().contains('nutrition facts') ||
              lines[i].toLowerCase().contains('serving size') ||
              lines[i].toLowerCase().contains('allergen information'))) {
        nextSectionIndex = i;
        break;
      }
    }

    if (ingredientsStartIndex != -1) {
      ingredientsList = lines.sublist(ingredientsStartIndex).join(' '); // Join from ingredients line onwards
      // Trim to actual end of ingredients list
      ingredientsList = ingredientsList!.substring('ingredients:'.length).trim();
      // Find any common end markers
      List<String> endMarkers = ['nutrition information', 'nutrition facts', 'serving size', 'allergen information', 'contains:'];
      for (String marker in endMarkers) {
        int markerIndex = ingredientsList!.toLowerCase().indexOf(marker);
        if (markerIndex != -1) {
          ingredientsList = ingredientsList!.substring(0, markerIndex).trim();
          break;
        }
      }
    }


    // --- 3. Extract Nutrition Facts (Line-by-Line Parsing) ---
    // This is a more robust approach for detached values
    // Define common nutrient keywords and their variations
    Map<String, List<String>> nutrientKeywords = {
      'Calories': ['calories', 'energy'],
      'Total Fat': ['total fat'],
      'Saturated Fat': ['saturated fat'],
      'Trans Fat': ['trans fat', 'transfats'],
      'Cholesterol': ['cholesterol'],
      'Sodium': ['sodium'],
      'Total Carbohydrate': ['total carbohydrate', 'carbohydrate'],
      'Fiber': ['fiber', 'dietary fiber'],
      'Sugar': ['sugar', 'sugars'],
      'Added Sugar': ['added sugar', 'added sugars'],
      'Protein': ['protein'],
      // Add more as needed
    };

    // Regular expression to find a number (integer or decimal)
    RegExp numberRegex = RegExp(r'([\d.]+)\s*(?:g|mg|kcal|kj)?'); // Capture number and optional unit

    for (int i = 0; i < lines.length; i++) {
      String currentLine = lines[i].toLowerCase();

      // Check for each nutrient keyword
      nutrientKeywords.forEach((nutrientName, keywords) {
        bool foundKeyword = false;
        for (String keyword in keywords) {
          if (currentLine.contains(keyword)) {
            foundKeyword = true;
            break;
          }
        }

        if (foundKeyword) {
          // Try to find the number on the current line first
          Match? numMatch = numberRegex.firstMatch(currentLine);
          if (numMatch != null) {
            double? value = double.tryParse(numMatch.group(1)!) ?? 0.0;
            nutritionFacts[nutrientName] = value;
            rawDetectedText[nutrientName] = '${numMatch.group(1)!}${numMatch.group(2) ?? ''}'; // Store raw string including unit
          } else if (i + 1 < lines.length) {
            // If not found on current line, look on the next line
            String nextLine = lines[i + 1].toLowerCase();
            numMatch = numberRegex.firstMatch(nextLine);
            if (numMatch != null) {
              double? value = double.tryParse(numMatch.group(1)!) ?? 0.0;
              nutritionFacts[nutrientName] = value;
              rawDetectedText[nutrientName] = '${numMatch.group(1)!}${numMatch.group(2) ?? ''}';
            }
          }
        }
      });
    }


    // --- 4. Health Analysis Logic (More detailed with parsed data) ---
    bool isHealthy = true;
    int healthScore = 10; // Start with a perfect score
    List<String> warnings = [];
    String message = 'Analysis Complete.';

    // Get values safely from the nutritionFacts map, defaulting to 0.0 if not found
    double sugar = nutritionFacts['Sugar'] ?? 0.0;
    double addedSugar = nutritionFacts['Added Sugar'] ?? 0.0;
    double totalFat = nutritionFacts['Total Fat'] ?? 0.0;
    double saturatedFat = nutritionFacts['Saturated Fat'] ?? 0.0;
    double transFat = nutritionFacts['Trans Fat'] ?? 0.0; // Will be >0 if detected, 0.0 if not
    double sodium = nutritionFacts['Sodium'] ?? 0.0;
    double fiber = nutritionFacts['Fiber'] ?? 0.0;
    int calories = (nutritionFacts['Calories'] ?? 0).toInt();

    // --- Apply Health Rules ---

    // Rule: Trans fats (highly unhealthy)
    if (transFat > 0) {
      isHealthy = false;
      warnings.add('Contains trans fats!');
      healthScore -= 4; // Significant deduction
    }

    // Rule: High Sugar (per 100g or per serving - needs context, so using absolute for now)
    if (sugar > 15.0) { // e.g., >15g sugar per serving is high
      isHealthy = false;
      warnings.add('High in sugar (${sugar.toStringAsFixed(1)}g)!');
      healthScore -= 3;
    } else if (sugar > 5.0) { // Moderate sugar
      warnings.add('Moderate sugar content (${sugar.toStringAsFixed(1)}g).');
      healthScore -= 1;
    }
    if (addedSugar > 5.0) { // Added sugar is generally worse than natural sugar
      isHealthy = false;
      warnings.add('Contains significant added sugars (${addedSugar.toStringAsFixed(1)}g)!');
      healthScore -= 2;
    }


    // Rule: High Sodium (example thresholds, daily recommended intake is ~2300mg)
    if (sodium > 400.0) { // e.g., >400mg sodium per serving is high
      isHealthy = false;
      warnings.add('High in sodium (${sodium.toStringAsFixed(0)}mg)!');
      healthScore -= 2;
    } else if (sodium > 150.0) { // Moderate sodium
      warnings.add('Moderate sodium content (${sodium.toStringAsFixed(0)}mg).');
      healthScore -= 1;
    }

    // Rule: High Total Fat
    if (totalFat > 20.0) { // e.g., >20g total fat per serving
      isHealthy = false;
      warnings.add('High in total fat (${totalFat.toStringAsFixed(1)}g)!');
      healthScore -= 2;
    }
    // Rule: High Saturated Fat
    if (saturatedFat > 5.0) { // e.g., >5g saturated fat per serving
      isHealthy = false;
      warnings.add('High in saturated fat (${saturatedFat.toStringAsFixed(1)}g)!');
      healthScore -= 2;
    }

    // Rule: Good Source of Fiber (positive indicator)
    if (fiber > 3.0) { // e.g., >3g fiber per serving is good
      warnings.add('Good source of fiber (${fiber.toStringAsFixed(1)}g)!');
      healthScore += 1; // Bonus for fiber
    }

    // Check for specific unhealthy ingredients keywords (very basic example)
    if (ingredientsList != null && ingredientsList!.isNotEmpty) {
      if (ingredientsList!.contains('high fructose corn syrup')) {
        isHealthy = false;
        warnings.add('Contains High Fructose Corn Syrup!');
        healthScore -= 3;
      }
      if (ingredientsList!.contains('hydrogenated oil') || ingredientsList!.contains('partially hydrogenated oil')) {
        isHealthy = false;
        warnings.add('Contains hydrogenated oil!');
        healthScore -= 3;
      }
      if (ingredientsList!.contains('artificial colors') || ingredientsList!.contains('artificial flavours')) {
        warnings.add('Contains artificial ingredients.');
        healthScore -= 1;
      }
    }

    // Final overall message based on calculated score
    if (healthScore <= 4) {
      message = 'Unhealthy!';
    } else if (healthScore <= 7) {
      message = 'Moderately Healthy.';
    } else {
      message = 'Healthy!';
    }

    healthScore = healthScore.clamp(0, 10); // Ensure score stays within 0-10 range

    // Return the comprehensive analysis result
    return HealthAnalysisResult(
      isHealthy: isHealthy,
      message: message,
      healthScore: healthScore,
      warnings: warnings,
      productName: productName,
      ingredientsList: ingredientsList,
      nutritionFacts: nutritionFacts, // Pass the parsed numerical map
      rawDetectedText: rawDetectedText, // Pass the raw string map
    );
  }
}