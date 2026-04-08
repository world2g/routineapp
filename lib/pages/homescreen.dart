import 'package:flutter/material.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: const [
          WatchConnectionCard(),
          SizedBox(height: 30),
          ScheduleSection(),
        ],
      ),
    );
  }
}

class WatchConnectionCard extends StatelessWidget {
  const WatchConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.watch, size: 50),

          const SizedBox(width: 20),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "M11 WATCH",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 5),

              Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 12),
                  SizedBox(width: 5),
                  Text("Connected"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SCHEDULE",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.arrow_back_ios, size: 16),
            Text("Today", style: TextStyle(fontSize: 18)),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),

        const SizedBox(height: 20),

        // ScheduleItem(
        //   time: "7:30 am",
        //   task: "Eat Breakfast",
        // ),

        // ScheduleItem(
        //   time: "8:00 am",
        //   task: "Music Class",
        // ),
      ],
    );
  }
}