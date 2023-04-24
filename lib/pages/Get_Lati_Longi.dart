import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sound_mode/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

class GetLatLongScreen extends StatefulWidget {
  const GetLatLongScreen({super.key});

  @override
  State<GetLatLongScreen> createState() => _GetLatLongScreenState();
}

class _GetLatLongScreenState extends State<GetLatLongScreen> {
  RingerModeStatus _soundMode = RingerModeStatus.unknown;
  String? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _getCurrentSoundMode();
    _getPermissionStatus();
  }

  double? lat;
  double? long;
  String address = "";
  String address1 = "";
  String address2 = "";
  String address3 = "";
  String address4 = "";

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  getLatLong() {
    Future<Position> data = _determinePosition();
    data.then((value) {
      print("value $value");
      setState(() {
        lat = value.latitude;
        long = value.longitude;
      });

      getAddress(value.latitude, value.longitude);
    }).catchError((error) {
      print("Error $error");
    });
  }

  getAddress(lat, long) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
    setState(() {
      address =
          placemarks[3].administrativeArea!; //+ " " + placemarks[3].country!;
      address1 = placemarks[3]
          .subAdministrativeArea!; //+ " " + placemarks[4].country!;
      address2 = placemarks[3].locality!;
      address4 = placemarks[3].postalCode!;
    });

    for (int i = 0; i < placemarks.length; i++) {
      print("INDEX $i ${placemarks[i]}");
    }
  }

  Future<void> _getCurrentSoundMode() async {
    RingerModeStatus ringerStatus = RingerModeStatus.unknown;

    Future.delayed(const Duration(seconds: 1), () async {
      try {
        ringerStatus = await SoundMode.ringerModeStatus;
      } catch (err) {
        ringerStatus = RingerModeStatus.unknown;
      }

      setState(() {
        _soundMode = ringerStatus;
      });
    });
  }

  Future<void> _getPermissionStatus() async {
    bool? permissionStatus = false;
    try {
      permissionStatus = await PermissionHandler.permissionsGranted;
      print(permissionStatus);
    } catch (err) {
      print(err);
    }

    setState(() {
      _permissionStatus =
          permissionStatus! ? "Permissions Enabled" : "Permissions not granted";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "Noiseless VIT",
              style: TextStyle(color: Colors.deepOrange),
            )
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Running on: $_soundMode'),
            Text('Permission status: $_permissionStatus'),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () => _getCurrentSoundMode(),
              child: const Text('Get current sound mode'),
            ),
            ElevatedButton(
              onPressed: () => _setNormalMode(),
              child: const Text('Set Normal mode'),
            ),
            ElevatedButton(
              onPressed: () => _setSilentMode(),
              child: const Text('Set Silent mode'),
            ),
            ElevatedButton(
              onPressed: () => _setVibrateMode(),
              child: const Text('Set Vibrate mode'),
            ),
            ElevatedButton(
                onPressed: getLatLong, child: const Text("Set Position")),
            ElevatedButton(
              onPressed: () => _openDoNotDisturbSettings(),
              child: const Text('Open Do Not Access Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setSilentMode() async {
    RingerModeStatus status;

    if ((lat! > 23.0700000 && lat! < 23.0800000) &&
        (long! > 76.8400000 && long! < 76.8600000)) {
      try {
        status = await SoundMode.setSoundMode(RingerModeStatus.silent);

        setState(() {
          _soundMode = status;
        });
      } on PlatformException {
        print('Do Not Disturb access permissions required!');
      }
    } else {
      _setNormalMode();
    }
  }

  Future<void> _setNormalMode() async {
    RingerModeStatus status;

    try {
      status = await SoundMode.setSoundMode(RingerModeStatus.normal);
      setState(() {
        _soundMode = status;
      });
    } on PlatformException {
      print('Do Not Disturb access permissions required!');
    }
  }

  Future<void> _setVibrateMode() async {
    RingerModeStatus status;

    try {
      status = await SoundMode.setSoundMode(RingerModeStatus.vibrate);

      setState(() {
        _soundMode = status;
      });
    } on PlatformException {
      print('Do Not Disturb access permissions required!');
    }
  }

  Future<void> _openDoNotDisturbSettings() async {
    await PermissionHandler.openDoNotDisturbSetting();
  }
}
