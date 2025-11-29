class CadastralHeadView {
  final int sectorId;
  final String manzanaId;
  final int typeUser;
  final String recordCode;
  final String name;
  final String address;
  final String cadastro;
  final String commercialSector;
  final String province;
  final String district;
  final int supplyZoneCode;
  final String batch;
  final String? nromedidor;

  CadastralHeadView({
    required this.sectorId,
    required this.manzanaId,
    required this.typeUser,
    required this.recordCode,
    required this.name,
    required this.address,
    required this.cadastro,
    required this.commercialSector,
    required this.province,
    required this.district,
    required this.supplyZoneCode,
    required this.batch,
    required this.nromedidor,
  });

  factory CadastralHeadView.fromJson(Map<String, dynamic> json) {
    final dynamic sectorComercial = json['sectorcomercial'];

    return CadastralHeadView(
      sectorId: json['codsector'],
      manzanaId: json['codmanzanas'],
      typeUser: json['codtipousuario'],
      recordCode: json['nroinscripcion'],
      name: json['nombre'],
      address: json['direccion'],
      cadastro: json['catastro'],
      commercialSector: (sectorComercial == 0 || sectorComercial == null) ? '' : sectorComercial.toString(),
      province: json['codprovincia'],
      district: json['coddistrito'],
      supplyZoneCode: json['codzonaabas'],
      batch: json['lote'],
      nromedidor: json['nromedidor'],
    );
  }
}
