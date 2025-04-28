import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../models/client.dart';
import '../models/company.dart';

class PdfService {
  /// Generate a PDF invoice and return the file path
  static Future<String> generateInvoice({
    required Invoice invoice,
    required Client client,
    required Company company,
  }) async {
    final pdf = pw.Document();

    // Load font
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Define styles
    final titleStyle = pw.TextStyle(font: fontBold, fontSize: 24);
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 16);
    final contentStyle = pw.TextStyle(font: font, fontSize: 12);
    final smallStyle = pw.TextStyle(font: font, fontSize: 10);
    final highlightStyle =
        pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue700);

    // Add page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with company info and logo
            _buildHeader(company, titleStyle, contentStyle),
            pw.SizedBox(height: 20),

            // Invoice info (number, date, due date)
            _buildInvoiceInfo(invoice, headerStyle, contentStyle),
            pw.SizedBox(height: 20),

            // Client info
            _buildClientInfo(client, headerStyle, contentStyle),
            pw.SizedBox(height: 30),

            // Invoice items table
            _buildItemsTable(
                invoice, headerStyle, contentStyle, highlightStyle),
            pw.SizedBox(height: 30),

            // Totals
            _buildTotals(invoice, headerStyle, contentStyle, highlightStyle),
            pw.SizedBox(height: 20),

            // Notes
            if (invoice.notes.isNotEmpty) ...[
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Notes:', style: headerStyle),
              pw.SizedBox(height: 5),
              pw.Text(invoice.notes, style: contentStyle),
            ],

            // Footer
            pw.SizedBox(height: 20),
            _buildFooter(company, smallStyle),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.number}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Build the header section with company info
  static pw.Widget _buildHeader(
      Company company, pw.TextStyle titleStyle, pw.TextStyle contentStyle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(company.name, style: titleStyle),
            if (company.address != null)
              pw.Text(company.address!, style: contentStyle),
            if (company.phone != null)
              pw.Text('Phone: ${company.phone}', style: contentStyle),
            if (company.email != null)
              pw.Text('Email: ${company.email}', style: contentStyle),
            if (company.website != null)
              pw.Text('Web: ${company.website}', style: contentStyle),
          ],
        ),

        // Logo placeholder (would be replaced with actual logo if available)
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          alignment: pw.Alignment.center,
          child: company.logoUrl != null
              ? pw.Placeholder() // Would be replaced with actual logo
              : pw.Text('LOGO', style: contentStyle),
        ),
      ],
    );
  }

  /// Build invoice information section
  static pw.Widget _buildInvoiceInfo(
      Invoice invoice, pw.TextStyle headerStyle, pw.TextStyle contentStyle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice Number:', style: headerStyle),
              pw.SizedBox(height: 5),
              pw.Text(invoice.number, style: contentStyle),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Issue Date:', style: headerStyle),
              pw.SizedBox(height: 5),
              pw.Text(
                  '${invoice.issueDate.day}/${invoice.issueDate.month}/${invoice.issueDate.year}',
                  style: contentStyle),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Due Date:', style: headerStyle),
              pw.SizedBox(height: 5),
              pw.Text(
                  '${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                  style: contentStyle),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Status:', style: headerStyle),
              pw.SizedBox(height: 5),
              pw.Text(invoice.status.toString().split('.').last.toUpperCase(),
                  style: contentStyle),
            ],
          ),
        ],
      ),
    );
  }

  /// Build client information section
  static pw.Widget _buildClientInfo(
      Client client, pw.TextStyle headerStyle, pw.TextStyle contentStyle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Bill To:', style: headerStyle),
        pw.SizedBox(height: 10),
        pw.Text(client.name, style: contentStyle),
        if (client.address != null)
          pw.Text(client.address!, style: contentStyle),
        pw.Text('Email: ${client.email}', style: contentStyle),
        if (client.phone != null)
          pw.Text('Phone: ${client.phone}', style: contentStyle),
        if (client.taxNumber != null)
          pw.Text('Tax Number: ${client.taxNumber}', style: contentStyle),
      ],
    );
  }

  /// Build invoice items table
  static pw.Widget _buildItemsTable(Invoice invoice, pw.TextStyle headerStyle,
      pw.TextStyle contentStyle, pw.TextStyle highlightStyle) {
    final headers = [
      'Description',
      'Quantity',
      'Unit Price',
      'Tax Rate',
      'Amount'
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Table header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers
              .map((header) => pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(header,
                        style: headerStyle, textAlign: pw.TextAlign.center),
                  ))
              .toList(),
        ),

        // Table rows for each invoice item
        ...invoice.items.map((item) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(item.description, style: contentStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(item.quantity.toString(),
                      style: contentStyle, textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('\$${item.unitPrice.toStringAsFixed(2)}',
                      style: contentStyle, textAlign: pw.TextAlign.right),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${item.taxRate.toStringAsFixed(1)}%',
                      style: contentStyle, textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('\$${item.total.toStringAsFixed(2)}',
                      style: contentStyle, textAlign: pw.TextAlign.right),
                ),
              ],
            )),
      ],
    );
  }

  /// Build totals section
  static pw.Widget _buildTotals(Invoice invoice, pw.TextStyle headerStyle,
      pw.TextStyle contentStyle, pw.TextStyle highlightStyle) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 150,
                child: pw.Text('Subtotal:',
                    style: contentStyle, textAlign: pw.TextAlign.right),
              ),
              pw.Container(
                width: 100,
                child: pw.Text('\$${invoice.subtotal.toStringAsFixed(2)}',
                    style: contentStyle, textAlign: pw.TextAlign.right),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 150,
                child: pw.Text('Tax:',
                    style: contentStyle, textAlign: pw.TextAlign.right),
              ),
              pw.Container(
                width: 100,
                child: pw.Text('\$${invoice.taxAmount.toStringAsFixed(2)}',
                    style: contentStyle, textAlign: pw.TextAlign.right),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 150,
                child: pw.Text('Total:',
                    style: highlightStyle, textAlign: pw.TextAlign.right),
              ),
              pw.Container(
                width: 100,
                child: pw.Text('\$${invoice.total.toStringAsFixed(2)}',
                    style: highlightStyle, textAlign: pw.TextAlign.right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build footer with payment information
  static pw.Widget _buildFooter(Company company, pw.TextStyle style) {
    final settings = company.settings;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 5),
        pw.Text('Payment Information:', style: style),
        if (settings.bankName != null)
          pw.Text('Bank: ${settings.bankName}', style: style),
        if (settings.bankAccountNumber != null)
          pw.Text('Account Number: ${settings.bankAccountNumber}',
              style: style),
        if (settings.bankRoutingNumber != null)
          pw.Text('Routing Number: ${settings.bankRoutingNumber}',
              style: style),
        if (settings.bankSwiftCode != null)
          pw.Text('SWIFT: ${settings.bankSwiftCode}', style: style),
        if (settings.bankIban != null)
          pw.Text('IBAN: ${settings.bankIban}', style: style),
        pw.SizedBox(height: 10),
        pw.Text('Payment Terms: ${settings.paymentTerms} days', style: style),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text('Thank you for your business!', style: style),
        ),
      ],
    );
  }

  /// Print the invoice directly
  static Future<void> printInvoice({
    required Invoice invoice,
    required Client client,
    required Company company,
  }) async {
    final pdf = await generateInvoice(
      invoice: invoice,
      client: client,
      company: company,
    );

    await Printing.layoutPdf(
      onLayout: (_) => File(pdf).readAsBytes(),
    );
  }

  /// Share the invoice as a PDF
  static Future<void> shareInvoice({
    required Invoice invoice,
    required Client client,
    required Company company,
  }) async {
    final pdfPath = await generateInvoice(
      invoice: invoice,
      client: client,
      company: company,
    );

    await Printing.sharePdf(
      bytes: File(pdfPath).readAsBytesSync(),
      filename: 'invoice_${invoice.number}.pdf',
    );
  }
}
