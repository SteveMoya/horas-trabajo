import 'package:flutter/material.dart';

/// `true` si el usuario activó "Quitar animaciones" en accesibilidad del
/// sistema. Las animaciones en loop o continuas (no las transiciones
/// puntuales y cortas) deben respetarlo y quedar estáticas.
bool reducirMovimiento(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;
