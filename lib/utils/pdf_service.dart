import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

class PdfService {
  static Future<void> exportHistoryPDF({
    required Map<String, dynamic> data,
    required String Function(String?) getTypeName,
    required String Function(String) translateKey,
    required String Function(dynamic) v,
    required String Function(String) buildImageUrl,
  }) async {
    try {
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/history_${data["id"]}.pdf");

      final summary = data["summary"] ?? {};
      final full = data["full_result"] ?? {};
      final plates = full["plates"] ?? [];
      final vehicles = full["vehicles"] ?? [];
      final faces = full["faces"] ?? [];

      /// IMAGE
      pw.Widget? imageWidget;
      final imagePath = data["representative_image_path"];

      try {
        if (imagePath != null && imagePath.isNotEmpty) {
          final image = await networkImage(buildImageUrl(imagePath));
          imageWidget = pw.Image(image, height: 200, fit: pw.BoxFit.cover);
        }
      } catch (_) {
        imageWidget = null;
      }

      /// ADD PAGE
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [

            /// HEADER
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "CHI TIẾT NHẬN DIỆN",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text("ID: ${data["id"] ?? ""}"),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            /// IMAGE
            if (imageWidget != null) ...[
              pw.Text("BẰNG CHỨNG HÌNH ẢNH",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: imageWidget,
              ),
              pw.SizedBox(height: 10),
            ],

            /// AI SUMMARY
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("PHÂN TÍCH AI",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("Loại: ${getTypeName(data["type"])}"),

                  ...summary.entries.map<pw.Widget>((e) {
                    return pw.Text(
                      "${translateKey(e.key)}: ${v(e.value)}",
                    );
                  }),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            /// PLATES
            if (plates.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BIỂN SỐ",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Wrap(
                      spacing: 6,
                      children: plates.map<pw.Widget>((p) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.green),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(v(p["plate"] ?? p)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            pw.SizedBox(height: 10),

            /// VEHICLES
            if (vehicles.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("PHƯƠNG TIỆN",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ...vehicles.map<pw.Widget>((vcl) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              "Loại: ${translateKey(vcl["class_name"])}"),
                          pw.Text(
                              "Biển số: ${vcl["plate"]?["text"] ?? "Không có"}"),
                          pw.SizedBox(height: 5),
                        ],
                      );
                    }),
                  ],
                ),
              ),

            pw.SizedBox(height: 10),

            /// FACES
            if (faces.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("KHUÔN MẶT",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ...faces.map<pw.Widget>((f) {
                      final person = f["person"];

                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              "Độ tin cậy: ${(f["match_score"] * 100).toStringAsFixed(1)}%"),
                          if (person != null) ...[
                            pw.Text("Tên: ${person["name"]}"),
                            pw.Text(
                                "SĐT: ${person["info"]?["phone"] ?? "Không có"}"),
                          ] else
                            pw.Text("Người lạ"),
                          pw.SizedBox(height: 5),
                        ],
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      );

      /// SAVE

      await file.writeAsBytes(await pdf.save());
      if (await file.exists()) {
        await OpenFilex.open(file.path);
      } else {
        debugPrint("File không tồn tại");
      }
      debugPrint("PDF saved: ${file.path}");
    } catch (e) {
      throw Exception("Lỗi export PDF: $e");
    }
  }
}