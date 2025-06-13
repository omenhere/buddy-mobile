import 'package:flutter/material.dart';
import 'chat_bot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.9);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 0.1,
      size.width,
      size.height * 0.9,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 30,
    );
    path.quadraticBezierTo(
      3 * size.width / 4,
      size.height - 60,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isAddLoading = false;
  bool _isReduceLoading = false;

  Map<String, dynamic>? dashboardData;
  List<Map<String, dynamic>> targets = [];
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> expenseTypes = [];
  Map<String, double> pieChartData = {};
  Map<String, Color> expenseTypeColors = {};

 
  final TextEditingController _amountController = TextEditingController();

  List<Color> availableColors = [
    const Color.fromARGB(255, 0, 0, 0),
    const Color.fromARGB(255, 0, 221, 255),
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];


  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchExpenseTypes();
    _fetchHistory();
    _fetchPieChartData();
  }

  Future<void> _fetchPieChartData() async {
    try {
      final data = await ApiService().getPieChartData();
      print('Pie Chart Data: $data');
      setState(() {
        pieChartData = data;
      });
    } catch (e) {
      print('Error fetching pie chart data: $e');
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await ApiService().getHistory();
      setState(() {
        history = data;
      });
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      ApiService apiService = ApiService();
      var data = await apiService.getDashboardData();
      setState(() {
        dashboardData = data;
        targets = List<Map<String, dynamic>>.from(data['targets'] ?? []);
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  Future<void> _fetchExpenseTypes() async {
    try {
      ApiService apiService = ApiService();
      var data = await apiService.getExpenseType();
      setState(() {
        expenseTypes = List<Map<String, dynamic>>.from(
          data['expenseTypes'] ?? [],
        );
        // Update expenseTypeColors dari hex color API
        expenseTypeColors = {
          for (var type in expenseTypes)
            type['name']: _hexToColor(type['color'] ?? "#888888"),
        };
      });
    } catch (e) {
      print('Error fetching expense types: $e');
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _addAmount() async {
    if (_amountController.text.isNotEmpty) {
      int amount = int.tryParse(_amountController.text) ?? 0;
      if (amount > 0) {
        setState(() => _isAddLoading = true);
        try {
          await ApiService().updateSaldo(amount, 'add');
          await _fetchDashboardData();
          _amountController.clear();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Saldo berhasil ditambah!")));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal menambah saldo.")));
        } finally {
          setState(() => _isAddLoading = false);
        }
      }
    }
  }

  void _reduceAmount() async {
    if (_amountController.text.isNotEmpty) {
      int amount = int.tryParse(_amountController.text) ?? 0;
      if (amount > 0) {
        setState(() => _isReduceLoading = true);
        try {
          await ApiService().updateSaldo(amount, 'reduce');
          await _fetchDashboardData();
          _amountController.clear();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Saldo berhasil dikurangi!")));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal mengurangi saldo.")));
        } finally {
          setState(() => _isReduceLoading = false);
        }
      }
    }
  }

  void _showAddTargetPopup() {
    List<String> items = ["Laptop", "Sepeda", "Kamera", "Lainnya"];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pilih Target Baru",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 16),
                Divider(color: Colors.blue.shade300, thickness: 1),
                SizedBox(height: 8),
                ...items.map((item) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item == "Lainnya"
                            ? Icons.add_circle_outline
                            : Icons
                                .shopping_bag, // Ikon default untuk semua item
                        color:
                            item == "Lainnya"
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                        size: 28,
                      ),
                      title: Text(
                        item,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              item == "Lainnya"
                                  ? Colors.green.shade800
                                  : Colors.black,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (item == "Lainnya") {
                          _showCustomItemDialog();
                        } else {
                          _showPriceInputDialog(item);
                        }
                      },
                    ),
                  );
                }).toList(),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Batal",
                    style: TextStyle(fontSize: 16, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomItemDialog() {
    final TextEditingController _itemController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade50, Colors.green.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Tambahkan Target Baru",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    labelText: "Nama Target",
                    hintText: "Contoh: Liburan ke Bali",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Batal",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (_itemController.text.trim().isNotEmpty) {
                          Navigator.of(context).pop();
                          _showPriceInputDialog(_itemController.text.trim());
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Silakan masukkan nama target"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Lanjutkan",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPriceInputDialog(String itemName) {
    final TextEditingController _priceController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Masukkan Harga untuk $itemName"),
              content: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Harga (Rp)",
                  hintText: "Contoh: 5000000",
                  prefixText: "Rp",
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Batal"),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (_priceController.text.isNotEmpty) {
                              setStateDialog(() => isLoading = true);
                              try {
                                await ApiService().addTarget({
                                  "name": itemName,
                                  "price": _priceController.text,
                                });
                                await _fetchDashboardData();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Target berhasil ditambahkan!",
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Gagal menambah target."),
                                  ),
                                );
                              } finally {
                                setStateDialog(() => isLoading = false);
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Silakan masukkan harga terlebih dahulu",
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                  child:
                      isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddProgressPopup(int index) {
    final TextEditingController _progressController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Tambahkan Progress"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Masukkan nominal untuk ${targets[index]["name"]}"),
                  TextField(
                    controller: _progressController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Nominal",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (_progressController.text.isNotEmpty) {
                              setStateDialog(() => isLoading = true);
                              try {
                                await ApiService().addTargetProgress(
                                  targetId: targets[index]['id'].toString(),
                                  progress: _progressController.text,
                                );
                                await _fetchDashboardData();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Progress berhasil ditambahkan!",
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Gagal menambah progress."),
                                  ),
                                );
                              } finally {
                                setStateDialog(() => isLoading = false);
                              }
                            }
                          },
                  child:
                      isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text("Tambahkan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPurchaseConfirmation(int index) {
    final TextEditingController _pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Masukkan PIN",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: "PIN",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              if (_pinController.text.isNotEmpty) {
                                setStateDialog(() => isLoading = true);
                                bool isValid = false;
                                try {
                                  isValid = await ApiService().validatePin(
                                    _pinController.text,
                                  );
                                } catch (e) {
                                  isValid = false;
                                }
                                if (isValid) {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Tutup dialog PIN
                                  _completePurchase(index); // Lanjutkan proses
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "PIN salah. Pembelian dibatalkan.",
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                                setStateDialog(() => isLoading = false);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Silakan masukkan PIN."),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child:
                        isLoading
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Memvalidasi...",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            )
                            : Text("Verifikasi PIN"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _completePurchase(int index) async {
    final targetId = targets[index]['id'].toString();
    final targetName = targets[index]['name'];
    final targetPrice = targets[index]['price'].toDouble();

    try {
      await ApiService().deleteTarget(targetId);
      await _fetchDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$targetName berhasil dibeli dan target dihapus!"),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menghapus target setelah pembelian."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double saldo = (dashboardData?['saldo']?['amount'] ?? 0).toDouble();
    double dailyLimit = (dashboardData?['daily_limit'] ?? 0).toDouble();
    double todaySpending = (dashboardData?['today_spending'] ?? 0).toDouble();
    double remaining = (dashboardData?['sisa_harian'] ?? 0).toDouble();
    double progress =
        ((dashboardData?['level_progress'] ?? 0).toDouble()) / 100;

    return Scaffold(
      backgroundColor: HexColor("#F7F9F8"),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _fetchDashboardData();
              await _fetchExpenseTypes();
              await _fetchHistory();
              await _fetchPieChartData();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (ClipPath) dipindahkan ke dalam SingleChildScrollView
                  ClipPath(
                    clipper: WaveClipper(),
                    child: Container(
                      width: double.infinity,
                      height: 220, // Tinggi ClipPath
                      color: Colors.blue,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Image.asset(
                            //   'assets/images/robotLogo.png',
                            //   width: 120,
                            //   height: 120,
                            // ),
                            SizedBox(height: 10),
                            Text(
                              ' Buddy',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  // Bagian atas dengan tombol setting
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hi, Kevin",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                " Buddy telah mempelajari pola pengeluaranmu selama ini.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showSettings,
                          icon: Icon(
                            Icons.settings,
                            size: 30,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(255, 62, 137, 198),
                            const Color.fromARGB(255, 51, 84, 107),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Level-mu saat ini",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showExpenseLimitsPopup,
                            child: Text(
                              "Moderate Saver",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.6,
                            backgroundColor: Colors.blue.shade200,
                            color: Colors.blue.shade900,
                            minHeight: 10,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tingkatkan untuk menjadi Professional Saver",
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 13.0, top: 16.0),
                    child: Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Pindahkan _buildEditableCard ke atas
                  _buildEditableCard(), // Editable Card di atas
                  SizedBox(
                    height: 16,
                  ), // Beri jarak antara Editable Card dan Target Card
                  // Target Card di bawah
                  _buildTargetCard(),
                  SizedBox(
                    height: 16,
                  ), // Beri jarak antara Target Card dan tombol

                  ElevatedButton(
                    onPressed: _showAddTargetPopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 148, 173, 207),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Tambah Target",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets
                              .zero, // Padding diatur nol karena akan diatur di child
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // Border radius tombol
                      ),
                      backgroundColor:
                          Colors
                              .transparent, // Latar belakang tombol transparan
                      elevation: 10, // Elevasi untuk shadow
                      side: BorderSide.none, // Hapus border
                      foregroundColor: Colors.white, // Warna teks
                      shadowColor: Colors.deepOrange.withOpacity(
                        0.5,
                      ), // Warna shadow
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange,
                            Colors.deepOrange,
                          ], // Gradien warna
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // Border radius yang sama dengan tombol
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ), // Padding untuk konten
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image.asset(
                            //   'assets/images/robotLogo.png', // Gambar robot
                            //   width: 70,
                            //   height: 70,
                            // ),
                            SizedBox(width: 12), // Jarak antara gambar dan teks
                            Text(
                              "Chat Buddy",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(
                                      0.2,
                                    ), // Shadow untuk teks
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Riwayat Pengeluaran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildExpensePieChart(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 62, 137, 198),
                          const Color.fromARGB(255, 51, 84, 107),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Optional: rounded corners
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ), // Adjust padding as needed
                    child: Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color:
                                Colors
                                    .white, // Changed to white for better visibility on gradient
                          ),
                          children: [
                            TextSpan(
                              text: "+0.0%",
                              style: TextStyle(
                                color:
                                    Colors
                                        .grey[300], // Lighter grey for better contrast
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  " dari bulan sebelumnya, pengeluaran mu aman",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ...history.map((item) {
                    return ListTile(
                      title: Text(item["expense_type_name"] ?? "-"),
                      subtitle: Text(
                        "Dibeli pada: ${item["created_at"] ?? "-"}\n"
                        "Metode: ${item["method"] ?? "-"}",
                      ),
                      trailing: Text(
                        "Rp${item["amount"]?.toString() ?? "0"}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Tombol Scan dengan Latar Belakang Setengah Lingkaran
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _BackgroundClipper(),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 120,
                padding: EdgeInsets.only(top: 40),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 21, 52, 118),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, 10),
                    child: Container(
                      width: 60,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _showScanPopup,
                        icon: Icon(
                          Icons.qr_code_scanner,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCard() {
    Widget saldoWidget;
    if (dashboardData == null) {
      saldoWidget = SizedBox(
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      double saldo =
          dashboardData?['saldo']?['amount'].toDouble() ?? 0.toDouble();
      final formattedSaldo = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      ).format(saldo);

      saldoWidget = Text(
        'Saldo: $formattedSaldo',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              saldoWidget,
              SizedBox(height: 8),
              Text(
                DateFormat("MMMM yyyy", "id_ID").format(DateTime.now()),
                style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Isi Nominal",
                  labelStyle: TextStyle(color: Colors.blue.shade700),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade900),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isReduceLoading ? null : _reduceAmount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child:
                        _isReduceLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              "Kurangi",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                  ElevatedButton(
                    onPressed: _isAddLoading ? null : _addAmount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child:
                        _isAddLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              "Tambah",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ],
              ),
                          if ((dashboardData?['daily_limit'] ?? 0) > 0) _buildDailyLimitWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyLimitWidget() {
    double dailyLimit = (dashboardData?['daily_limit'] ?? 0).toDouble();
    double todayExpenses = (dashboardData?['today_spending'] ?? 0).toDouble();
    double remaining = dailyLimit - todayExpenses;
    double progress = dailyLimit > 0 ? todayExpenses / dailyLimit : 0;

    String formatNumber(double number) {
      return number
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    }

    return Column(
      children: [
        SizedBox(height: 30),
        Text(
          "Batas Pengeluaran Harian",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress > 1 ? 1 : progress,
          backgroundColor: Colors.grey.shade600,
          color:
              progress >= 1
                  ? Colors.red
                  : progress >= 0.8
                  ? Colors.orange
                  : Colors.green,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ),
        SizedBox(height: 8),
        Text(
          "Sisa: Rp${remaining > 0 ? formatNumber(remaining) : '0'}",
          style: TextStyle(
            fontSize: 14,
            color: remaining > 0 ? Colors.blue.shade800 : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (remaining <= 0)
          Text(
            "Batas harian telah tercapai!",
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
      ],
    );
  }

  Widget _buildTargetCard() {
    return Card(
      elevation: 4, // Shadow yang lebih menonjol
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ), // Border radius yang lebih besar
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 140, 205, 223),
              const Color.fromARGB(255, 179, 195, 216),
            ], // Gradien warna
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            20,
          ), // Border radius yang sama dengan card
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2), // Shadow untuk efek elevasi
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16), // Padding yang lebih besar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Target",
                style: TextStyle(
                  fontSize: 20, // Ukuran teks yang lebih besar
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900, // Warna teks yang lebih gelap
                ),
              ),
              SizedBox(height: 12),
              ...targets.map((target) {
                double progressValue = (target["progress"] ?? 0).toDouble();
                double priceValue = (target["price"] ?? 1).toDouble();
                double progress =
                    priceValue > 0 ? progressValue / priceValue : 0;
                bool isDisabled = target["disabled"] ?? false;

                return Stack(
                  children: [
                    if (isDisabled)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            target["name"] ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          subtitle: Text(
                            "Terkumpul: Rp${progressValue.toStringAsFixed(0)} dari Rp${priceValue.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isDisabled ? Icons.block : Icons.block,
                                  color: isDisabled ? Colors.grey : Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    target["disabled"] =
                                        !(target["disabled"] ?? false);
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text("Hapus Target"),
                                          content: Text(
                                            "Yakin ingin menghapus target ini?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: Text("Batal"),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: Text(
                                                "Hapus",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await ApiService().deleteTarget(
                                        target['id'].toString(),
                                      );
                                      await _fetchDashboardData();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Target berhasil dihapus!",
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Gagal menghapus target.",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!isDisabled) {
                              _showAddProgressPopup(targets.indexOf(target));
                            }
                          },
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress > 1 ? 1 : progress,
                            backgroundColor: const Color.fromARGB(
                              255,
                              154,
                              80,
                              80,
                            ),
                            color:
                                isDisabled
                                    ? Colors.grey
                                    : const Color.fromARGB(255, 43, 120, 72),
                            minHeight: 10,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%/100%",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        if (progress >= 1 && !isDisabled)
                          ElevatedButton(
                            onPressed: () {
                              _showPurchaseConfirmation(
                                targets.indexOf(target),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              "Beli Sekarang",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanPopup() {
    final TextEditingController _amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Scan QRIS"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  // child: Image.asset(
                  //   'assets/images/qris.jpg', // Path ke gambar QRIS
                  //   width: 200,
                  //   height: 200,
                  //   fit: BoxFit.cover,
                  // ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Masukkan Nominal Pembelian",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_amountController.text.isNotEmpty) {
                    Navigator.of(context).pop(); // Tutup pop-up scan
                    _showExpenseTypeSelection(_amountController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Silakan masukkan nominal pembelian."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text("Bayar"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpenseTypeSelection(String amount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pilih Kategori Pengeluaran"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children:
                  expenseTypes.map((type) {
                    return ListTile(
                      leading: Icon(
                        Icons.category,
                        color: expenseTypeColors[type['name']] ?? Colors.blue,
                      ),
                      title: Text(type['name']),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showPinInputForQris(amount, type['id']);
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showPinInputForQris(String amount, String expenseTypeId) {
    final TextEditingController _pinController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Masukkan PIN"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "PIN",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              if (_pinController.text.isNotEmpty) {
                                setStateDialog(() => isLoading = true);
                                try {
                                  await ApiService().scanQrisPayment(
                                    amount: amount,
                                    pin: _pinController.text,
                                    expenseTypeId: expenseTypeId,
                                  );
                                  Navigator.of(context).pop();
                                  await _fetchDashboardData();
                                  await _fetchHistory();
                                  await _fetchPieChartData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Pembayaran QRIS berhasil!",
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Pembayaran QRIS gagal."),
                                    ),
                                  );
                                } finally {
                                  setStateDialog(() => isLoading = false);
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Silakan masukkan PIN."),
                                  ),
                                );
                              }
                            },
                    child:
                        isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text("Verifikasi & Bayar"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSettings() {
    final TextEditingController _expenseTypeController =
        TextEditingController();
    final TextEditingController _dailyLimitController = TextEditingController();
    Color? selectedColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isLoading = false;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 10,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Pengaturan",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Tipe Pengeluaran",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
                      ...expenseTypes.map((type) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.circle,
                              color:
                                  expenseTypeColors[type['name']] ??
                                  Colors.grey,
                            ),
                            title: Text(
                              type['name'],
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    final TextEditingController
                                    editNameController = TextEditingController(
                                      text: type['name'],
                                    );
                                    final TextEditingController
                                    editLimitController = TextEditingController(
                                      text: type['daily_limit'].toString(),
                                    );
                                    Color? editSelectedColor =
                                        expenseTypeColors[type['name']] ??
                                        Colors.blue;

                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        bool isEditLoading = false;
                                        return StatefulBuilder(
                                          builder: (
                                            context,
                                            setStateEditDialog,
                                          ) {
                                            return AlertDialog(
                                              title: Text(
                                                "Edit Tipe Pengeluaran",
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller:
                                                        editNameController,
                                                    decoration: InputDecoration(
                                                      labelText: "Nama Tipe",
                                                    ),
                                                  ),
                                                  SizedBox(height: 12),
                                                  TextField(
                                                    controller:
                                                        editLimitController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: InputDecoration(
                                                      labelText: "Limit Harian",
                                                    ),
                                                  ),
                                                  SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 8.0,
                                                    children:
                                                        availableColors.map((
                                                          color,
                                                        ) {
                                                          return GestureDetector(
                                                            onTap: () {
                                                              setStateEditDialog(
                                                                () {
                                                                  editSelectedColor =
                                                                      color;
                                                                },
                                                              );
                                                            },
                                                            child: Container(
                                                              width: 32,
                                                              height: 32,
                                                              decoration: BoxDecoration(
                                                                color: color,
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                                border: Border.all(
                                                                  color:
                                                                      editSelectedColor ==
                                                                              color
                                                                          ? Colors
                                                                              .black
                                                                          : Colors
                                                                              .transparent,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: Text(
                                                    "Batal",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          Colors.blue.shade900,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed:
                                                      isEditLoading
                                                          ? null
                                                          : () async {
                                                            setStateEditDialog(
                                                              () =>
                                                                  isEditLoading =
                                                                      true,
                                                            );
                                                            try {
                                                              await ApiService().updateExpenseType(
                                                                type['id'],
                                                                {
                                                                  "expense_type":
                                                                      editNameController
                                                                          .text,
                                                                  "color":
                                                                      '#${(editSelectedColor ?? Colors.blue).value.toRadixString(16).substring(2)}',
                                                                  "daily_limit":
                                                                      editLimitController
                                                                          .text,
                                                                },
                                                              );
                                                              await _fetchExpenseTypes();
                                                              setStateDialog(
                                                                () {},
                                                              );
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    "Tipe pengeluaran berhasil diubah!",
                                                                  ),
                                                                ),
                                                              );
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                            } catch (e) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    "Gagal mengubah tipe pengeluaran.",
                                                                  ),
                                                                ),
                                                              );
                                                            } finally {
                                                              setStateEditDialog(
                                                                () =>
                                                                    isEditLoading =
                                                                        false,
                                                              );
                                                            }
                                                          },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors
                                                                .blue
                                                                .shade900,
                                                      ),
                                                  child:
                                                      isEditLoading
                                                          ? SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          )
                                                          : Text(
                                                            "Simpan",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text(
                                              "Hapus Tipe Pengeluaran",
                                            ),
                                            content: Text(
                                              "Yakin ingin menghapus tipe pengeluaran ini?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text("Batal"),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: Text(
                                                  "Hapus",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ApiService().deleteExpenseType(
                                          type['id'],
                                        );
                                        await _fetchExpenseTypes();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Tipe pengeluaran berhasil dihapus!",
                                            ),
                                          ),
                                        );
                                        Navigator.of(
                                          context,
                                        ).pop(); // Tutup modal pengaturan setelah sukses hapus
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Gagal menghapus tipe pengeluaran.",
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 16),
                      TextField(
                        controller: _expenseTypeController,
                        decoration: InputDecoration(
                          labelText: "Tambah Tipe Pengeluaran",
                          labelStyle: TextStyle(color: Colors.blue.shade800),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue.shade900),
                          ),
                          prefixIcon: Icon(Icons.category, color: Colors.blue),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Pilih Warna",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children:
                            availableColors.map((color) {
                              return GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selectedColor == color
                                              ? Colors.black
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Batas Nominal Pengeluaran Harian",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _dailyLimitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Masukkan Batas Harian",
                          labelStyle: TextStyle(color: Colors.blue.shade800),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue.shade900),
                          ),
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showPinSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            "Atur PIN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "Batal",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      if (_expenseTypeController
                                              .text
                                              .isNotEmpty &&
                                          selectedColor != null) {
                                        setStateDialog(() => isLoading = true);
                                        try {
                                          await ApiService().addExpenseType({
                                            "expense_type":
                                                _expenseTypeController.text,
                                            "color":
                                                '#${selectedColor!.value.toRadixString(16).substring(2)}',
                                            "daily_limit":
                                                _dailyLimitController.text,
                                          });
                                          await _fetchExpenseTypes();
                                          _expenseTypeController.clear();
                                          _dailyLimitController.clear();
                                          selectedColor = null;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Tipe pengeluaran berhasil ditambah!",
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Gagal menambah tipe pengeluaran.",
                                              ),
                                            ),
                                          );
                                        } finally {
                                          setStateDialog(
                                            () => isLoading = false,
                                          );
                                          Navigator.of(context).pop();
                                        }
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 5,
                            ),
                            child:
                                isLoading
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      "Simpan",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPinSettings() {
    final TextEditingController _oldPinController = TextEditingController();
    final TextEditingController _newPinController = TextEditingController();
    bool isPinLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStatePinDialog) {
            bool hasPin =
                true; // Anggap user sudah punya PIN, atau cek dari API jika perlu

            return AlertDialog(
              title: Text("Atur PIN"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPin) ...[
                    TextField(
                      controller: _oldPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Masukkan PIN Lama",
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _newPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Masukkan PIN Baru"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                      isPinLoading
                          ? null
                          : () async {
                            if (_newPinController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Silakan masukkan PIN baru."),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            if (hasPin) {
                              setStatePinDialog(() => isPinLoading = true);
                              bool isValid = false;
                              try {
                                isValid = await ApiService().validatePin(
                                  _oldPinController.text,
                                );
                              } catch (e) {
                                isValid = false;
                              }
                              if (!isValid) {
                                setStatePinDialog(() => isPinLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "PIN lama salah. Silakan coba lagi.",
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                            }
                            setStatePinDialog(() => isPinLoading = true);
                            try {
                              await ApiService().setPin(
                                _newPinController.text,
                                _newPinController.text,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    hasPin
                                        ? "PIN berhasil diubah."
                                        : "PIN berhasil diatur.",
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Gagal mengatur PIN."),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } finally {
                              setStatePinDialog(() => isPinLoading = false);
                            }
                          },
                  child:
                      isPinLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildExpensePieChart() {
    // Jika belum ada data
    if (pieChartData.isEmpty || pieChartData.values.every((v) => v == 0)) {
      return Center(child: Text('Belum ada data pengeluaran'));
    }

    // Buat sections untuk pie chart
    final total = pieChartData.values.fold(0.0, (a, b) => a + b);
    final pieSections =
        pieChartData.entries.map((entry) {
          final category = entry.key;
          final value = entry.value;
          final percentage = total > 0 ? (value / total) * 100 : 0.0;

          return PieChartSectionData(
            color: expenseTypeColors[category] ?? Colors.grey,
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            showTitle: percentage > 5, // Hanya tampilkan persentase jika >5%
          );
        }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: pieSections,
              centerSpaceRadius: 40,
              sectionsSpace: 0,
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildLegend(pieChartData),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLegend(Map<String, double> expenseTotals) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children:
          expenseTotals.entries.map((entry) {
            String category = entry.key;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: expenseTypeColors[category] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(category, style: TextStyle(fontSize: 14)),
              ],
            );
          }).toList(),
    );
  }

  void _showExpenseLimitsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (expenseTypes.isEmpty) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Container(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Limit Pengeluaran per Hari",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(color: Colors.blue.shade300),
                    SizedBox(height: 8),
                    ...expenseTypes.map((type) {
                      final String name = type['name'];
                      final double dailyLimit =
                          (type['daily_limit'] ?? 0).toDouble();
                      final double totalSpent =
                          (type['total_spent'] ?? 0).toDouble();
                      final double remaining = dailyLimit - totalSpent;
                      final bool isOverLimit = remaining < 0;

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: expenseTypeColors[name]?.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.category,
                              color: expenseTypeColors[name],
                              size: 20,
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            isOverLimit
                                ? "Melebihi limit: Rp${(-remaining).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}"
                                : "Sisa: Rp${remaining.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
                            style: TextStyle(
                              color:
                                  isOverLimit
                                      ? Colors.red.shade700
                                      : Colors.black,
                              fontWeight:
                                  isOverLimit
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade700),
                            onPressed: () {
                              final TextEditingController limitController =
                                  TextEditingController(
                                    text: dailyLimit.toStringAsFixed(0),
                                  );
                              showDialog(
                                context: context,
                                builder: (context) {
                                  bool isLoading = false;
                                  return StatefulBuilder(
                                    builder: (context, setStateEditDialog) {
                                      return AlertDialog(
                                        title: Text("Edit Limit Harian"),
                                        content: TextField(
                                          controller: limitController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: "Limit Harian (Rp)",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text("Batal"),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                isLoading
                                                    ? null
                                                    : () async {
                                                      setStateEditDialog(
                                                        () => isLoading = true,
                                                      );
                                                      try {
                                                        await ApiService()
                                                            .updateExpenseType(
                                                              type['id']
                                                                  .toString(),
                                                              {
                                                                "daily_limit":
                                                                    limitController
                                                                        .text,
                                                                "expense_type":
                                                                    type['name'],
                                                                "color":
                                                                    type['color'],
                                                              },
                                                            );
                                                        await _fetchExpenseTypes();
                                                        setStateDialog(
                                                          () {},
                                                        ); // <-- refresh dialog limit
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              "Limit harian berhasil diubah!",
                                                            ),
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              "Gagal mengubah limit harian.",
                                                            ),
                                                          ),
                                                        );
                                                      } finally {
                                                        setStateEditDialog(
                                                          () =>
                                                              isLoading = false,
                                                        );
                                                      }
                                                    },
                                            child:
                                                isLoading
                                                    ? SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : Text("Simpan"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Tutup",
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
}
