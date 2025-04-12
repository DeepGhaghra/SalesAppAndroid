import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'dart:io';

class PrinterSetupScreen extends StatefulWidget {
  @override
  _PrinterSetupScreenState createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends State<PrinterSetupScreen> {
  List<String> devices = [];
  String? selectedPrinter;
  TextEditingController ipController = TextEditingController();
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedPrinter = prefs.getString('printer_ip');
    });
  }

  Future<void> _savePrinter(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    String cleanIP = ip.split(":")[0];

    await prefs.setString('printer_ip', cleanIP);
    debugPrint("Saved Printer IP: $ip");

    if (!mounted) return; // Prevent errors if widget is unmounted

    setState(() {
      selectedPrinter = cleanIP;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Printer Saved: $ip")));
  }

  Future<String?> getSubnet() async {
    final info = NetworkInfo();
    String? wifiIP = await info.getWifiIP();
    if (wifiIP == null) return null;

    List<String> parts = wifiIP.split(".");
    return "${parts[0]}.${parts[1]}.${parts[2]}"; // Extract subnet
  }

  Future<List<String>> scanNetwork() async {
    String? subnet = await getSubnet();
    if (subnet == null) return [];

    List<String> activeDevices = [];
    List<Future> futures = [];

    for (int i = 1; i < 255; i++) {
      String ip = "$subnet.$i";
      futures.add(
        Process.run("ping", ["-c", "1", ip]).then((result) {
          if (result.exitCode == 0) {
            activeDevices.add(ip);
          }
        }),
      );
    }

    await Future.wait(futures);
    return activeDevices;
  }

  Future<void> _scanNetwork() async {
    setState(() => isScanning = true);
    List<String> foundDevices = await scanNetwork();
    setState(() {
      devices = foundDevices;
      isScanning = false;
    });
  }

  Future<void> _detectPrinter(String ip) async {
    String? printer = await scanPrinterPorts(ip);
    if (!mounted) return; // Prevent setState if widget is unmounted

    if (printer != null) {
      _savePrinter(printer);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No printer detected on $ip")));
    }
  }

  Future<String?> scanPrinterPorts(String ip) async {
    List<int> commonPorts = [9100, 515, 631, 9220]; // Raw TCP, LPD, IPP

    for (int port in commonPorts) {
      try {
        debugPrint("🔍 Testing $ip:$port...");

        final printer = PrinterNetworkManager(
          ip,
          port: port,
          timeout: Duration(seconds: 3),
        );
        final PosPrintResult res = await printer.connect();
        await printer.disconnect();
        if (res == PosPrintResult.success) {
          debugPrint("🎯 Found printer at $ip:$port");
          return "$ip:$port"; // Return first working printer
        } else {
          debugPrint("🚫 Port $port not working: ${res.msg}");
        }
      } catch (e) {
        debugPrint("❌ $ip:$port not responding.");
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Printer Setup")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _scanNetwork,
              child:
                  isScanning
                      ? CircularProgressIndicator()
                      : Text("Scan Wi-Fi Devices"),
            ),
            SizedBox(height: 10),
            isScanning
                ? Center(child: CircularProgressIndicator())
                : devices.isEmpty
                ? Text("No devices found")
                : Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        child: ListTile(
                          title: Text(
                            devices[index],
                            style: TextStyle(fontSize: 16),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _detectPrinter(devices[index]),
                            child: Text("Check Printer"),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            Divider(),
            Text(
              "Manual Entry",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: ipController,
              decoration: InputDecoration(labelText: "Enter Printer IP"),
            ),
            ElevatedButton(
              onPressed: () => _savePrinter(ipController.text.trim()),
              child: Text("Save Printer Manually"),
            ),
            if (selectedPrinter != null)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Selected Printer: $selectedPrinter",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
