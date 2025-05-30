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
  Map<String, dynamic>? dashboardData;
  int totalAmount = 3000000;
  final TextEditingController _amountController = TextEditingController();

  Map<String, Color> expenseTypeColors = {
    "Makanan dan Minuman": Colors.red,
    "Kebutuhan Harian": Colors.green,
    "Lainnya": Colors.grey,
  };

  List<Color> availableColors = [
    const Color.fromARGB(255, 0, 0, 0),
    const Color.fromARGB(255, 0, 221, 255),
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];

  List<Map<String, dynamic>> targets = [
    {
      "name": "Konser Blackpink",
      "price": 1000000,
      "saved": 0,
      "disabled": false,
    },
    {"name": "Laptop", "price": 5000000, "saved": 0, "disabled": false},
    {"name": "Hotel Bali", "price": 2000000, "saved": 0, "disabled": false},
  ];

  List<Map<String, dynamic>> purchaseHistory = [];

  List<String> expenseTypes = ["Makanan dan Minuman", "Kebutuhan Harian"];
  double dailyExpenseLimit = 0;

  Map<String, double> expenseLimits = {
    "Makanan dan Minuman": 0,
    "Kebutuhan Harian": 0,
  };

  Map<String, double> categoryLimits = {
    "Makanan dan Minuman": 0,
    "Kebutuhan Harian": 0,
  };

  @override
  void initState() {
    super.initState();
    _loadCategoryLimits();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      print('Memanggil API getDashboardData...');
      ApiService apiService = ApiService();
      var data = await apiService.getDashboardData();
      print('API sukses, data: $data');
      if (mounted) {
        setState(() {
          dashboardData = data;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', pin);
  }

  Future<String?> _getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_pin');
  }

  void _addAmount() {
    if (_amountController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Top up dari minimarket terdekat"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog pertama
                  _showBiometricPopup(); // Tampilkan pop-up sidik jari
                },
                child: Text("Lanjutkan"),
              ),
            ],
          );
        },
      );
    }
  }

  void _showBiometricPopup() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Verifikasi Sidik Jari",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // Image.asset(
              //   'assets/images/fingerprint.png', // Gambar sidik jari
              //   width: 100,
              //   height: 100,
              // ),
              SizedBox(height: 16),
              Text(
                "Silakan letakkan jari Anda pada sensor sidik jari.",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup pop-up sidik jari
                  _completeTransaction(); // Selesaikan transaksi
                },
                child: Text("Verifikasi Sidik Jari"),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup pop-up sidik jari
                  _showPinInputPopup(); // Tampilkan pop-up input PIN
                },
                child: Text(
                  "Ganti ke Ketik PIN",
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPinInputPopup() {
    final TextEditingController _pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Masukkan PIN",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true, // Menyembunyikan teks (untuk PIN)
                decoration: InputDecoration(
                  labelText: "PIN",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_pinController.text.isNotEmpty) {
                    // Ambil PIN yang tersimpan
                    final savedPin = await _getPin();

                    // Bandingkan PIN yang dimasukkan dengan PIN yang tersimpan
                    if (_pinController.text == savedPin) {
                      Navigator.of(context).pop(); // Tutup pop-up input PIN
                      _completeTransaction(); // Selesaikan transaksi
                    } else {
                      // Tampilkan pesan error jika PIN salah
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("PIN salah. Transaksi dibatalkan."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    // Tampilkan pesan error jika PIN kosong
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Silakan masukkan PIN."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text("Verifikasi PIN"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _completeTransaction() {
    setState(() {
      totalAmount += int.tryParse(_amountController.text) ?? 0;
    });
    _amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Transaksi berhasil!"),
        duration: Duration(seconds: 2),
      ),
    );
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
            TextButton(
              onPressed: () {
                if (_priceController.text.isNotEmpty) {
                  setState(() {
                    targets.add({
                      "name": itemName,
                      "price": int.tryParse(_priceController.text) ?? 0,
                      "saved": 0,
                      "disabled": false,
                    });
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Silakan masukkan harga terlebih dahulu"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void _showAddProgressPopup(int index) {
    final TextEditingController _progressController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () {
                // Hapus target dan kembalikan uang ke totalAmount
                setState(() {
                  totalAmount +=
                      (targets[index]["saved"] as num)
                          .toInt(); // Konversi ke int
                  targets.removeAt(index);
                });
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_progressController.text.isNotEmpty) {
                  setState(() {
                    int nominal = int.tryParse(_progressController.text) ?? 0;
                    if (totalAmount >= nominal) {
                      targets[index]["saved"] += nominal;
                      totalAmount -= nominal;
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Saldo tidak cukup!"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                  Navigator.of(context).pop(); // Tutup dialog
                }
              },
              child: Text("Tambahkan"),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseConfirmation(int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Verifikasi Sidik Jari",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // Image.asset(
              //   'assets/images/fingerprint.png', // Gambar sidik jari
              //   width: 100,
              //   height: 100,
              // ),
              SizedBox(height: 16),
              Text(
                "Silakan letakkan jari Anda pada sensor sidik jari.",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup pop-up sidik jari
                  _completePurchase(index); // Selesaikan pembelian
                },
                child: Text("Verifikasi"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _completePurchase(int index) {
    setState(() {
      // Tambahkan ke riwayat pembelian dengan format yang konsisten
      purchaseHistory.add({
        'name': targets[index]['name'],
        'category': 'Lainnya', // Kategori eksplisit
        'amount': targets[index]['price'].toDouble(), // Gunakan harga penuh
        'date': DateTime.now().toString(),
        'type': 'target', // Tambahkan identifier khusus
      });
      targets.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${purchaseHistory.last['name']} berhasil dibeli!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (dashboardData == null) {
    //   return Scaffold(
    //     backgroundColor: HexColor("#F7F9F8"),
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    double saldo =
        dashboardData?['saldo']?.toDouble() ?? totalAmount.toDouble();
    double dailyLimit = dashboardData?['daily_limit']?.toDouble() ?? 0;
    double todaySpending = dashboardData?['today_spending']?.toDouble() ?? 0;
    double remaining = dashboardData?['sisa_harian']?.toDouble() ?? 0;
    String level = dashboardData?['level'] ?? '';
    double progress = (dashboardData?['level_progress']?.toDouble() ?? 0) / 100;

    return Scaffold(
      backgroundColor: HexColor("#F7F9F8"),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        Colors.transparent, // Latar belakang tombol transparan
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
                            text: " dari bulan sebelumnya, pengeluaran mu aman",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ...purchaseHistory.map((item) {
                  return ListTile(
                    title: Text(item["name"]),
                    subtitle: Text("Dibeli pada: ${DateTime.now().toString()}"),
                  );
                }).toList(),
                SizedBox(height: 80),
              ],
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
          dashboardData?['saldo']?.toDouble() ?? totalAmount.toDouble();
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
                    onPressed: _reduceAmount,
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
                    child: Text(
                      "Kurangi",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addAmount,
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
                    child: Text(
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
              if (dailyExpenseLimit > 0) _buildDailyLimitWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyLimitWidget() {
    // Calculate total expenses today
    double todayExpenses = purchaseHistory
        .where(
          (expense) =>
              DateTime.parse(expense["date"]).day == DateTime.now().day &&
              DateTime.parse(expense["date"]).month == DateTime.now().month &&
              DateTime.parse(expense["date"]).year == DateTime.now().year,
        )
        .fold(0.0, (sum, expense) => sum + expense["amount"].toDouble());

    double remaining = dailyExpenseLimit - todayExpenses;
    double progress =
        dailyExpenseLimit > 0 ? todayExpenses / dailyExpenseLimit : 0;

    // Fungsi untuk memformat angka dengan titik sebagai pemisah ribuan
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
                double progress = target["saved"] / target["price"];
                bool isDisabled =
                    target["disabled"] ?? false; // Cek status disable

                return Stack(
                  children: [
                    // Lapisan abu-abu jika target dinonaktifkan
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
                            target["name"],
                            style: TextStyle(
                              fontSize: 18, // Ukuran teks yang lebih besar
                              fontWeight: FontWeight.bold,
                              color:
                                  Colors
                                      .blue
                                      .shade900, // Warna teks yang lebih gelap
                            ),
                          ),
                          subtitle: Text(
                            "Terkumpul: Rp${target["saved"].toString().replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'), (Match m) => '.')} dari Rp${target["price"].toString().replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'), (Match m) => '.')}",
                            style: TextStyle(
                              fontSize: 14, // Ukuran teks yang lebih kecil
                              color:
                                  Colors
                                      .blue
                                      .shade700, // Warna teks yang lebih gelap
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isDisabled
                                  ? Icons.block
                                  : Icons.block, // Icon berubah sesuai status
                              color: isDisabled ? Colors.grey : Colors.red,
                            ),
                            onPressed: () {
                              if (isDisabled) {
                                _showEnableConfirmation(
                                  targets.indexOf(target),
                                ); // Tampilkan pop-up konfirmasi enable
                              } else {
                                _showDisableConfirmation(
                                  targets.indexOf(target),
                                ); // Tampilkan pop-up konfirmasi disable
                              }
                            },
                          ),
                          onTap: () {
                            if (!isDisabled) {
                              _showAddProgressPopup(
                                targets.indexOf(target),
                              ); // Tampilkan pop-up tambah progress
                            }
                          },
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Border radius untuk progress bar
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color.fromARGB(
                              255,
                              154,
                              80,
                              80,
                            ), // Warna latar belakang progress bar
                            color:
                                isDisabled
                                    ? Colors.grey
                                    : const Color.fromARGB(
                                      255,
                                      43,
                                      120,
                                      72,
                                    ), // Warna progress bar
                            minHeight: 10, // Tinggi progress bar
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%/100%",
                          style: TextStyle(
                            fontSize: 14, // Ukuran teks yang lebih kecil
                            color:
                                Colors
                                    .blue
                                    .shade700, // Warna teks yang lebih gelap
                          ),
                        ),
                        if (progress >= 1 && !isDisabled)
                          ElevatedButton(
                            onPressed: () {
                              _showPurchaseConfirmation(
                                targets.indexOf(target),
                              ); // Tampilkan konfirmasi pembelian
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.blue.shade900, // Warna tombol
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ), // Padding yang lebih besar
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Border radius tombol
                              ),
                              elevation: 5, // Shadow untuk tombol
                            ),
                            child: Text(
                              "Beli Sekarang",
                              style: TextStyle(
                                fontSize: 16, // Ukuran teks yang lebih besar
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Warna teks tombol
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
    final TextEditingController _amountController =
        TextEditingController(); // Controller untuk nominal pembelian

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
                    _showPinInputForPayment(
                      _amountController.text,
                    ); // Tampilkan pop-up PIN untuk pembayaran
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

  // Fungsi untuk menampilkan pop-up input PIN untuk pembayaran
  void _showPinInputForPayment(String amount) {
    final TextEditingController _pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Masukkan PIN",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true, // Menyembunyikan teks (untuk PIN)
                decoration: InputDecoration(
                  labelText: "PIN",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_pinController.text.isNotEmpty) {
                    // Ambil PIN yang tersimpan
                    final savedPin = await _getPin();

                    // Bandingkan PIN yang dimasukkan dengan PIN yang tersimpan
                    if (_pinController.text == savedPin) {
                      Navigator.of(context).pop(); // Tutup pop-up input PIN
                      _completePayment(amount); // Selesaikan pembayaran
                    } else {
                      // Tampilkan pesan error jika PIN salah
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("PIN salah. Pembayaran dibatalkan."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    // Tampilkan pesan error jika PIN kosong
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Silakan masukkan PIN."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text("Verifikasi PIN"),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk menyelesaikan pembayaran
  void _completePayment(String amount) async {
    int paymentAmount = int.tryParse(amount) ?? 0;

    if (paymentAmount > 0 && totalAmount >= paymentAmount) {
      setState(() {
        totalAmount -= paymentAmount; // Kurangi saldo
      });

      // Tampilkan pop-up kategori pengeluaran setelah pembayaran berhasil
      _showCategoryPopup(
        paymentAmount,
      ); // Tambahkan parameter nominal pembayaran
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Saldo tidak cukup untuk melakukan pembayaran."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Modifikasi fungsi _showCategoryPopup untuk menerima nominal pembayaran
  void _showCategoryPopup(int paymentAmount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pilih Kategori Pengeluaran"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                expenseTypes.map((category) {
                  return ListTile(
                    title: Text(category),
                    onTap: () {
                      Navigator.of(context).pop(); // Tutup pop-up kategori
                      _addToPurchaseHistory(
                        category,
                        paymentAmount,
                      ); // Tambahkan ke riwayat pembelian
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  // Modifikasi fungsi _addToPurchaseHistory untuk menambahkan nominal pembayaran
  void _addToPurchaseHistory(String category, int paymentAmount) {
    setState(() {
      purchaseHistory.add({
        "name": "Pembelian $category",
        "amount": paymentAmount,
        "date": DateTime.now().toString(),
        "category": category, // Tambahkan kategori
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Pembelian $category sebesar Rp${paymentAmount.toString().replaceAllMapped(RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'), (Match m) => '.')} berhasil ditambahkan!",
        ),
        duration: Duration(seconds: 2),
      ),
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Sudut yang melengkung
          ),
          elevation: 10, // Shadow yang lebih menonjol
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white], // Gradien warna
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
                          color: expenseTypeColors[type],
                        ),
                        title: Text(type, style: TextStyle(fontSize: 16)),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // Tambahkan logika untuk mengedit tipe pengeluaran
                          },
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
                              setState(() {
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
                      prefixIcon: Icon(Icons.attach_money, color: Colors.blue),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Tutup dialog pengaturan
                        _showPinSettings(); // Tampilkan dialog pengaturan PIN
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
                          Navigator.of(context).pop(); // Tutup pop-up setting
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
                        onPressed: () {
                          // Simpan perubahan tipe pengeluaran dan batas harian
                          setState(() {
                            if (_expenseTypeController.text.isNotEmpty &&
                                selectedColor != null) {
                              expenseTypes.add(_expenseTypeController.text);
                              expenseTypeColors[_expenseTypeController.text] =
                                  selectedColor!;
                              availableColors.remove(
                                selectedColor,
                              ); // Hapus warna yang sudah dipilih
                            }
                            if (_dailyLimitController.text.isNotEmpty) {
                              dailyExpenseLimit =
                                  double.tryParse(_dailyLimitController.text) ??
                                  0;
                            }
                          });
                          Navigator.of(context).pop(); // Tutup pop-up setting
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
  }

  void _showPinSettings() {
    final TextEditingController _oldPinController = TextEditingController();
    final TextEditingController _newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<String?>(
          future: _getPin(), // Ambil PIN yang tersimpan
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              ); // Tampilkan loading indicator
            }

            final savedPin = snapshot.data; // Ambil nilai PIN yang tersimpan
            print("Saved PIN: $savedPin"); // Debugging: Cetak nilai savedPin

            return AlertDialog(
              title: Text("Atur PIN"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tampilkan field PIN lama hanya jika sudah ada PIN yang tersimpan
                  if (savedPin != null) ...[
                    TextField(
                      controller: _oldPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true, // Menyembunyikan teks (untuk PIN lama)
                      decoration: InputDecoration(
                        labelText: "Masukkan PIN Lama",
                      ),
                    ),
                    SizedBox(height: 8), // Tambahkan jarak antara field
                  ],
                  // Field untuk memasukkan PIN baru
                  TextField(
                    controller: _newPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true, // Menyembunyikan teks (untuk PIN baru)
                    decoration: InputDecoration(
                      labelText:
                          savedPin == null
                              ? "Masukkan PIN Baru"
                              : "Masukkan PIN Baru",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog pengaturan PIN
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    // Jika belum ada PIN yang tersimpan
                    if (savedPin == null) {
                      // Izinkan pengguna mengatur PIN baru tanpa validasi PIN lama
                      if (_newPinController.text.isNotEmpty) {
                        await _savePin(
                          _newPinController.text,
                        ); // Simpan PIN baru
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("PIN berhasil diatur."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(
                          context,
                        ).pop(); // Tutup dialog pengaturan PIN
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Silakan masukkan PIN baru."),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      return; // Hentikan proses
                    }

                    // Jika sudah ada PIN yang tersimpan, validasi PIN lama
                    if (_oldPinController.text != savedPin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("PIN lama salah. Silakan coba lagi."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return; // Hentikan proses jika PIN lama salah
                    }

                    // Simpan PIN baru jika diisi
                    if (_newPinController.text.isNotEmpty) {
                      await _savePin(_newPinController.text); // Simpan PIN baru
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("PIN berhasil diubah."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Silakan masukkan PIN baru."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    Navigator.of(context).pop(); // Tutup dialog pengaturan PIN
                  },
                  child: Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDisableConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi"),
          content: Text(
            "Apakah Anda yakin ingin menonaktifkan auto budgeting untuk target ini?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  targets[index]["disabled"] = true; // Nonaktifkan target
                });
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Lanjutkan"),
            ),
          ],
        );
      },
    );
  }

  void _showEnableConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi"),
          content: Text(
            "Apakah Anda yakin ingin mengaktifkan kembali target ini?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  targets[index]["disabled"] = false; // Aktifkan target
                });
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text("Lanjutkan"),
            ),
          ],
        );
      },
    );
  }

  void _reduceAmount() {
    if (_amountController.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Saldo dompet tabungan akan ditarik tunai"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog pertama
                  _showBiometricPopupForReduction(); // Tampilkan pop-up sidik jari
                },
                child: Text("Lanjutkan"),
              ),
            ],
          );
        },
      );
    }
  }

  // Fungsi untuk menampilkan pop-up sidik jari untuk pengurangan saldo
  void _showBiometricPopupForReduction() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Verifikasi Sidik Jari",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // Image.asset(
              //   'assets/images/fingerprint.png', // Gambar sidik jari
              //   width: 100,
              //   height: 100,
              // ),
              SizedBox(height: 16),
              Text(
                "Silakan letakkan jari Anda pada sensor sidik jari.",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup pop-up sidik jari
                  _completeReductionTransaction(); // Selesaikan transaksi pengurangan
                },
                child: Text("Verifikasi Sidik Jari"),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup pop-up sidik jari
                  _showPinInputPopupForReduction(); // Tampilkan pop-up input PIN
                },
                child: Text(
                  "Ganti ke Ketik PIN",
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk menampilkan pop-up input PIN untuk pengurangan saldo
  void _showPinInputPopupForReduction() {
    final TextEditingController _pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Masukkan PIN",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true, // Menyembunyikan teks (untuk PIN)
                decoration: InputDecoration(
                  labelText: "PIN",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_pinController.text.isNotEmpty) {
                    // Ambil PIN yang tersimpan
                    final savedPin = await _getPin();

                    // Bandingkan PIN yang dimasukkan dengan PIN yang tersimpan
                    if (_pinController.text == savedPin) {
                      Navigator.of(context).pop(); // Tutup pop-up input PIN
                      _completeReductionTransaction(); // Selesaikan transaksi pengurangan
                    } else {
                      // Tampilkan pesan error jika PIN salah
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("PIN salah. Transaksi dibatalkan."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    // Tampilkan pesan error jika PIN kosong
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Silakan masukkan PIN."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text("Verifikasi PIN"),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk menyelesaikan transaksi pengurangan saldo
  void _completeReductionTransaction() {
    setState(() {
      int amount = int.tryParse(_amountController.text) ?? 0;
      if (totalAmount >= amount) {
        totalAmount -= amount;
        // Kurangi saldo dompet tabungan (asumsi ada variabel untuk saldo dompet tabungan)
        // Misalnya: walletBalance -= amount;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Saldo tidak cukup!"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
    _amountController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Transaksi berhasil!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildExpensePieChart() {
    // Debug: Cetak seluruh purchaseHistory untuk verifikasi
    debugPrint('Purchase History: ${purchaseHistory.toString()}');

    // Kelompokkan data berdasarkan kategori
    final Map<String, double> categoryTotals = {};

    for (final expense in purchaseHistory) {
      final category = expense['category'] ?? 'Lainnya';
      final amount = (expense['amount'] ?? expense['price'] ?? 0).toDouble();

      if (amount > 0) {
        categoryTotals.update(
          category,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }

    // Debug: Cetak total per kategori
    debugPrint('Category Totals: ${categoryTotals.toString()}');

    // Jika tidak ada data
    if (categoryTotals.isEmpty) {
      return Center(child: Text('Belum ada data pengeluaran'));
    }

    // Buat sections untuk pie chart
    final pieSections =
        categoryTotals.entries.map((entry) {
          final category = entry.key;
          final value = entry.value;
          final total = categoryTotals.values.reduce((a, b) => a + b);
          final percentage = (value / total) * 100;

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
              sectionsSpace: 0, // Hilangkan jarak antar section
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildLegend(categoryTotals),
        SizedBox(height: 8), // Tambahkan jarak antara legenda dan teks
      ],
    );
  }

  Widget _buildLegend(Map<String, double> expenseTotals) {
    return Wrap(
      spacing: 8.0, // Jarak horizontal antara item
      runSpacing: 4.0, // Jarak vertikal antara baris
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
    // Calculate remaining amounts for each expense type
    Map<String, double> remainingAmounts = {};

    for (var type in expenseTypes) {
      double spent = purchaseHistory
          .where((expense) => expense['category'] == type)
          .fold(
            0.0,
            (sum, expense) => sum + (expense['amount'] ?? 0).toDouble(),
          );

      remainingAmounts[type] = (categoryLimits[type] ?? 0) - spent;
    }

    showDialog(
      context: context,
      builder: (context) {
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
                  "Limit Pengeluaran per Bulan",
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
                  double remaining = remainingAmounts[type] ?? 0;
                  bool isOverLimit = remaining < 0;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: expenseTypeColors[type]?.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.category,
                          color: expenseTypeColors[type],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        type,
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
                              isOverLimit ? Colors.red.shade700 : Colors.black,
                          fontWeight:
                              isOverLimit ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue.shade700),
                        onPressed: () {
                          _showEditExpenseLimitDialog(type);
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
  }

  void _showEditExpenseLimitDialog(String expenseType) {
    final TextEditingController _limitController = TextEditingController(
      text: categoryLimits[expenseType]?.toStringAsFixed(0) ?? '0',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Atur Limit untuk $expenseType"),
          content: TextField(
            controller: _limitController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Limit Bulanan (Rp)",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                if (_limitController.text.isNotEmpty) {
                  setState(() {
                    categoryLimits[expenseType] =
                        double.tryParse(_limitController.text) ?? 0;
                    _saveCategoryLimits(); // Simpan ke SharedPreferences
                  });
                  Navigator.pop(context);
                }
              },
              child: Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCategoryLimits() async {
    final prefs = await SharedPreferences.getInstance();
    categoryLimits.forEach((key, value) async {
      await prefs.setDouble('limit_$key', value);
    });
  }

  Future<void> _loadCategoryLimits() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      categoryLimits = Map.fromIterables(
        expenseTypes,
        expenseTypes.map((type) => prefs.getDouble('limit_$type') ?? 0),
      );
    });
  }
}
