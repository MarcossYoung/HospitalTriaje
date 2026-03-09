/// Emergency tips per complaint_category.
/// Each entry has: title, dos (qué hacer), donts (qué no hacer).
class EmergencyTips {
  const EmergencyTips({
    required this.title,
    required this.dos,
    required this.donts,
    required this.callEmergency,
  });

  final String title;
  final List<String> dos;
  final List<String> donts;
  final bool callEmergency;
}

const Map<String, EmergencyTips> kEmergencyTips = {
  'cardiaco': EmergencyTips(
    title: 'Emergencia cardíaca',
    callEmergency: true,
    dos: [
      'Llame al 911 de inmediato',
      'Haga que el paciente se siente o recueste cómodamente',
      'Afloje ropa ajustada (corbata, cuello)',
      'Si tiene aspirina disponible y no es alérgico, déle una (325mg) a masticar',
      'Si el paciente pierde el conocimiento, inicie RCP si está capacitado',
      'Permanezca con el paciente hasta que llegue la ayuda',
    ],
    donts: [
      'No deje al paciente solo',
      'No le dé nada de comer ni beber',
      'No permita que el paciente conduzca',
      'No espere para llamar al 911',
    ],
  ),
  'neurologico': EmergencyTips(
    title: 'Emergencia neurológica',
    callEmergency: true,
    dos: [
      'Llame al 911 inmediatamente',
      'Anote la hora exacta en que comenzaron los síntomas',
      'Si el paciente está consciente, manténgalo tranquilo y acostado',
      'Si tiene convulsiones: proteja la cabeza, retire objetos peligrosos cerca',
      'Observe y describa todos los síntomas al médico',
    ],
    donts: [
      'No meta nada en la boca durante una convulsión',
      'No le dé medicamentos sin indicación médica',
      'No deje al paciente solo',
      'No le dé agua ni alimentos',
      'No inmovilice al paciente durante una convulsión',
    ],
  ),
  'trauma': EmergencyTips(
    title: 'Trauma / Hemorragia',
    callEmergency: true,
    dos: [
      'Aplique presión directa y firme sobre la herida con un paño limpio',
      'Eleve la extremidad afectada si es posible',
      'Si el sangrado empapa el paño, agregue más sin retirar el primero',
      'Mantenga al paciente quieto y abrigado',
      'Llame al 911 si el sangrado es severo',
    ],
    donts: [
      'No retire objetos incrustados en la herida',
      'No aplique torniquetes sin entrenamiento (excepto en caso extremo)',
      'No limpie heridas profundas con alcohol o agua oxigenada',
      'No deje de aplicar presión',
    ],
  ),
  'respiratorio': EmergencyTips(
    title: 'Dificultad respiratoria',
    callEmergency: true,
    dos: [
      'Llame al 911 de inmediato',
      'Siente al paciente en posición erguida (no acostado)',
      'Afloje ropa que comprima el pecho',
      'Si tiene inhalador prescrito, úselo según indicación',
      'Mantenga la calma para reducir el pánico',
    ],
    donts: [
      'No acueste al paciente boca arriba',
      'No le dé medicamentos sin indicación',
      'No tape la boca o nariz del paciente',
      'No deje al paciente solo',
    ],
  ),
  'abdominal': EmergencyTips(
    title: 'Dolor abdominal severo',
    callEmergency: false,
    dos: [
      'Diríjase a urgencias hospitalarias de inmediato',
      'Anote cuándo comenzó el dolor y su localización exacta',
      'Mantenga al paciente cómodo y en reposo',
      'Lleve una lista de medicamentos actuales',
    ],
    donts: [
      'No le dé analgésicos sin indicación médica (pueden enmascarar síntomas)',
      'No le dé alimentos ni bebidas',
      'No aplique calor en el abdomen sin indicación',
    ],
  ),
  'infeccioso': EmergencyTips(
    title: 'Infección / Fiebre alta',
    callEmergency: false,
    dos: [
      'Diríjase a urgencias si la fiebre supera 39.5°C o tiene rigidez de cuello',
      'Mantenga al paciente hidratado con líquidos claros',
      'Use paños húmedos tibios en la frente para bajar la fiebre',
      'Tome la temperatura cada 2 horas',
    ],
    donts: [
      'No use aspirina en menores de 16 años',
      'No cubra con muchas cobijas si hay fiebre alta',
      'No use baños de agua helada',
      'No retrase la atención médica si hay confusión o rigidez de cuello',
    ],
  ),
  'general': EmergencyTips(
    title: 'Malestar general',
    callEmergency: false,
    dos: [
      'Descanse y manténgase hidratado',
      'Monitoree sus síntomas',
      'Acuda a urgencias si los síntomas empeoran',
    ],
    donts: [
      'No tome medicamentos sin indicación médica',
      'No ignore síntomas que empeoren progresivamente',
    ],
  ),
};

EmergencyTips getTips(String category) {
  return kEmergencyTips[category] ?? kEmergencyTips['general']!;
}
