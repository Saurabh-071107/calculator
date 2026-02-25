import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  final Function(String result) onItemTap;

  const HistoryPage({super.key, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          /// same gradient of home
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: isDark
                    ? [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF121212),
                ]
                    : [
                  Colors.lightBlueAccent,
                  Colors.white,
                ],
              ),
            ),
          ),
          /// CONTENT
          SafeArea(
            child: Column(
              children: [
                /// Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text("Calculation History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          var collection = FirebaseFirestore.instance.collection('history');
                          var snapshots = await collection.get();
                          for (var doc in snapshots.docs) {
                            await doc.reference.delete();
                          }
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                /// History List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('history').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No History Yet",
                            style: TextStyle(fontSize: 25,fontWeight: FontWeight.w500),
                          ),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index];
                          return Dismissible(
                            key: Key(data.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              FirebaseFirestore.instance
                                  .collection('history')
                                  .doc(data.id)
                                  .delete();
                            },
                            background: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                BorderRadius.circular(15),
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                              const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete,
                                  color: Colors.white),
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 6),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : Colors.white,
                                borderRadius:
                                BorderRadius.circular(15),
                                boxShadow: isDark
                                    ? []
                                    : [
                                  BoxShadow(
                                    color: Colors.grey
                                        .withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ListTile(
                                onTap: () {
                                  onItemTap(data['result']);
                                  Navigator.pop(context);
                                },
                                title: Text(
                                  data['expression'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  "= ${data['result']}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}