import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audira_receipt/app/routes.dart';
import 'package:audira_receipt/core/constants/app_colors.dart';
import 'package:audira_receipt/core/services/bluetooth_service.dart';

class PrinterStatusWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const PrinterStatusWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothService>(
      builder: (context, btService, _) {
        final isConnected = btService.isConnected;
        final isConnecting = btService.connectionState == BluetoothConnState.connecting;
        final printerName = btService.connectedPrinter?.name ?? 'Tidak ada printer terhubung';
        final paperSize = btService.connectedPrinter?.paperSize ?? '58mm';

        Color statusColor;
        Color statusBg;
        String statusLabel;
        IconData statusIcon;

        if (isConnecting) {
          statusColor = AppColors.warning;
          statusBg = AppColors.warningLight;
          statusLabel = 'Menyambungkan...';
          statusIcon = Icons.bluetooth_searching;
        } else if (isConnected) {
          statusColor = AppColors.success;
          statusBg = AppColors.successLight;
          statusLabel = 'Printer Terhubung';
          statusIcon = Icons.check_circle;
        } else {
          statusColor = AppColors.danger;
          statusBg = AppColors.dangerLight;
          statusLabel = 'Printer Tidak Terhubung';
          statusIcon = Icons.cancel;
        }

        return InkWell(
          onTap: onTap ?? () => Navigator.pushNamed(context, AppRoutes.printerScan),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected ? AppColors.success.withOpacity(0.3) : AppColors.border,
                width: isConnected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon indicator
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Text status & printer name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isConnected ? printerName : 'Ketuk untuk hubungkan printer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isConnected ? AppColors.text : AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isConnected) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Thermal ESC/POS • $paperSize',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow button
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
