import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';

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

      final summary = data["summary"] ?? {};
      final full = data["full_result"] ?? {};
      final plates = full["plates"] ?? [];
      final vehicles = full["vehicles"] ?? [];
      final faces = full["faces"] ?? [];
      final imagePath = data["representative_image_path"];
      
      final primaryColor = PdfColor.fromHex('#0F4C75');
      final secondaryColor = PdfColor.fromHex('#3282B8');

      pw.ImageProvider? imageProvider;
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          imageProvider = await networkImage(buildImageUrl(imagePath));
        } catch (e) {
          debugPrint("PDF Image error: $e");
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          header: (context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "BÁO CÁO GIÁM SÁT GIAO THÔNG",
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "Hệ thống phân tích AI thông minh",
                        style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("ID: ${data["id"]}", style: pw.TextStyle(fontSize: 8)),
                      pw.Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: primaryColor, thickness: 2),
              pw.SizedBox(height: 10),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Phần mềm AI Traffic App", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  pw.Text("Trang ${context.pageNumber} / ${context.pagesCount}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
              ),
            ],
          ),
          build: (context) => [
            // Thông tin chung & Ảnh
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cột trái: Ảnh
                if (imageProvider != null)
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("HÌNH ẢNH GHI NHẬN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: primaryColor)),
                        pw.SizedBox(height: 5),
                        pw.Container(
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
                          child: pw.Image(imageProvider, height: 150, fit: pw.BoxFit.contain),
                        ),
                      ],
                    ),
                  ),
                if (imageProvider != null) pw.SizedBox(width: 20),
                
                // Cột phải: Summary
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TỔNG QUAN PHÂN TÍCH", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: primaryColor)),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Column(
                          children: [
                            _buildSummaryRow("Loại hình:", getTypeName(data["type"])),
                            ...summary.entries.map((e) => _buildSummaryRow("${translateKey(e.key)}:", v(e.value))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Phần Chi tiết Biển số & Phương tiện
            if (plates.isNotEmpty || vehicles.isNotEmpty) ...[
              pw.Text("CHI TIẾT PHƯƠNG TIỆN & BIỂN SỐ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: primaryColor)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(4),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: secondaryColor),
                    children: [
                      _buildTableCell("Loại xe", isHeader: true),
                      _buildTableCell("Biển số", isHeader: true),
                      _buildTableCell("Chủ sở hữu", isHeader: true),
                      _buildTableCell("Độ tin cậy", isHeader: true),
                    ],
                  ),
                  // Data from plates
                  ...plates.map((p) {
                    final owner = p["owner"] ?? {};
                    return pw.TableRow(
                      children: [
                        _buildTableCell(translateKey(p["class_name"] ?? "car")),
                        _buildTableCell(v(p["plate"])),
                        _buildTableCell(owner["found"] == true ? owner["name"] : "Không xác định"),
                        _buildTableCell("${((p["confidence"] ?? 0) * 100).toStringAsFixed(1)}%"),
                      ],
                    );
                  }),
                  // Data from vehicles (if not redundant)
                  ...vehicles.where((vcl) => !plates.any((p) => p["plate"] == (vcl["plate"]?["text"]))).map((vcl) {
                    final plate = vcl["plate"] ?? {};
                    final owner = plate["owner"] ?? {};
                    return pw.TableRow(
                      children: [
                        _buildTableCell(translateKey(vcl["class_name"] ?? "car")),
                        _buildTableCell(v(plate["text"])),
                        _buildTableCell(owner["found"] == true ? owner["name"] : "Không xác định"),
                        _buildTableCell("${((plate["confidence"] ?? 0) * 100).toStringAsFixed(1)}%"),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Phần Chi tiết Khuôn mặt
            if (faces.isNotEmpty) ...[
              pw.Text("CHI TIẾT NHẬN DIỆN KHUÔN MẶT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: primaryColor)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: secondaryColor),
                    children: [
                      _buildTableCell("Họ và Tên", isHeader: true),
                      _buildTableCell("Thông tin liên lạc", isHeader: true),
                      _buildTableCell("Độ tin cậy", isHeader: true),
                    ],
                  ),
                  ...faces.map((f) {
                    final matches = f["top_matches"] as List? ?? [];
                    if (matches.isEmpty) {
                      return pw.TableRow(children: [_buildTableCell("Người lạ"), _buildTableCell("-"), _buildTableCell("-")]);
                    }
                    final top = matches.first;
                    return pw.TableRow(
                      children: [
                        _buildTableCell(v(top["name"])),
                        _buildTableCell("SĐT: ${v(top["info"]?["phone"])}\nCCCD: ${v(top["info"]?["cccd"])}"),
                        _buildTableCell("${((top["match_score"] ?? 0) * 100).toStringAsFixed(1)}%"),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      );

      // Lưu file
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/BaoCao_GiaoThong_${data["id"]}.pdf");
      await file.writeAsBytes(await pdf.save());
      
      if (await file.exists()) {
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      debugPrint("Lỗi export PDF: $e");
      throw Exception("Lỗi export PDF: $e");
    }
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: isHeader ? PdfColors.white : PdfColors.black,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
