# Holding Group · Órdenes de material

Aplicación Flutter para Android e iPhone. Las órdenes se guardan exclusivamente en la base local del teléfono (`sqflite`): no hay cuentas, servidor ni sincronización externa.

## Funciones incluidas

- Número correlativo local que inicia en 000389.
- Datos del encabezado y hasta 30 filas en el PDF.
- Captura de firma manuscrita con el dedo o lápiz.
- Generación, vista previa, impresión y compartición del PDF desde el dispositivo.
- Historial local de órdenes; desde este historial se puede volver a abrir el PDF.

El encabezado reproduce el nombre del logo **HOLDING GROUP** en tipografía. Para utilizar el archivo oficial del isotipo, coloque el archivo autorizado como `assets/holding_group_logo.png` y agréguelo a `pubspec.yaml`; así se evita extraer un logo borroso desde la fotografía de referencia.

## Preparación

1. Instale Flutter estable: https://docs.flutter.dev/get-started/install
2. Desde esta carpeta ejecute:

```powershell
flutter create . --platforms=android,ios
flutter pub get
flutter run
```

3. Para compilar Android: `flutter build appbundle`.
4. Para compilar iPhone se necesita macOS con Xcode: `flutter build ipa`.

## Nota sobre la firma

La firma incluida es una firma electrónica manuscrita y se incrusta en el PDF. No es una firma digital criptográfica con certificado. Si el documento requiere validez legal específica, se debe integrar un proveedor de firma certificado según el país y el proceso de la empresa.
