class MenuModel {
  final String id;
  final String nama;
  final String deskripsi;
  final int harga;
  final String gambarUrl; // ← Ubah jadi gambarUrl (huruf u kecil)
  final String kategori; 
  final double rating;

  MenuModel({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.gambarUrl, // ← Ubah juga di sini
    required this.kategori,
    this.rating = 0.0,
  });

  factory MenuModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MenuModel(
      id: documentId,
      nama: data['name'] ?? 'Tanpa Nama',
      deskripsi: data['description'] ?? '-',
      harga: (data['price'] ?? 0).toInt(),
      gambarUrl: data['image_url'] ?? '', // ← Ubah juga di sini
      kategori: data['category'] ?? 'Lainnya',
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': nama,
      'description': deskripsi,
      'price': harga,
      'image_url': gambarUrl, // ← Ubah juga di sini
      'category': kategori,
      'rating': rating,
    };
  }
}