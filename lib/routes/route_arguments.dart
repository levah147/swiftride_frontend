// Arguments models for passing data through routes

class RideOptionsArguments {
  final String from;
  final String to;
  final bool isScheduled;

  RideOptionsArguments({
    required this.from,
    required this.to,
    required this.isScheduled,
  });
}

class DriverMatchingArguments {
  final String from;
  final String to;
  final Map<String, dynamic> rideType;
  final bool isScheduled;

  DriverMatchingArguments({
    required this.from,
    required this.to,
    required this.rideType,
    required this.isScheduled,
  });
}

class RideTrackingArguments {
  final String from;
  final String to;
  final Map<String, dynamic> rideType;
  final Map<String, dynamic> driver;

  RideTrackingArguments({
    required this.from,
    required this.to,
    required this.rideType,
    required this.driver,
  });
}

class RideCompletionArguments {
  final String from;
  final String to;
  final Map<String, dynamic> rideType;
  final Map<String, dynamic> driver;
  final String duration;
  final String distance;

  RideCompletionArguments({
    required this.from,
    required this.to,
    required this.rideType,
    required this.driver,
    required this.duration,
    required this.distance,
  });
}