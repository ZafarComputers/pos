import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../models/season.dart' as season_model;

class SeasonListPage extends StatefulWidget {
  const SeasonListPage({super.key});

  @override
  State<SeasonListPage> createState() => _SeasonListPageState();
}

class _SeasonListPageState extends State<SeasonListPage> {
  List<season_model.Season> seasons = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;
  int totalSeasons = 0;
  final int itemsPerPage = 10;

  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'All';

  // Predefined seasons for dropdown selection
  final List<String> predefinedSeasons = [
    'Winter',
    'Summer',
    'Spring',
    'Fall',
    'Autumn',
    'Mid-Season',
    'All Seasons',
    'Holiday',
    'Festive',
    'Year Round',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSeasons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSeasons({int page = 1}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await InventoryService.getSeasons(
        page: page,
        limit: itemsPerPage,
      );

      if (!mounted) return;

      setState(() {
        seasons = response.data;
        currentPage = response.currentPage;
        totalPages = response.lastPage;
        totalSeasons = response.total;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void addNewSeason() async {
    String selectedSeason = predefinedSeasons.first;
    String selectedStatus = 'Active';

    final parentContext = context; // Store parent context

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.wb_sunny, color: Color(0xFFFFA726)),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Season',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF343A40),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Season Preview
                    Container(
                      width: 80,
                      height: 60,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFE9ECEF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFDEE2E6)),
                      ),
                      child: Center(
                        child: Text(
                          selectedSeason,
                          style: TextStyle(
                            color: Color(0xFF343A40),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSeason,
                      decoration: InputDecoration(
                        labelText: 'Select Season *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: predefinedSeasons
                          .map(
                            (season) => DropdownMenuItem(
                              value: season,
                              child: Text(season),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedSeason = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: ['Active', 'Inactive']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF6C757D)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      Navigator.of(context).pop(true); // Close dialog first
                      if (mounted) setState(() => isLoading = true);

                      final createData = {
                        'title': selectedSeason,
                        'status': selectedStatus,
                      };

                      await InventoryService.createSeason(createData);

                      // Reload the entire page from page 1
                      await _fetchSeasons(page: 1);

                      if (!mounted) return;
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Season created successfully'),
                            ],
                          ),
                          backgroundColor: Color(0xFF28A745),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Failed to create season: $e'),
                            ],
                          ),
                          backgroundColor: Color(0xFFDC3545),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFA726),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void editSeason(season_model.Season season) async {
    String selectedSeason = season.title;
    String selectedStatus = season.status;

    final parentContext = context; // Store parent context

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Create dropdown options that include the current season if not in predefined list
            final dropdownOptions = List<String>.from(predefinedSeasons);
            if (!dropdownOptions.contains(selectedSeason)) {
              dropdownOptions.insert(0, selectedSeason);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF28A745)),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Season',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF343A40),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Season Preview
                    Container(
                      width: 80,
                      height: 60,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFE9ECEF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFDEE2E6)),
                      ),
                      child: Center(
                        child: Text(
                          selectedSeason,
                          style: TextStyle(
                            color: Color(0xFF343A40),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedSeason,
                      decoration: InputDecoration(
                        labelText: 'Select Season *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: dropdownOptions
                          .map(
                            (seasonOption) => DropdownMenuItem(
                              value: seasonOption,
                              child: Text(seasonOption),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedSeason = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: ['Active', 'Inactive']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF6C757D)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      Navigator.of(context).pop(true); // Close dialog first
                      if (mounted) setState(() => isLoading = true);

                      final updateData = {
                        'title': selectedSeason,
                        'status': selectedStatus,
                      };

                      await InventoryService.updateSeason(
                        season.id,
                        updateData,
                      );

                      // Reload the entire page from page 1
                      await _fetchSeasons(page: 1);

                      if (!mounted) return;
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Season updated successfully'),
                            ],
                          ),
                          backgroundColor: Color(0xFF28A745),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Failed to update season: $e'),
                            ],
                          ),
                          backgroundColor: Color(0xFFDC3545),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteSeason(season_model.Season season) {
    final parentContext = context; // Store parent context

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Color(0xFFDC3545)),
              SizedBox(width: 8),
              Text('Delete Season'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${season.title}"?\n\nThis will also remove all associated products.',
            style: TextStyle(color: Color(0xFF6C757D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF6C757D))),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.of(context).pop(); // Close dialog first
                  if (mounted) setState(() => isLoading = true);

                  await InventoryService.deleteSeason(season.id);

                  // Reload the entire page from page 1
                  await _fetchSeasons(page: 1);

                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Season deleted successfully'),
                        ],
                      ),
                      backgroundColor: Color(0xFFDC3545),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Failed to delete season: $e'),
                        ],
                      ),
                      backgroundColor: Color(0xFFDC3545),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } finally {
                  if (mounted) setState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC3545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void viewSeasonDetails(season_model.Season season) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<season_model.Season>(
              future: InventoryService.getSeason(season.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.visibility, color: Color(0xFF17A2B8)),
                        SizedBox(width: 12),
                        Text(
                          'Season Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Container(
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFA726),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading season details...',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.error, color: Color(0xFFDC3545)),
                        SizedBox(width: 12),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Container(
                      width: 400,
                      child: Text(
                        'Failed to load season details: ${snapshot.error}',
                        style: TextStyle(color: Color(0xFF6C757D)),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasData) {
                  final details = snapshot.data!;
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.visibility, color: Color(0xFF17A2B8)),
                        SizedBox(width: 12),
                        Text(
                          'Season Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Season Preview
                          Container(
                            width: 100,
                            height: 60,
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFE9ECEF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFDEE2E6)),
                            ),
                            child: Center(
                              child: Text(
                                details.title,
                                style: TextStyle(
                                  color: Color(0xFF343A40),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                          // Details
                          _buildDetailRow('Title', details.title),
                          _buildDetailRow('Status', details.status),
                          _buildDetailRow(
                            'Created',
                            _formatDate(details.createdAt),
                          ),
                          _buildDetailRow(
                            'Updated',
                            _formatDate(details.updatedAt),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      ),
                    ],
                  );
                } else {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.error, color: Color(0xFFDC3545)),
                        SizedBox(width: 12),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Container(
                      width: 400,
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Color(0xFF6C757D)),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      ),
                    ],
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA726), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFFA726).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seasons',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage seasonal collections for your products',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: addNewSeason,
                    icon: Icon(Icons.add, size: 16),
                    label: Text('Add Season'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF17A2B8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Enhanced Filters Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Color(0xFF6C757D),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Search & Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF343A40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Search seasons...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF6C757D),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFFDEE2E6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFFDEE2E6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFFFFA726),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFFFA726),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                                items: ['All', 'Active', 'Inactive']
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: Color(0xFF343A40),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedStatus = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Enhanced Table Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: Color(0xFFFFA726),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Seasons List',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_sunny,
                                color: Color(0xFFFF8F00),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '$totalSeasons Seasons',
                                style: TextStyle(
                                  color: Color(0xFFFF8F00),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _fetchSeasons(page: 1);
                      },
                      color: Color(0xFFFFA726),
                      child: isLoading
                          ? Container(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFFA726),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Loading seasons...',
                                      style: TextStyle(
                                        color: Color(0xFF6C757D),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : errorMessage != null
                          ? Container(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Color(0xFFDC3545),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Failed to load seasons',
                                      style: TextStyle(
                                        color: Color(0xFFDC3545),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        color: Color(0xFF6C757D),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchSeasons,
                                      child: Text('Retry'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFFFA726),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : seasons.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.wb_sunny_outlined,
                                      color: Color(0xFF6C757D),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No seasons found',
                                      style: TextStyle(
                                        color: Color(0xFF6C757D),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first season to get started',
                                      style: TextStyle(
                                        color: Color(0xFF6C757D),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Color(0xFFF8F9FA),
                              ),
                              dataRowColor:
                                  MaterialStateProperty.resolveWith<Color>((
                                    Set<MaterialState> states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return Color(0xFFFFA726).withOpacity(0.1);
                                    }
                                    return Colors.white;
                                  }),
                              columns: const [
                                DataColumn(
                                  label: SizedBox(
                                    width: 85,
                                    child: Text('Preview'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 175,
                                    child: Text('Season Name'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 85,
                                    child: Text('Status'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 115,
                                    child: Text('Created'),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 85,
                                    child: Text('Actions'),
                                  ),
                                ),
                              ],
                              rows: seasons.map((season_model.Season season) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        width: 50,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE9ECEF),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            season.title.length > 4
                                                ? season.title.substring(0, 4) +
                                                      '...'
                                                : season.title,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF343A40),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          season.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF343A40),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 90,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: season.status == 'Active'
                                                ? Color(0xFFD4EDDA)
                                                : Color(0xFFF8D7DA),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                season.status == 'Active'
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: season.status == 'Active'
                                                    ? Color(0xFF28A745)
                                                    : Color(0xFFDC3545),
                                                size: 12,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                season.status,
                                                style: TextStyle(
                                                  color:
                                                      season.status == 'Active'
                                                      ? Color(0xFF155724)
                                                      : Color(0xFF721C24),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          _formatDate(season.createdAt),
                                          style: TextStyle(
                                            color: Color(0xFF6C757D),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 90,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  viewSeasonDetails(season),
                                              icon: Icon(
                                                Icons.visibility,
                                                color: Color(0xFF17A2B8),
                                                size: 16,
                                              ),
                                              tooltip: 'View Details',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                            ),
                                            SizedBox(width: 2),
                                            IconButton(
                                              onPressed: () =>
                                                  editSeason(season),
                                              icon: Icon(
                                                Icons.edit,
                                                color: Color(0xFF28A745),
                                                size: 16,
                                              ),
                                              tooltip: 'Edit Season',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                            ),
                                            SizedBox(width: 2),
                                            IconButton(
                                              onPressed: () =>
                                                  deleteSeason(season),
                                              icon: Icon(
                                                Icons.delete,
                                                color: Color(0xFFDC3545),
                                                size: 16,
                                              ),
                                              tooltip: 'Delete Season',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Pagination
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: currentPage > 1
                        ? () => _fetchSeasons(page: currentPage - 1)
                        : null,
                    icon: Icon(Icons.chevron_left, size: 14),
                    label: Text('Previous', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: currentPage > 1
                          ? Color(0xFF6C757D)
                          : Color(0xFFADB5BD),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dynamic page buttons based on total pages
                  ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
                    int pageNumber;
                    if (totalPages <= 5) {
                      pageNumber = index + 1;
                    } else if (currentPage <= 3) {
                      pageNumber = index + 1;
                    } else if (currentPage >= totalPages - 2) {
                      pageNumber = totalPages - 4 + index;
                    } else {
                      pageNumber = currentPage - 2 + index;
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      child: ElevatedButton(
                        onPressed: () => _fetchSeasons(page: pageNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pageNumber == currentPage
                              ? Color(0xFFFFA726)
                              : Colors.white,
                          foregroundColor: pageNumber == currentPage
                              ? Colors.white
                              : Color(0xFF6C757D),
                          elevation: pageNumber == currentPage ? 2 : 0,
                          side: pageNumber == currentPage
                              ? null
                              : BorderSide(color: Color(0xFFDEE2E6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size(32, 32),
                        ),
                        child: Text(
                          pageNumber.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: currentPage < totalPages
                        ? () => _fetchSeasons(page: currentPage + 1)
                        : null,
                    icon: Icon(Icons.chevron_right, size: 14),
                    label: Text('Next', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: currentPage < totalPages
                          ? Color(0xFF6C757D)
                          : Color(0xFFADB5BD),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                  // Page info
                  const SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Page $currentPage of $totalPages (${totalSeasons} total)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6C757D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF343A40),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
