// lib/presentation/screens/learn_hub_screen.dart
import 'package:flutter/material.dart';

class LearnHubScreen extends StatefulWidget {
  const LearnHubScreen({super.key});

  @override
  State<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends State<LearnHubScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Business Basics', 'Finance', 'Marketing'];

  final List<Map<String, dynamic>> _lessons = [
    {
      'title': 'How to Price Your Products',
      'description': 'Learn competitive pricing strategies',
      'duration': '15 min',
      'category': 'Business Basics',
      'icon': Icons.attach_money,
      'color': 0xFF4CAF50,
    },
    {
      'title': 'Managing Customer Credit',
      'description': 'Safely offer credit to customers',
      'duration': '10 min',
      'category': 'Finance',
      'icon': Icons.credit_card,
      'color': 0xFF2196F3,
    },
    {
      'title': 'Saving for Your Business',
      'description': 'Build business savings effectively',
      'duration': '20 min',
      'category': 'Finance',
      'icon': Icons.savings,
      'color': 0xFFFF9800,
    },
    {
      'title': 'Record Keeping',
      'description': 'Simple bookkeeping methods',
      'duration': '25 min',
      'category': 'Business Basics',
      'icon': Icons.receipt,
      'color': 0xFF9C27B0,
    },
    {
      'title': 'Marketing on Social Media',
      'description': 'Reach more customers online',
      'duration': '18 min',
      'category': 'Marketing',
      'icon': Icons.campaign,
      'color': 0xFFE91E63,
    },
    {
      'title': 'Customer Service Tips',
      'description': 'Build loyalty and trust',
      'duration': '12 min',
      'category': 'Business Basics',
      'icon': Icons.support_agent,
      'color': 0xFF00BCD4,
    },
  ];

  List<Map<String, dynamic>> get _filteredLessons {
    return _lessons.where((lesson) {
      final matchesCategory = _selectedCategory == 'All' || lesson['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          lesson['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lesson['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Learn Hub',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search learning topics',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          
          // Category Filters: All | Business Basics | Finance | Marketing
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF4CAF50).withOpacity(0.1),
                    checkmarkColor: const Color(0xFF4CAF50),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Lessons List
          Expanded(
            child: _filteredLessons.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = _filteredLessons[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Lesson Icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(lesson['color']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                lesson['icon'],
                                color: Color(lesson['color']),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lesson['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      lesson['duration'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.play_circle_outline,
                              color: Color(0xFF4CAF50),
                              size: 32,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // View More Topics Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () {
                // Show more topics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('More topics coming soon!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              child: const Text(
                'View More Topics...',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No lessons found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Try selecting a different category'
                : 'No lessons match your search',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }
}