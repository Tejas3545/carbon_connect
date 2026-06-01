import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  double _flights = 0;
  double _carUsage = 0;

  // Typical values (tons of CO2)
  // Flights: ~0.2 tons per hour
  // Car: ~0.0003 tons per km
  // Diet: Average ~2 tons per year for omnivore, 1.5 for vegetarian, 1 for vegan.

  double _totalEmissions = 0.0;
  String _dietMode = 'Omnivore';

  void _calculate() {
    double flightEmissions = _flights * 0.2;
    double carEmissions = _carUsage * 0.0003 * 365; // Approx km/day -> km/year
    double dietEmissions = 2.0; // Omnivore
    if (_dietMode == 'Vegetarian') dietEmissions = 1.5;
    if (_dietMode == 'Vegan') dietEmissions = 1.0;

    setState(() {
      _totalEmissions = flightEmissions + carEmissions + dietEmissions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Carbon Footprint Calculator',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculate your annual CO₂ impact.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Flights
            _buildSliderTitle('Flights (hours per year)', _flights.toStringAsFixed(0)),
            Slider(
              value: _flights,
              min: 0,
              max: 100,
              activeColor: Colors.blueAccent,
              onChanged: (val) {
                setState(() => _flights = val);
                _calculate();
              },
            ),
            const SizedBox(height: 16),

            // Car Usage
            _buildSliderTitle('Car Usage (km per day)', _carUsage.toStringAsFixed(0)),
            Slider(
              value: _carUsage,
              min: 0,
              max: 100,
              activeColor: Colors.greenAccent,
              onChanged: (val) {
                setState(() => _carUsage = val);
                _calculate();
              },
            ),
            const SizedBox(height: 16),

            // Diet
            Text('Diet Type', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              dropdownColor: const Color(0xFF1E293B),
              value: _dietMode,
              items: ['Omnivore', 'Vegetarian', 'Vegan']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _dietMode = val);
                  _calculate();
                }
              },
              isExpanded: true,
            ),
            const SizedBox(height: 32),

            // Result Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Annual Footprint',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalEmissions.toStringAsFixed(1)} Tonnes',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Let's pass the amount needed to offset if we navigate
                      context.push('/market'); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Buy ${_totalEmissions.ceil()} Credits to Offset',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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

  Widget _buildSliderTitle(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        Text(val, style: GoogleFonts.inter(color: Colors.white70)),
      ],
    );
  }
}
