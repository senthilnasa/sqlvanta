import 'package:equatable/equatable.dart';

class TableNode extends Equatable {
  final String name;
  final String type; // 'BASE TABLE' | 'VIEW'
  final int estimatedRows;

  const TableNode({
    required this.name,
    required this.type,
    this.estimatedRows = 0,
  });

  bool get isView => type == 'VIEW';

  @override
  List<Object?> get props => [name, type];
}
