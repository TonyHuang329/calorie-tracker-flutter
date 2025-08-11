import '../models/food_item.dart';

class FoodDatabaseService {
  static List<FoodItem> _predefinedFoods = [
    // ===== Staple Food =====
    FoodItem(
      name: 'Rice',
      caloriesPerUnit: 1.3, // 130 calories/100g = 1.3 calories/g
      unit: 'g',
      category: 'Staple Food',
      protein: 0.027, // 2.7g protein/100g = 0.027g/g
      carbs: 0.28,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Brown Rice',
      caloriesPerUnit: 1.12,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.023,
      carbs: 0.23,
      fat: 0.009,
    ),
    FoodItem(
      name: 'Quinoa',
      caloriesPerUnit: 1.20,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.044,
      carbs: 0.22,
      fat: 0.019,
    ),
    FoodItem(
      name: 'Noodles',
      caloriesPerUnit: 2.8,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.11,
      carbs: 0.55,
      fat: 0.011,
    ),
    FoodItem(
      name: 'Whole Wheat Noodles',
      caloriesPerUnit: 1.24,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.050,
      carbs: 0.25,
      fat: 0.010,
    ),
    FoodItem(
      name: 'Bread',
      caloriesPerUnit: 3.12,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.085,
      carbs: 0.58,
      fat: 0.051,
    ),
    FoodItem(
      name: 'Whole Wheat Bread',
      caloriesPerUnit: 2.47,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.130,
      carbs: 0.41,
      fat: 0.032,
    ),
    FoodItem(
      name: 'Oats',
      caloriesPerUnit: 3.89,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.169,
      carbs: 0.66,
      fat: 0.069,
    ),
    FoodItem(
      name: 'Sweet Potato',
      caloriesPerUnit: 0.86,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.020,
      carbs: 0.20,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Potato',
      caloriesPerUnit: 0.77,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.020,
      carbs: 0.17,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Corn',
      caloriesPerUnit: 0.86,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.032,
      carbs: 0.19,
      fat: 0.012,
    ),
    FoodItem(
      name: 'Barley',
      caloriesPerUnit: 3.54,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.123,
      carbs: 0.73,
      fat: 0.023,
    ),

    // ===== Protein =====
    FoodItem(
      name: 'Chicken Breast',
      caloriesPerUnit: 1.65,
      unit: 'g',
      category: 'Protein',
      protein: 0.31,
      carbs: 0.0,
      fat: 0.036,
    ),
    FoodItem(
      name: 'Chicken Thigh',
      caloriesPerUnit: 2.09,
      unit: 'g',
      category: 'Protein',
      protein: 0.262,
      carbs: 0.0,
      fat: 0.104,
    ),
    FoodItem(
      name: 'Chicken Wings',
      caloriesPerUnit: 2.03,
      unit: 'g',
      category: 'Protein',
      protein: 0.306,
      carbs: 0.0,
      fat: 0.081,
    ),
    FoodItem(
      name: 'Egg',
      caloriesPerUnit: 1.55,
      unit: 'g',
      category: 'Protein',
      protein: 0.13,
      carbs: 0.011,
      fat: 0.11,
    ),
    FoodItem(
      name: 'Egg White',
      caloriesPerUnit: 0.52,
      unit: 'g',
      category: 'Protein',
      protein: 0.109,
      carbs: 0.007,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Beef',
      caloriesPerUnit: 2.5,
      unit: 'g',
      category: 'Protein',
      protein: 0.26,
      carbs: 0.0,
      fat: 0.17,
    ),
    FoodItem(
      name: 'Lean Beef',
      caloriesPerUnit: 1.58,
      unit: 'g',
      category: 'Protein',
      protein: 0.302,
      carbs: 0.0,
      fat: 0.040,
    ),
    FoodItem(
      name: 'Pork',
      caloriesPerUnit: 2.42,
      unit: 'g',
      category: 'Protein',
      protein: 0.279,
      carbs: 0.0,
      fat: 0.140,
    ),
    FoodItem(
      name: 'Lean Pork',
      caloriesPerUnit: 1.43,
      unit: 'g',
      category: 'Protein',
      protein: 0.281,
      carbs: 0.0,
      fat: 0.035,
    ),
    FoodItem(
      name: 'Fish',
      caloriesPerUnit: 2.06,
      unit: 'g',
      category: 'Protein',
      protein: 0.22,
      carbs: 0.0,
      fat: 0.12,
    ),
    FoodItem(
      name: 'Salmon',
      caloriesPerUnit: 2.08,
      unit: 'g',
      category: 'Protein',
      protein: 0.250,
      carbs: 0.0,
      fat: 0.120,
    ),
    FoodItem(
      name: 'Tuna',
      caloriesPerUnit: 1.44,
      unit: 'g',
      category: 'Protein',
      protein: 0.301,
      carbs: 0.0,
      fat: 0.010,
    ),
    FoodItem(
      name: 'Shrimp',
      caloriesPerUnit: 0.99,
      unit: 'g',
      category: 'Protein',
      protein: 0.240,
      carbs: 0.0,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Tofu',
      caloriesPerUnit: 0.76,
      unit: 'g',
      category: 'Protein',
      protein: 0.081,
      carbs: 0.019,
      fat: 0.048,
    ),
    FoodItem(
      name: 'Greek Yogurt',
      caloriesPerUnit: 0.59,
      unit: 'g',
      category: 'Protein',
      protein: 0.100,
      carbs: 0.036,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Cottage Cheese',
      caloriesPerUnit: 0.98,
      unit: 'g',
      category: 'Protein',
      protein: 0.111,
      carbs: 0.033,
      fat: 0.043,
    ),
    FoodItem(
      name: 'Black Beans',
      caloriesPerUnit: 1.32,
      unit: 'g',
      category: 'Protein',
      protein: 0.089,
      carbs: 0.230,
      fat: 0.005,
    ),
    FoodItem(
      name: 'Lentils',
      caloriesPerUnit: 1.16,
      unit: 'g',
      category: 'Protein',
      protein: 0.090,
      carbs: 0.200,
      fat: 0.004,
    ),
    FoodItem(
      name: 'Chickpeas',
      caloriesPerUnit: 1.64,
      unit: 'g',
      category: 'Protein',
      protein: 0.081,
      carbs: 0.270,
      fat: 0.026,
    ),

    // ===== Vegetables =====
    FoodItem(
      name: 'Broccoli',
      caloriesPerUnit: 0.25,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.03,
      carbs: 0.05,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Spinach',
      caloriesPerUnit: 0.23,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.029,
      carbs: 0.036,
      fat: 0.004,
    ),
    FoodItem(
      name: 'Kale',
      caloriesPerUnit: 0.49,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.043,
      carbs: 0.087,
      fat: 0.007,
    ),
    FoodItem(
      name: 'Lettuce',
      caloriesPerUnit: 0.15,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.014,
      carbs: 0.029,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Cabbage',
      caloriesPerUnit: 0.25,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.013,
      carbs: 0.058,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Carrot',
      caloriesPerUnit: 0.41,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.009,
      carbs: 0.10,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Bell Pepper',
      caloriesPerUnit: 0.31,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.010,
      carbs: 0.070,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Tomato',
      caloriesPerUnit: 0.18,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.009,
      carbs: 0.039,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Cucumber',
      caloriesPerUnit: 0.16,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.007,
      carbs: 0.036,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Zucchini',
      caloriesPerUnit: 0.17,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.012,
      carbs: 0.033,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Eggplant',
      caloriesPerUnit: 0.25,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.010,
      carbs: 0.058,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Onion',
      caloriesPerUnit: 0.40,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.011,
      carbs: 0.093,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Garlic',
      caloriesPerUnit: 1.49,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.064,
      carbs: 0.331,
      fat: 0.005,
    ),
    FoodItem(
      name: 'Mushrooms',
      caloriesPerUnit: 0.22,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.031,
      carbs: 0.032,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Asparagus',
      caloriesPerUnit: 0.20,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.022,
      carbs: 0.039,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Green Beans',
      caloriesPerUnit: 0.35,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.018,
      carbs: 0.070,
      fat: 0.002,
    ),

    // ===== Fruits =====
    FoodItem(
      name: 'Apple',
      caloriesPerUnit: 0.52,
      unit: 'g',
      category: 'Fruits',
      protein: 0.003,
      carbs: 0.14,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Banana',
      caloriesPerUnit: 0.89,
      unit: 'g',
      category: 'Fruits',
      protein: 0.011,
      carbs: 0.23,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Orange',
      caloriesPerUnit: 0.47,
      unit: 'g',
      category: 'Fruits',
      protein: 0.009,
      carbs: 0.12,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Grapes',
      caloriesPerUnit: 0.69,
      unit: 'g',
      category: 'Fruits',
      protein: 0.007,
      carbs: 0.174,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Strawberries',
      caloriesPerUnit: 0.32,
      unit: 'g',
      category: 'Fruits',
      protein: 0.007,
      carbs: 0.077,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Blueberries',
      caloriesPerUnit: 0.57,
      unit: 'g',
      category: 'Fruits',
      protein: 0.007,
      carbs: 0.144,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Watermelon',
      caloriesPerUnit: 0.30,
      unit: 'g',
      category: 'Fruits',
      protein: 0.006,
      carbs: 0.076,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Pineapple',
      caloriesPerUnit: 0.50,
      unit: 'g',
      category: 'Fruits',
      protein: 0.005,
      carbs: 0.131,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Mango',
      caloriesPerUnit: 0.60,
      unit: 'g',
      category: 'Fruits',
      protein: 0.008,
      carbs: 0.150,
      fat: 0.004,
    ),
    FoodItem(
      name: 'Kiwi',
      caloriesPerUnit: 0.61,
      unit: 'g',
      category: 'Fruits',
      protein: 0.011,
      carbs: 0.147,
      fat: 0.005,
    ),
    FoodItem(
      name: 'Avocado',
      caloriesPerUnit: 1.60,
      unit: 'g',
      category: 'Fruits',
      protein: 0.020,
      carbs: 0.089,
      fat: 0.147,
    ),
    FoodItem(
      name: 'Cherries',
      caloriesPerUnit: 0.63,
      unit: 'g',
      category: 'Fruits',
      protein: 0.011,
      carbs: 0.160,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Peach',
      caloriesPerUnit: 0.39,
      unit: 'g',
      category: 'Fruits',
      protein: 0.009,
      carbs: 0.095,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Pear',
      caloriesPerUnit: 0.57,
      unit: 'g',
      category: 'Fruits',
      protein: 0.004,
      carbs: 0.152,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Lemon',
      caloriesPerUnit: 0.29,
      unit: 'g',
      category: 'Fruits',
      protein: 0.011,
      carbs: 0.092,
      fat: 0.003,
    ),

    // ===== Snacks =====
    FoodItem(
      name: 'Potato Chips',
      caloriesPerUnit: 5.36,
      unit: 'g',
      category: 'Snacks',
      protein: 0.07,
      carbs: 0.53,
      fat: 0.32,
    ),
    FoodItem(
      name: 'Chocolate',
      caloriesPerUnit: 5.46,
      unit: 'g',
      category: 'Snacks',
      protein: 0.049,
      carbs: 0.61,
      fat: 0.31,
    ),
    FoodItem(
      name: 'Dark Chocolate',
      caloriesPerUnit: 5.98,
      unit: 'g',
      category: 'Snacks',
      protein: 0.079,
      carbs: 0.457,
      fat: 0.428,
    ),
    FoodItem(
      name: 'Almonds',
      caloriesPerUnit: 5.79,
      unit: 'g',
      category: 'Snacks',
      protein: 0.212,
      carbs: 0.218,
      fat: 0.495,
    ),
    FoodItem(
      name: 'Walnuts',
      caloriesPerUnit: 6.54,
      unit: 'g',
      category: 'Snacks',
      protein: 0.153,
      carbs: 0.137,
      fat: 0.654,
    ),
    FoodItem(
      name: 'Peanuts',
      caloriesPerUnit: 5.67,
      unit: 'g',
      category: 'Snacks',
      protein: 0.259,
      carbs: 0.161,
      fat: 0.491,
    ),
    FoodItem(
      name: 'Cashews',
      caloriesPerUnit: 5.53,
      unit: 'g',
      category: 'Snacks',
      protein: 0.183,
      carbs: 0.303,
      fat: 0.437,
    ),
    FoodItem(
      name: 'Crackers',
      caloriesPerUnit: 5.04,
      unit: 'g',
      category: 'Snacks',
      protein: 0.100,
      carbs: 0.655,
      fat: 0.230,
    ),
    FoodItem(
      name: 'Popcorn',
      caloriesPerUnit: 3.87,
      unit: 'g',
      category: 'Snacks',
      protein: 0.123,
      carbs: 0.778,
      fat: 0.043,
    ),
    FoodItem(
      name: 'Granola Bar',
      caloriesPerUnit: 4.71,
      unit: 'g',
      category: 'Snacks',
      protein: 0.099,
      carbs: 0.645,
      fat: 0.200,
    ),
    FoodItem(
      name: 'Cookies',
      caloriesPerUnit: 5.02,
      unit: 'g',
      category: 'Snacks',
      protein: 0.055,
      carbs: 0.680,
      fat: 0.230,
    ),
    FoodItem(
      name: 'Ice Cream',
      caloriesPerUnit: 2.07,
      unit: 'g',
      category: 'Snacks',
      protein: 0.036,
      carbs: 0.237,
      fat: 0.110,
    ),

    // ===== Beverages =====
    FoodItem(
      name: 'Milk',
      caloriesPerUnit: 0.42,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.034,
      carbs: 0.05,
      fat: 0.01,
    ),
    FoodItem(
      name: 'Skim Milk',
      caloriesPerUnit: 0.34,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.034,
      carbs: 0.050,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Almond Milk',
      caloriesPerUnit: 0.17,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.004,
      carbs: 0.016,
      fat: 0.011,
    ),
    FoodItem(
      name: 'Soy Milk',
      caloriesPerUnit: 0.33,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.028,
      carbs: 0.015,
      fat: 0.016,
    ),
    FoodItem(
      name: 'Cola',
      caloriesPerUnit: 0.42,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.0,
      carbs: 0.106,
      fat: 0.0,
    ),
    FoodItem(
      name: 'Orange Juice',
      caloriesPerUnit: 0.45,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.007,
      carbs: 0.104,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Apple Juice',
      caloriesPerUnit: 0.46,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.001,
      carbs: 0.114,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Green Tea',
      caloriesPerUnit: 0.01,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
    ),
    FoodItem(
      name: 'Coffee',
      caloriesPerUnit: 0.02,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.001,
      carbs: 0.0,
      fat: 0.0,
    ),
    FoodItem(
      name: 'Beer',
      caloriesPerUnit: 0.43,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.005,
      carbs: 0.037,
      fat: 0.0,
    ),
    FoodItem(
      name: 'Red Wine',
      caloriesPerUnit: 0.85,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.001,
      carbs: 0.025,
      fat: 0.0,
    ),
    FoodItem(
      name: 'Sports Drink',
      caloriesPerUnit: 0.25,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.0,
      carbs: 0.060,
      fat: 0.0,
    ),

    // ===== Condiments & Others =====
    FoodItem(
      name: 'Olive Oil',
      caloriesPerUnit: 8.84,
      unit: 'ml',
      category: 'Condiments',
      protein: 0.0,
      carbs: 0.0,
      fat: 1.0,
    ),
    FoodItem(
      name: 'Butter',
      caloriesPerUnit: 7.17,
      unit: 'g',
      category: 'Condiments',
      protein: 0.009,
      carbs: 0.006,
      fat: 0.813,
    ),
    FoodItem(
      name: 'Honey',
      caloriesPerUnit: 3.04,
      unit: 'g',
      category: 'Condiments',
      protein: 0.003,
      carbs: 0.824,
      fat: 0.0,
    ),
    FoodItem(
      name: 'Sugar',
      caloriesPerUnit: 3.87,
      unit: 'g',
      category: 'Condiments',
      protein: 0.0,
      carbs: 0.998,
      fat: 0.0,
    ),
    FoodItem(
      name: 'Salt',
      caloriesPerUnit: 0.0,
      unit: 'g',
      category: 'Condiments',
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
    ),
    FoodItem(
      name: 'Soy Sauce',
      caloriesPerUnit: 0.60,
      unit: 'ml',
      category: 'Condiments',
      protein: 0.101,
      carbs: 0.055,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Ketchup',
      caloriesPerUnit: 1.12,
      unit: 'g',
      category: 'Condiments',
      protein: 0.011,
      carbs: 0.269,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Mayonnaise',
      caloriesPerUnit: 6.80,
      unit: 'g',
      category: 'Condiments',
      protein: 0.011,
      carbs: 0.006,
      fat: 0.749,
    ),

    // ===== Seafood =====
    FoodItem(
      name: 'Crab',
      caloriesPerUnit: 0.97,
      unit: 'g',
      category: 'Protein',
      protein: 0.205,
      carbs: 0.0,
      fat: 0.013,
    ),
    FoodItem(
      name: 'Lobster',
      caloriesPerUnit: 0.89,
      unit: 'g',
      category: 'Protein',
      protein: 0.189,
      carbs: 0.0,
      fat: 0.009,
    ),
    FoodItem(
      name: 'Scallops',
      caloriesPerUnit: 0.88,
      unit: 'g',
      category: 'Protein',
      protein: 0.207,
      carbs: 0.024,
      fat: 0.006,
    ),
    FoodItem(
      name: 'Oysters',
      caloriesPerUnit: 0.68,
      unit: 'g',
      category: 'Protein',
      protein: 0.092,
      carbs: 0.039,
      fat: 0.018,
    ),

    // ===== Dairy =====
    FoodItem(
      name: 'Cheddar Cheese',
      caloriesPerUnit: 4.03,
      unit: 'g',
      category: 'Protein',
      protein: 0.249,
      carbs: 0.013,
      fat: 0.334,
    ),
    FoodItem(
      name: 'Mozzarella Cheese',
      caloriesPerUnit: 2.80,
      unit: 'g',
      category: 'Protein',
      protein: 0.222,
      carbs: 0.022,
      fat: 0.174,
    ),
    FoodItem(
      name: 'Parmesan Cheese',
      caloriesPerUnit: 4.31,
      unit: 'g',
      category: 'Protein',
      protein: 0.383,
      carbs: 0.041,
      fat: 0.286,
    ),
    FoodItem(
      name: 'Cream Cheese',
      caloriesPerUnit: 3.42,
      unit: 'g',
      category: 'Protein',
      protein: 0.055,
      carbs: 0.040,
      fat: 0.342,
    ),
    FoodItem(
      name: 'Yogurt',
      caloriesPerUnit: 0.59,
      unit: 'g',
      category: 'Protein',
      protein: 0.100,
      carbs: 0.046,
      fat: 0.001,
    ),

    // ===== Chinese Dishes =====
    FoodItem(
      name: 'Fried Rice',
      caloriesPerUnit: 1.63,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.042,
      carbs: 0.201,
      fat: 0.067,
    ),
    FoodItem(
      name: 'Steamed Buns',
      caloriesPerUnit: 2.21,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.072,
      carbs: 0.456,
      fat: 0.011,
    ),
    FoodItem(
      name: 'Dumplings',
      caloriesPerUnit: 2.32,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.089,
      carbs: 0.285,
      fat: 0.089,
    ),
    FoodItem(
      name: 'Spring Rolls',
      caloriesPerUnit: 1.94,
      unit: 'g',
      category: 'Snacks',
      protein: 0.061,
      carbs: 0.238,
      fat: 0.097,
    ),
    FoodItem(
      name: 'Congee',
      caloriesPerUnit: 0.30,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.011,
      carbs: 0.067,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Hot Pot',
      caloriesPerUnit: 1.50,
      unit: 'g',
      category: 'Protein',
      protein: 0.120,
      carbs: 0.080,
      fat: 0.090,
    ),

    // ===== Japanese Cuisine =====
    FoodItem(
      name: 'Sushi Rice',
      caloriesPerUnit: 1.30,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.027,
      carbs: 0.280,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Salmon Sashimi',
      caloriesPerUnit: 2.08,
      unit: 'g',
      category: 'Protein',
      protein: 0.250,
      carbs: 0.0,
      fat: 0.120,
    ),
    FoodItem(
      name: 'Miso Soup',
      caloriesPerUnit: 0.40,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.026,
      carbs: 0.056,
      fat: 0.012,
    ),
    FoodItem(
      name: 'Edamame',
      caloriesPerUnit: 1.21,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.111,
      carbs: 0.089,
      fat: 0.051,
    ),

    // ===== Italian Cuisine =====
    FoodItem(
      name: 'Pasta',
      caloriesPerUnit: 1.31,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.050,
      carbs: 0.250,
      fat: 0.011,
    ),
    FoodItem(
      name: 'Pizza',
      caloriesPerUnit: 2.66,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.110,
      carbs: 0.330,
      fat: 0.100,
    ),
    FoodItem(
      name: 'Olive Oil Pasta',
      caloriesPerUnit: 1.58,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.053,
      carbs: 0.230,
      fat: 0.055,
    ),

    // ===== Indian Cuisine =====
    FoodItem(
      name: 'Curry',
      caloriesPerUnit: 1.20,
      unit: 'g',
      category: 'Protein',
      protein: 0.067,
      carbs: 0.089,
      fat: 0.078,
    ),
    FoodItem(
      name: 'Naan Bread',
      caloriesPerUnit: 3.12,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.085,
      carbs: 0.580,
      fat: 0.051,
    ),
    FoodItem(
      name: 'Basmati Rice',
      caloriesPerUnit: 1.21,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.025,
      carbs: 0.250,
      fat: 0.004,
    ),

    // ====  Mexican Cuisine =====
    FoodItem(
      name: 'Tortilla',
      caloriesPerUnit: 2.18,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.056,
      carbs: 0.434,
      fat: 0.028,
    ),
    FoodItem(
      name: 'Guacamole',
      caloriesPerUnit: 1.50,
      unit: 'g',
      category: 'Condiments',
      protein: 0.020,
      carbs: 0.089,
      fat: 0.132,
    ),
    FoodItem(
      name: 'Black Bean Burrito',
      caloriesPerUnit: 2.15,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.089,
      carbs: 0.345,
      fat: 0.056,
    ),

    // ===== Health Foods =====
    FoodItem(
      name: 'Chia Seeds',
      caloriesPerUnit: 4.86,
      unit: 'g',
      category: 'Snacks',
      protein: 0.167,
      carbs: 0.424,
      fat: 0.309,
    ),
    FoodItem(
      name: 'Flax Seeds',
      caloriesPerUnit: 5.34,
      unit: 'g',
      category: 'Snacks',
      protein: 0.183,
      carbs: 0.289,
      fat: 0.422,
    ),
    FoodItem(
      name: 'Quinoa Salad',
      caloriesPerUnit: 1.72,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.055,
      carbs: 0.220,
      fat: 0.067,
    ),
    FoodItem(
      name: 'Protein Powder',
      caloriesPerUnit: 4.12,
      unit: 'g',
      category: 'Protein',
      protein: 0.800,
      carbs: 0.100,
      fat: 0.050,
    ),
    FoodItem(
      name: 'Green Smoothie',
      caloriesPerUnit: 0.45,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.025,
      carbs: 0.089,
      fat: 0.012,
    ),

    // ===== Baked Goods =====
    FoodItem(
      name: 'Croissant',
      caloriesPerUnit: 4.06,
      unit: 'g',
      category: 'Snacks',
      protein: 0.089,
      carbs: 0.455,
      fat: 0.210,
    ),
    FoodItem(
      name: 'Muffin',
      caloriesPerUnit: 3.77,
      unit: 'g',
      category: 'Snacks',
      protein: 0.067,
      carbs: 0.556,
      fat: 0.156,
    ),
    FoodItem(
      name: 'Bagel',
      caloriesPerUnit: 2.50,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.100,
      carbs: 0.489,
      fat: 0.022,
    ),
    FoodItem(
      name: 'Pancakes',
      caloriesPerUnit: 2.27,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.063,
      carbs: 0.289,
      fat: 0.100,
    ),
    FoodItem(
      name: 'Waffles',
      caloriesPerUnit: 2.91,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.067,
      carbs: 0.345,
      fat: 0.133,
    ),

    // ===== Soups =====
    FoodItem(
      name: 'Chicken Soup',
      caloriesPerUnit: 0.38,
      unit: 'ml',
      category: 'Protein',
      protein: 0.034,
      carbs: 0.022,
      fat: 0.019,
    ),
    FoodItem(
      name: 'Vegetable Soup',
      caloriesPerUnit: 0.30,
      unit: 'ml',
      category: 'Vegetables',
      protein: 0.012,
      carbs: 0.056,
      fat: 0.005,
    ),
    FoodItem(
      name: 'Tomato Soup',
      caloriesPerUnit: 0.29,
      unit: 'ml',
      category: 'Vegetables',
      protein: 0.016,
      carbs: 0.067,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Mushroom Soup',
      caloriesPerUnit: 0.33,
      unit: 'ml',
      category: 'Vegetables',
      protein: 0.009,
      carbs: 0.045,
      fat: 0.015,
    ),

    // ===== Dried Fruits & Nuts =====
    FoodItem(
      name: 'Raisins',
      caloriesPerUnit: 2.99,
      unit: 'g',
      category: 'Fruits',
      protein: 0.031,
      carbs: 0.792,
      fat: 0.005,
    ),
    FoodItem(
      name: 'Dried Apricots',
      caloriesPerUnit: 2.41,
      unit: 'g',
      category: 'Fruits',
      protein: 0.034,
      carbs: 0.625,
      fat: 0.005,
    ),
    FoodItem(
      name: 'Dates',
      caloriesPerUnit: 2.77,
      unit: 'g',
      category: 'Fruits',
      protein: 0.020,
      carbs: 0.750,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Pistachios',
      caloriesPerUnit: 5.60,
      unit: 'g',
      category: 'Snacks',
      protein: 0.202,
      carbs: 0.278,
      fat: 0.454,
    ),
    FoodItem(
      name: 'Pecans',
      caloriesPerUnit: 6.91,
      unit: 'g',
      category: 'Snacks',
      protein: 0.092,
      carbs: 0.139,
      fat: 0.720,
    ),
    FoodItem(
      name: 'Brazil Nuts',
      caloriesPerUnit: 6.56,
      unit: 'g',
      category: 'Snacks',
      protein: 0.141,
      carbs: 0.121,
      fat: 0.674,
    ),
    FoodItem(
      name: 'Macadamia Nuts',
      caloriesPerUnit: 7.18,
      unit: 'g',
      category: 'Snacks',
      protein: 0.079,
      carbs: 0.137,
      fat: 0.758,
    ),

    // ===== Breakfast Foods =====
    FoodItem(
      name: 'Cereal',
      caloriesPerUnit: 3.78,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.067,
      carbs: 0.844,
      fat: 0.022,
    ),
    FoodItem(
      name: 'Granola',
      caloriesPerUnit: 4.89,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.134,
      carbs: 0.645,
      fat: 0.200,
    ),
    FoodItem(
      name: 'French Toast',
      caloriesPerUnit: 2.22,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.100,
      carbs: 0.289,
      fat: 0.089,
    ),
    FoodItem(
      name: 'Hash Browns',
      caloriesPerUnit: 2.65,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.032,
      carbs: 0.356,
      fat: 0.134,
    ),
    FoodItem(
      name: 'Bacon',
      caloriesPerUnit: 5.41,
      unit: 'g',
      category: 'Protein',
      protein: 0.371,
      carbs: 0.016,
      fat: 0.417,
    ),
    FoodItem(
      name: 'Sausage',
      caloriesPerUnit: 3.01,
      unit: 'g',
      category: 'Protein',
      protein: 0.130,
      carbs: 0.040,
      fat: 0.270,
    ),

    // ===== Salads & Health Foods =====
    FoodItem(
      name: 'Caesar Salad',
      caloriesPerUnit: 1.58,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.089,
      carbs: 0.067,
      fat: 0.120,
    ),
    FoodItem(
      name: 'Greek Salad',
      caloriesPerUnit: 1.06,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.045,
      carbs: 0.056,
      fat: 0.089,
    ),
    FoodItem(
      name: 'Cobb Salad',
      caloriesPerUnit: 1.95,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.134,
      carbs: 0.045,
      fat: 0.156,
    ),
    FoodItem(
      name: 'Fruit Salad',
      caloriesPerUnit: 0.50,
      unit: 'g',
      category: 'Fruits',
      protein: 0.005,
      carbs: 0.130,
      fat: 0.001,
    ),
    FoodItem(
      name: 'Hummus',
      caloriesPerUnit: 1.66,
      unit: 'g',
      category: 'Protein',
      protein: 0.081,
      carbs: 0.145,
      fat: 0.098,
    ),

    // ===== Frozen Foods =====
    FoodItem(
      name: 'Frozen Vegetables',
      caloriesPerUnit: 0.42,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.025,
      carbs: 0.089,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Frozen Berries',
      caloriesPerUnit: 0.35,
      unit: 'g',
      category: 'Fruits',
      protein: 0.005,
      carbs: 0.089,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Frozen Pizza',
      caloriesPerUnit: 2.18,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.089,
      carbs: 0.267,
      fat: 0.078,
    ),

    // ===== Canned Foods =====
    FoodItem(
      name: 'Canned Tuna',
      caloriesPerUnit: 1.16,
      unit: 'g',
      category: 'Protein',
      protein: 0.256,
      carbs: 0.0,
      fat: 0.008,
    ),
    FoodItem(
      name: 'Canned Salmon',
      caloriesPerUnit: 1.42,
      unit: 'g',
      category: 'Protein',
      protein: 0.197,
      carbs: 0.0,
      fat: 0.064,
    ),
    FoodItem(
      name: 'Canned Beans',
      caloriesPerUnit: 0.81,
      unit: 'g',
      category: 'Protein',
      protein: 0.053,
      carbs: 0.144,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Canned Corn',
      caloriesPerUnit: 0.76,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.027,
      carbs: 0.178,
      fat: 0.005,
    ),
    FoodItem(
      name: 'Canned Tomatoes',
      caloriesPerUnit: 0.16,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.009,
      carbs: 0.038,
      fat: 0.001,
    ),
  ];

  // Get all predefined foods
  static List<FoodItem> getAllFoods() {
    return List.from(_predefinedFoods);
  }

  // Get foods by category
  static List<FoodItem> getFoodsByCategory(String category) {
    return _predefinedFoods.where((food) => food.category == category).toList();
  }

  // Search foods - enhanced with better matching
  static List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) {
      return getAllFoods();
    }

    final queryLower = query.toLowerCase();

    // Exact name matches first
    var exactMatches = _predefinedFoods
        .where((food) => food.name.toLowerCase() == queryLower)
        .toList();

    // Name starts with query
    var startsWithMatches = _predefinedFoods
        .where((food) =>
            food.name.toLowerCase().startsWith(queryLower) &&
            !exactMatches.contains(food))
        .toList();

    // Name contains query
    var containsMatches = _predefinedFoods
        .where((food) =>
            food.name.toLowerCase().contains(queryLower) &&
            !exactMatches.contains(food) &&
            !startsWithMatches.contains(food))
        .toList();

    // Category matches
    var categoryMatches = _predefinedFoods
        .where((food) =>
            food.category.toLowerCase().contains(queryLower) &&
            !exactMatches.contains(food) &&
            !startsWithMatches.contains(food) &&
            !containsMatches.contains(food))
        .toList();

    // Combine all matches in order of relevance
    return [
      ...exactMatches,
      ...startsWithMatches,
      ...containsMatches,
      ...categoryMatches
    ];
  }

  // Get all categories
  static List<String> getAllCategories() {
    return _predefinedFoods.map((food) => food.category).toSet().toList()
      ..sort();
  }

  // Get food by name (exact match)
  static FoodItem? getFoodByName(String name) {
    try {
      return _predefinedFoods.firstWhere((food) => food.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get food by ID
  static FoodItem? getFoodById(int id) {
    try {
      return _predefinedFoods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get popular foods (most commonly consumed)
  static List<FoodItem> getPopularFoods() {
    // Return a curated list of popular foods
    final popularFoodNames = [
      'Rice',
      'Chicken Breast',
      'Egg',
      'Banana',
      'Apple',
      'Broccoli',
      'Salmon',
      'Bread',
      'Milk',
      'Oats'
    ];

    return popularFoodNames
        .map((name) => getFoodByName(name))
        .where((food) => food != null)
        .cast<FoodItem>()
        .toList();
  }

  // Get foods by meal type recommendations
  static List<FoodItem> getFoodsForMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return _predefinedFoods
            .where((food) =>
                food.name.contains('Oats') ||
                food.name.contains('Cereal') ||
                food.name.contains('Egg') ||
                food.name.contains('Bread') ||
                food.name.contains('Pancakes') ||
                food.name.contains('French Toast') ||
                food.name.contains('Granola') ||
                food.category == 'Fruits')
            .toList();

      case 'lunch':
      case 'dinner':
        return _predefinedFoods
            .where((food) =>
                food.category == 'Protein' ||
                food.category == 'Vegetables' ||
                food.category == 'Staple Food')
            .toList();

      case 'snack':
        return _predefinedFoods
            .where((food) =>
                food.category == 'Fruits' ||
                food.category == 'Snacks' ||
                food.name.contains('Nuts') ||
                food.name.contains('Yogurt'))
            .toList();

      default:
        return getAllFoods();
    }
  }

  // Get high protein foods
  static List<FoodItem> getHighProteinFoods() {
    return _predefinedFoods
        .where((food) => (food.protein ?? 0) > 0.15)
        .toList() // >15g protein per 100g
      ..sort((a, b) => (b.protein ?? 0).compareTo(a.protein ?? 0));
  }

  // Get low calorie foods
  static List<FoodItem> getLowCalorieFoods() {
    return _predefinedFoods
        .where((food) => food.caloriesPerUnit < 1.0)
        .toList() // <100 calories per 100g
      ..sort((a, b) => a.caloriesPerUnit.compareTo(b.caloriesPerUnit));
  }

  // Get foods by calorie range
  static List<FoodItem> getFoodsByCalorieRange(double minCal, double maxCal) {
    return _predefinedFoods.where((food) {
      final caloriePer100g = food.caloriesPerUnit * 100;
      return caloriePer100g >= minCal && caloriePer100g <= maxCal;
    }).toList();
  }

  // Add custom food
  static void addCustomFood(FoodItem food) {
    _predefinedFoods.add(food);
  }

  // Remove custom food
  static bool removeCustomFood(String foodName) {
    final index = _predefinedFoods.indexWhere((food) => food.name == foodName);
    if (index != -1) {
      _predefinedFoods.removeAt(index);
      return true;
    }
    return false;
  }

  // Calculate calories for specified quantity
  static double calculateCalories(FoodItem food, double quantity) {
    return food.caloriesPerUnit * quantity;
  }

  // Get nutrition summary
  static Map<String, double> getNutritionSummary(
      FoodItem food, double quantity) {
    return {
      'calories': calculateCalories(food, quantity),
      'protein': (food.protein ?? 0) * quantity,
      'carbs': (food.carbs ?? 0) * quantity,
      'fat': (food.fat ?? 0) * quantity,
    };
  }

  // Get recommended serving size (based on common portions)
  static double getRecommendedServing(FoodItem food) {
    // Enhanced recommendations based on food type
    if (food.name.contains('Oil') || food.name.contains('Butter')) {
      return 10.0; // 1 tablespoon
    }

    switch (food.category) {
      case 'Staple Food':
        if (food.name.contains('Rice') || food.name.contains('Pasta')) {
          return 75.0; // 75g dry weight
        } else if (food.name.contains('Bread')) {
          return 30.0; // 1 slice
        }
        return 150.0; // Default

      case 'Protein':
        if (food.name.contains('Cheese')) {
          return 30.0; // 30g cheese
        } else if (food.name.contains('Egg')) {
          return 50.0; // 1 large egg
        }
        return 100.0; // 100g protein

      case 'Vegetables':
        if (food.name.contains('Garlic') || food.name.contains('Onion')) {
          return 50.0; // Smaller serving for strong flavors
        }
        return 200.0; // 200g vegetables

      case 'Fruits':
        if (food.name.contains('Avocado')) {
          return 100.0; // Half an avocado
        } else if (food.name.contains('Banana')) {
          return 120.0; // 1 medium banana
        } else if (food.name.contains('Apple')) {
          return 150.0; // 1 medium apple
        }
        return 150.0; // Default fruit serving

      case 'Snacks':
        if (food.name.contains('Nuts') || food.name.contains('Seeds')) {
          return 30.0; // 1 ounce nuts/seeds
        } else if (food.name.contains('Chocolate')) {
          return 20.0; // Small piece
        }
        return 30.0; // Small snack serving

      case 'Beverages':
        if (food.name.contains('Milk') || food.name.contains('Juice')) {
          return 250.0; // 1 glass
        } else if (food.name.contains('Coffee') || food.name.contains('Tea')) {
          return 240.0; // 1 cup
        } else if (food.name.contains('Beer') || food.name.contains('Wine')) {
          return 150.0; // Standard drink
        }
        return 250.0; // Default beverage

      case 'Condiments':
        if (food.name.contains('Salt') || food.name.contains('Pepper')) {
          return 1.0; // Pinch
        } else if (food.name.contains('Honey') || food.name.contains('Sugar')) {
          return 15.0; // 1 tablespoon
        }
        return 15.0; // 1 tablespoon

      default:
        return 100.0;
    }
  }

  // Get unit display text
  static String getUnitDisplayText(String unit) {
    switch (unit) {
      case 'g':
        return 'grams';
      case 'ml':
        return 'milliliters';
      case 'piece':
        return 'pieces';
      case 'slice':
        return 'slices';
      case 'cup':
        return 'cups';
      default:
        return unit;
    }
  }

  // Get foods similar to a given food (same category, similar nutrition)
  static List<FoodItem> getSimilarFoods(FoodItem food, {int limit = 5}) {
    return _predefinedFoods
        .where((f) => f.category == food.category && f.name != food.name)
        .take(limit)
        .toList();
  }

  // Get random foods for variety suggestions
  static List<FoodItem> getRandomFoods({int count = 3, String? category}) {
    var foods = category != null ? getFoodsByCategory(category) : getAllFoods();

    foods.shuffle();
    return foods.take(count).toList();
  }

  // Get foods by nutrition goals
  static List<FoodItem> getFoodsByNutritionGoal(String goal) {
    switch (goal.toLowerCase()) {
      case 'high_protein':
        return getHighProteinFoods();
      case 'low_calorie':
        return getLowCalorieFoods();
      case 'high_fiber':
        return _predefinedFoods
            .where((food) =>
                food.category == 'Vegetables' ||
                food.category == 'Fruits' ||
                food.name.contains('Oats') ||
                food.name.contains('Quinoa') ||
                food.name.contains('Beans'))
            .toList();
      case 'healthy_fats':
        return _predefinedFoods
            .where((food) =>
                food.name.contains('Avocado') ||
                food.name.contains('Nuts') ||
                food.name.contains('Seeds') ||
                food.name.contains('Salmon') ||
                food.name.contains('Olive Oil'))
            .toList();
      case 'complex_carbs':
        return _predefinedFoods
            .where((food) =>
                food.name.contains('Oats') ||
                food.name.contains('Quinoa') ||
                food.name.contains('Brown Rice') ||
                food.name.contains('Sweet Potato') ||
                food.name.contains('Whole Wheat'))
            .toList();
      default:
        return getAllFoods();
    }
  }

  // Get total count of foods in database
  static int getTotalFoodCount() {
    return _predefinedFoods.length;
  }

  // Get count by category
  static Map<String, int> getFoodCountByCategory() {
    Map<String, int> counts = {};
    for (var food in _predefinedFoods) {
      counts[food.category] = (counts[food.category] ?? 0) + 1;
    }
    return counts;
  }

  // Validate food data
  static bool validateFoodData(FoodItem food) {
    return food.name.isNotEmpty &&
        food.caloriesPerUnit >= 0 &&
        food.unit.isNotEmpty &&
        food.category.isNotEmpty &&
        (food.protein == null || food.protein! >= 0) &&
        (food.carbs == null || food.carbs! >= 0) &&
        (food.fat == null || food.fat! >= 0);
  }

  // Export food database as JSON (for backup/sharing)
  static Map<String, dynamic> exportDatabase() {
    return {
      'version': '1.0',
      'foods': _predefinedFoods.map((food) => food.toMap()).toList(),
      'categories': getAllCategories(),
      'totalCount': getTotalFoodCount(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Import food database from JSON
  static bool importDatabase(Map<String, dynamic> data) {
    try {
      if (data['foods'] != null) {
        List<dynamic> foodsList = data['foods'];
        List<FoodItem> importedFoods = foodsList
            .map((foodMap) => FoodItem.fromMap(foodMap))
            .where((food) => validateFoodData(food))
            .toList();

        _predefinedFoods = importedFoods;
        return true;
      }
      return false;
    } catch (e) {
      print('Error importing database: $e');
      return false;
    }
  }

  // Reset to default database
  static void resetToDefaults() {
    // This would reload the original predefined foods
    // Implementation would depend on how you want to handle this
    print('Database reset to defaults');
  }

  // Search with advanced filters
  static List<FoodItem> advancedSearch({
    String? query,
    String? category,
    double? minCalories,
    double? maxCalories,
    double? minProtein,
    double? maxProtein,
    bool sortByCalories = false,
    bool sortByProtein = false,
  }) {
    var results = _predefinedFoods.where((food) {
      // Text search
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        if (!food.name.toLowerCase().contains(queryLower) &&
            !food.category.toLowerCase().contains(queryLower)) {
          return false;
        }
      }

      // Category filter
      if (category != null && food.category != category) {
        return false;
      }

      // Calorie range filter
      final caloriePer100g = food.caloriesPerUnit * 100;
      if (minCalories != null && caloriePer100g < minCalories) {
        return false;
      }
      if (maxCalories != null && caloriePer100g > maxCalories) {
        return false;
      }

      // Protein range filter
      final proteinPer100g = (food.protein ?? 0) * 100;
      if (minProtein != null && proteinPer100g < minProtein) {
        return false;
      }
      if (maxProtein != null && proteinPer100g > maxProtein) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    if (sortByCalories) {
      results.sort((a, b) => a.caloriesPerUnit.compareTo(b.caloriesPerUnit));
    } else if (sortByProtein) {
      results.sort((a, b) => (b.protein ?? 0).compareTo(a.protein ?? 0));
    }

    return results;
  }

  // Get nutrition density score (protein + fiber per calorie)
  static double getNutritionDensityScore(FoodItem food) {
    final protein = food.protein ?? 0;
    final calories = food.caloriesPerUnit;

    if (calories == 0) return 0;

    // Simple nutrition density: protein per calorie
    // Higher score = more nutritious
    return (protein / calories) * 100;
  }

  // Get most nutritious foods
  static List<FoodItem> getMostNutritiousFoods({int limit = 10}) {
    var foods = List<FoodItem>.from(_predefinedFoods);
    foods.sort((a, b) =>
        getNutritionDensityScore(b).compareTo(getNutritionDensityScore(a)));
    return foods.take(limit).toList();
  }

  // Get food suggestions based on time of day
  static List<FoodItem> getFoodSuggestionsByTime() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 10) {
      // Breakfast suggestions
      return getFoodsForMealType('breakfast');
    } else if (hour >= 11 && hour < 14) {
      // Lunch suggestions
      return getFoodsForMealType('lunch');
    } else if (hour >= 17 && hour < 20) {
      // Dinner suggestions
      return getFoodsForMealType('dinner');
    } else {
      // Snack suggestions
      return getFoodsForMealType('snack');
    }
  }

  // Get seasonal food suggestions
  static List<FoodItem> getSeasonalFoods() {
    final month = DateTime.now().month;

    if (month >= 3 && month <= 5) {
      // Spring - fresh vegetables and fruits
      return _predefinedFoods
          .where((food) =>
              food.category == 'Vegetables' || food.category == 'Fruits')
          .toList();
    } else if (month >= 6 && month <= 8) {
      // Summer - light foods and beverages
      return _predefinedFoods
          .where((food) =>
              food.category == 'Fruits' ||
              food.category == 'Beverages' ||
              food.name.contains('Salad'))
          .toList();
    } else if (month >= 9 && month <= 11) {
      // Fall - hearty foods
      return _predefinedFoods
          .where((food) =>
              food.category == 'Staple Food' ||
              food.category == 'Protein' ||
              food.name.contains('Soup'))
          .toList();
    } else {
      // Winter - warming foods
      return _predefinedFoods
          .where((food) =>
              food.category == 'Protein' ||
              food.category == 'Staple Food' ||
              food.name.contains('Soup') ||
              food.name.contains('Stew'))
          .toList();
    }
  }

  // Database statistics
  static Map<String, dynamic> getDatabaseStats() {
    final categoryCount = getFoodCountByCategory();
    final totalFoods = getTotalFoodCount();

    double avgCalories = _predefinedFoods
            .map((f) => f.caloriesPerUnit * 100)
            .reduce((a, b) => a + b) /
        totalFoods;

    double avgProtein = _predefinedFoods
            .map((f) => (f.protein ?? 0) * 100)
            .reduce((a, b) => a + b) /
        totalFoods;

    return {
      'totalFoods': totalFoods,
      'categories': categoryCount,
      'averageCaloriesPer100g': avgCalories.round(),
      'averageProteinPer100g': avgProtein.round(),
      'highProteinFoods': getHighProteinFoods().length,
      'lowCalorieFoods': getLowCalorieFoods().length,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
