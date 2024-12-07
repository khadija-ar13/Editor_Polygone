import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:flutter_map_line_editor/flutter_map_line_editor.dart';
import 'package:latlong2/latlong.dart';

class PolygonPage extends StatefulWidget {
  const PolygonPage({super.key});

  @override
  State<PolygonPage> createState() => _PolygonPageState();
}

class _PolygonPageState extends State<PolygonPage> {
  late PolyEditor polyEditor;

  // Polygone temporaire utilisé pour dessiner
  var drawTempPolygon = Polygon(color: Colors.green, points: <LatLng>[]);

  // Liste des polygones enregistrés
  final List<Polygon> addedPolygons = [];

  // Polygone sélectionné
  Polygon? selectedPolygon;

  @override
  void initState() {
    super.initState();

    // Initialisation de PolyEditor
    polyEditor = PolyEditor(
      addClosePathMarker: true,
      points: drawTempPolygon.points,
      pointIcon: const Icon(Icons.crop_square, size: 23),
      intermediateIcon: const Icon(Icons.lens, size: 15, color: Colors.grey),
      callbackRefresh: (LatLng? _) => setState(() {}),
    );
  }

  // Vérifie si un point est à l'intérieur d'un polygone
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length; i++) {
      LatLng a = polygon[i];
      LatLng b = polygon[(i + 1) % polygon.length];
      bool intersect = ((a.latitude > point.latitude) != (b.latitude > point.latitude)) &&
          (point.longitude <
              (b.longitude - a.longitude) *
                  (point.latitude - a.latitude) /
                  (b.latitude - a.latitude) +
                  a.longitude);
      if (intersect) intersectCount++;
    }
    return (intersectCount % 2) == 1;
  }

  // Action lorsqu'on clique sur la carte
  void _onMapTapped(LatLng latLng) {
    Polygon? foundPolygon;

    // Parcourt les polygones ajoutés pour voir si latLng est dedans
    for (var poly in addedPolygons) {
      if (isPointInPolygon(latLng, poly.points)) {
        foundPolygon = poly;
        break;
      }
    }

    setState(() {
      selectedPolygon = foundPolygon;

      // Si aucun polygone n'est sélectionné, ajoute un point au polygone temporaire
      if (selectedPolygon == null) {
        polyEditor.add(drawTempPolygon.points, latLng);
      }
    });
  }

  // Sauvegarde le polygone temporaire dans la liste
  void _savePolygon() {
    setState(() {
      if (selectedPolygon != null) {
        addedPolygons.remove(selectedPolygon);
      }
      if (drawTempPolygon.points.isNotEmpty) {
        var poly = Polygon(
          points: drawTempPolygon.points.toList(),
          color: Colors.lightBlueAccent.withOpacity(0.5),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
        );
        addedPolygons.add(poly);
        drawTempPolygon.points.clear();
        selectedPolygon = poly;
      }
    });
  }

  // Réinitialise le polygone temporaire
  void _resetPolygon() {
    setState(() {
      drawTempPolygon.points.clear();
      selectedPolygon = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Met en évidence le polygone sélectionné
    List<Polygon> displayedPolygons = addedPolygons.map((p) {
      if (p == selectedPolygon) {
        return Polygon(
          points: p.points,
          color: Colors.yellow.withOpacity(0.5),
          borderColor: Colors.yellow,
          borderStrokeWidth: 3,
        );
      }
      return p;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Constructions"),
      ),
      body: FlutterMap(
        options: MapOptions(
          onTap: (tapPos, latLng) => _onMapTapped(latLng),
          initialCenter: LatLng(45.5231, -122.6765),
          initialZoom: 10,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          PolygonLayer(polygons: displayedPolygons),
          if (drawTempPolygon.points.isNotEmpty)
            PolygonLayer(polygons: [drawTempPolygon]),
          DragMarkers(markers: polyEditor.edit()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _savePolygon,
            child: const Icon(Icons.save),
            tooltip: "Enregistrer le polygone",
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _resetPolygon,
            child: const Icon(Icons.refresh),
            tooltip: "Réinitialiser le polygone temporaire",
          ),
          const SizedBox(height: 10),
          // Bouton Éditer
          FloatingActionButton(
            onPressed: () {
              setState(() {
                if (selectedPolygon != null) {
                  // Met les points du polygone sélectionné dans polyEditor
                  polyEditor.points.clear();
                  polyEditor.points.addAll(selectedPolygon!.points);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sélectionnez un polygone à éditer")),
                  );
                }
              });
            },
            child: const Icon(Icons.edit),
            tooltip: "Éditer un polygone",
          ),
          const SizedBox(height: 10),
          // Bouton Supprimer
          FloatingActionButton(
            onPressed: () {
              setState(() {
                if (selectedPolygon != null) {
                  addedPolygons.remove(selectedPolygon);
                  selectedPolygon = null;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sélectionnez un polygone à supprimer")),
                  );
                }
              });
            },
            child: const Icon(Icons.delete),
            tooltip: "Supprimer un polygone",
          ),
        ],
      ),
    );
  }
}