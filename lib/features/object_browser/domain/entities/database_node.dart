import 'package:equatable/equatable.dart';

class DatabaseNode extends Equatable {
  final String name;
  const DatabaseNode(this.name);

  @override
  List<Object?> get props => [name];
}
