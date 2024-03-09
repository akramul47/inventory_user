import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Show 10 shimmering cards
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Shimmer.fromColors(
              baseColor: Colors.grey,
              highlightColor: Colors.white,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
              ),
            ),
            title: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.white,
              child: Container(
                color: Colors.grey[300],
                height: 16,
                width: 100,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 8,
                ), // Add spacing here
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.white,
                  child: Container(
                    color: Colors.grey[300],
                    height: 12,
                    width: 50,
                  ),
                ),
                const SizedBox(height: 4),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.white,
                  child: Container(
                    color: Colors.grey[300],
                    height: 12,
                    width: 150,
                  ),
                ),
              ],
            ),
            trailing: Shimmer.fromColors(
              baseColor: Colors.grey,
              highlightColor: Colors.white,
              child: Icon(Icons.star),
            ),
          ),
        );
      },
    );
  }
}
