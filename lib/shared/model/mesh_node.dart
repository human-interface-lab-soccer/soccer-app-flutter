/// MeshNodeは、メッシュネットワーク内のノードを表現するクラスです。
/// ノードのUUID、プライマリユニキャストアドレス、名前、および設定状態を含みます。
/// このクラスは、メッシュネットワーク内のノードの管理と表現に使用され、
/// ノードの設定や識別などの操作を可能にします。
/// 
/// # Example:
/// ```dart
/// var node = MeshNode.fromMap({
///   'uuid': 'XXXX-XXXX',
///   'primaryUnicastAddress': 12345,
///   'name': 'My Node',
///   'isConfigured': true,
/// });
/// print(node); // MeshNode(uuid: XXXX-XXXX, primaryUnicastAddress: 12345, name: My Node, isConfigured: true)
/// ```
/// 
class MeshNode {
  final String uuid;
  final int primaryUnicastAddress;
  final String name;
  final bool isConfigured;

  MeshNode({
    required this.uuid,
    required this.primaryUnicastAddress,
    required this.name,
    required this.isConfigured,
  }) {
    if (primaryUnicastAddress < 1) {
      throw ArgumentError('Unicast addresses must be positive integers.');
    }
  }

  factory MeshNode.fromMap(final Map<String, dynamic> map) {
    return MeshNode(
      uuid: map['uuid'] as String? ?? 'Unknown UUID',
      primaryUnicastAddress: map['primaryUnicastAddress'] as int? ?? 1,
      name: map['name'] as String? ?? 'Unknown Node',
      isConfigured: map['isConfigured'] as bool? ?? false,
    );
  }

  MeshNode copyWith({
    String? uuid,
    int? primaryUnicastAddress,
    String? name,
    bool? isConfigured,
  }) {
    return MeshNode(
      uuid: uuid ?? this.uuid,
      primaryUnicastAddress: primaryUnicastAddress ?? this.primaryUnicastAddress,
      name: name ?? this.name,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}
