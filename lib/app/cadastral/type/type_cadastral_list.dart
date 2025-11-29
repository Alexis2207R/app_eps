class CadastralList {
  final String sucursal;
  final String? nromedidor;
  final String? direccionFicha;
  final String? propietario;
  final String? localId;
  final String? nroInscripcion;
  final String? nroFicha;
  final String? empadronador;
  bool get synchronized => (nroInscripcion != null && nroInscripcion!.isNotEmpty) && (nroFicha != null && nroFicha!.isNotEmpty);

  CadastralList({
    required this.sucursal,
    this.nromedidor,
    this.direccionFicha,
    this.propietario,
    this.localId,
    this.nroInscripcion,
    this.nroFicha,
    this.empadronador,
  });

  factory CadastralList.fromJson(Map<String, dynamic> json) {
    return CadastralList(
      sucursal: json['sucursal'],
      nromedidor: json['nromedidor']?.toString() ?? 'Sin medidor',
      direccionFicha: json['direccion_ficha']?.toString() ?? 'Sin dirección',
      propietario: json['propietario'] ?? 'Sin propietario',
      localId: json['localId'],
      nroInscripcion: json['nroinscripcion']?.toString(),
      nroFicha: json['nroficha']?.toString(),
      empadronador: json['empadronador']?.toString(),
    );
  }
}
