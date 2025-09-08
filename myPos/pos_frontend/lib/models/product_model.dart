class ProductModel  {
  String imageProduct;
  String nameProduct;
  String category;
  String vendor;
  double price;
  int quantity;
  String imageUser;
  String createdBy;
  String status;

ProductModel({
    required this.imageProduct,
    required this.nameProduct,
    required this.category,
    required this.vendor,
    required this.price,
    required this.quantity,
    required this.imageUser,
    required this.createdBy,
    required this.status,
  });
}