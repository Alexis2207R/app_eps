class CadastralImage {
  final String path; // Ruta local del archivo
  final String name; // Nombre del archivo (timestamp)
  String status; // "Pendiente" o "Sincronizado"
  String? codFichaImagen; // ID del servidor (solo si está Sincronizado)

  CadastralImage({
    required this.path,
    required this.name,
    this.status = 'Pendiente',
    this.codFichaImagen,
  });

  factory CadastralImage.fromJson(Map<String, dynamic> json) {
    return CadastralImage(
      path: json['path'],
      name: json['name'],
      status: json['status'],
      codFichaImagen: json['codFichaImagen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'status': status,
      'codFichaImagen': codFichaImagen,
    };
  }

  bool get isSynchronized => status == 'Sincronizado';
}
