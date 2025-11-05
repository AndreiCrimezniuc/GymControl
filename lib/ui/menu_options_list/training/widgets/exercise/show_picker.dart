import "package:flutter/cupertino.dart";

void showPicker({
  required BuildContext context,
  required String title,
  required List<Widget> options,
  required int initialIndex,
  required Function(int) onSelected,
}) {
  showCupertinoModalPopup(
    context: context,
    builder: (_) => Container(
      height: 250,
      color: CupertinoColors.systemGrey6,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CupertinoColors.systemGrey5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text("Done"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 36.0,
              scrollController: FixedExtentScrollController(
                initialItem: initialIndex,
              ),
              onSelectedItemChanged: onSelected,
              children: options,
            ),
          ),
        ],
      ),
    ),
  );
}
