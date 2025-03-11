import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'dart:typed_data';
import 'dart:async';

void main() {
  runApp(FXTaktApp());
}

class FXTaktApp extends StatefulWidget {
  @override
  _FXTaktAppState createState() => _FXTaktAppState();
}

class _FXTaktAppState extends State<FXTaktApp> {
  MidiCommand _midiCommand = MidiCommand();
  List<MidiDevice> _devices = [];
  MidiDevice? _selectedDevice;
  double _crossfadeValue = 0.0;
  bool _freezeActive = false;
  bool _beatRepeatActive = false;
  Timer? _beatRepeatTimer;
  
  @override
  void initState() {
    super.initState();
    _fetchMidiDevices();
  }

  void _fetchMidiDevices() async {
    List<MidiDevice>? devices = await _midiCommand.devices;
    if (devices != null && devices.isNotEmpty) {
      setState(() {
        _devices = devices;
        // Ensure the selected device is still valid
        if (!_devices.contains(_selectedDevice)) {
          _selectedDevice = null;
        }
      });
    }
  }

  void _connectToDevice(MidiDevice device) {
    if (_selectedDevice != null && _selectedDevice!.id == device.id) {
      print("Device already connected: \${device.name}");
      return;
    }
    _midiCommand.connectToDevice(device);
    setState(() {
      _selectedDevice = device;
    });
  }

  void _sendMidiCC(int control, int value) {
    int midiChannel = 8; // Channel 9 in MIDI (0-indexed)
    if (_selectedDevice != null) {
      print("Sending MIDI CC: Control = $control, Value = $value on Channel 9 to \${_selectedDevice!.name}");
      _midiCommand.sendData(Uint8List.fromList([0xB0 + midiChannel, control, value]));
    } else {
      print("❌ ERROR: No MIDI device selected!");
    }
  }

  void _toggleFreezeMode() {
    setState(() {
      _freezeActive = !_freezeActive;
      if (_freezeActive) {
        _sendMidiCC(84, 127);
        _sendMidiCC(85, 127);
      } else {
        _sendMidiCC(84, 0);
        _sendMidiCC(85, 0);
      }
    });
  }

  void _toggleBeatRepeat() {
    if (_beatRepeatActive) {
      _beatRepeatTimer?.cancel();
      setState(() {
        _beatRepeatActive = false;
      });
    } else {
      setState(() {
        _beatRepeatActive = true;
      });
      _beatRepeatTimer = Timer.periodic(Duration(milliseconds: 120), (timer) {
        _sendMidiCC(15, 127);
        Future.delayed(Duration(milliseconds: 50), () {
          _sendMidiCC(15, 0);
        });
      });
    }
  }

  void _updateCrossfade(double value) {
    setState(() {
      _crossfadeValue = value;
      int filterValue = (20 + (107 * value)).toInt();
      int reverbValue = (127 * value).toInt();
      int delayValue = (127 * value).toInt();
      _sendMidiCC(74, filterValue);
      _sendMidiCC(91, reverbValue);
      _sendMidiCC(84, delayValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Column(
            children: [
              Text('FXTAKT', style: TextStyle(fontFamily: 'DINCondensed', color: Colors.white, fontSize: 24)),
              Text('Digitakt Performance Controller', style: TextStyle(fontFamily: 'DINCondensed', color: Colors.white, fontSize: 14)),
            ],
          ),
          backgroundColor: Colors.black,
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], shadowColor: Colors.orangeAccent, elevation: 10),
                onPressed: _fetchMidiDevices,
                child: Text("REFRESH MIDI DEVICES", style: TextStyle(color: Colors.white, fontFamily: 'DINCondensed')),
              ),
              DropdownButton<MidiDevice>(
                hint: Text("SELECT MIDI DEVICE", style: TextStyle(color: Colors.white, fontFamily: 'DINCondensed', fontSize: 16)),
                dropdownColor: Colors.black,
                value: _devices.contains(_selectedDevice) ? _selectedDevice : null,
                items: _devices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text(device.name, style: TextStyle(color: Colors.white, fontFamily: 'DINCondensed')),
                  );
                }).toList(),
                onChanged: (device) {
                  if (device != null) {
                    setState(() {
                      _selectedDevice = device;
                    });
                    _connectToDevice(device);
                  }
                },
              ),
              Text(
                _selectedDevice != null ? "CONNECTED: ${_selectedDevice!.name}" : "NO DEVICE CONNECTED",
                style: TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'DINCondensed'),
              ),
              Text('CROSSFADE', style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'DINCondensed')),
              Slider(
                value: _crossfadeValue,
                onChanged: _updateCrossfade,
                activeColor: Colors.orangeAccent,
                inactiveColor: Colors.grey,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _toggleBeatRepeat,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                    child: Text("BEAT REPEAT", style: TextStyle(color: Colors.white, fontFamily: 'DINCondensed')),
                  ),
                  ElevatedButton(
                    onPressed: _toggleFreezeMode,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                    child: Text("FREEZE MODE", style: TextStyle(color: Colors.white, fontFamily: 'DINCondensed')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
