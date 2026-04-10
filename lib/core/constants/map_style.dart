/// Custom Google Maps style.
/// Goals: suppress all POI / transit labels, clean muted palette, let
/// 3D buildings show through, keep roads subtle so our markers pop.
const String kMapStyle = '''
[
  {
    "featureType": "all",
    "elementType": "labels",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#f0ece4" }]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#e8e2d8" }]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#dff0d8" }]
  },
  {
    "featureType": "landscape.natural.terrain",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#cfe8c2" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#a8d5e8" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#ffffff" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{ "color": "#d8d0c4" }, { "weight": 0.8 }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#f5dfa8" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{ "color": "#e0c880" }, { "weight": 1 }]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#f8f4ee" }]
  },
  {
    "featureType": "poi",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#e2f0d8" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#c8e8b0" }]
  },
  {
    "featureType": "poi.school",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#f4e8cc" }]
  },
  {
    "featureType": "poi.medical",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#fce8e8" }]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "building",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#ddd8cc" }]
  },
  {
    "featureType": "building",
    "elementType": "geometry.stroke",
    "stylers": [{ "color": "#c8c0b4" }, { "weight": 0.5 }]
  }
]
''';
