// lib/src/groups/groups.dart
import 'package:flutter/material.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  // Função auxiliar para criar um contêiner de grupo reutilizável
  Widget _buildGroupContainer({
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Divider(color: Colors.black54, height: 15, thickness: 1),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '- $item',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Grupos'),
        backgroundColor: Colors.teal, // Cor de fundo da AppBar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // --- Grupo 1 ---
          _buildGroupContainer(
            title: 'Grupo de Estudo Flutter',
            items: ['Membros: João, Maria, Pedro'],
            color: Colors.teal.shade50,
          ),
          const SizedBox(height: 20), // Espaçamento entre os grupos

          // --- Grupo 2 ---
          _buildGroupContainer(
            title: 'Time de Futebol',
            items: ['Membros: Lucas, Ana, Carlos'],
            color: Colors.teal.shade100,
          ),
          const SizedBox(height: 20),

          // --- Grupo 3 ---
          _buildGroupContainer(
            title: 'Clube do Livro',
            items: ['Membros: Sofia, Rafael, Camila'],
            color: Colors.teal.shade200,
          ),
          const SizedBox(height: 20),

          // Adicione mais grupos aqui
        ],
      ),
    );
  }
}