import 'package:flutter/material.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:shimmer/shimmer.dart';

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Show 10 shimmering cards
      itemBuilder: (context, index) {
        return Card(
          color: Colors.grey[200],
          elevation: 0,
          margin: const EdgeInsets.all(5.0),
          child: ListTile(
            leading: Shimmer.fromColors(
              baseColor: Pallete.primaryRed.withOpacity(0.7),
              highlightColor: Colors.white,
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
              ),
            ),
            title: Shimmer.fromColors(
              baseColor: Pallete.primaryRed.withOpacity(0.7),
              highlightColor: Colors.white,
              child: Container(
                color: Colors.grey[300],
                height: 14,
                width: 100,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const SizedBox(
                //   height: 4,
                // ), // Add spacing here
                // Shimmer.fromColors(
                //   baseColor: Colors.grey[300]!,
                //   highlightColor: Colors.white,
                //   child: Container(
                //     color: Colors.grey[300],
                //     height: 12,
                //     width: 50,
                //   ),
                // ),
                const SizedBox(height: 5),
                Shimmer.fromColors(
                  baseColor: Pallete.primaryRed.withOpacity(0.7),
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
              baseColor: Pallete.primaryRed.withOpacity(0.7),
              highlightColor: Colors.white,
              child: const Icon(Icons.star),
            ),
          ),
        );
      },
    );
  }
}
