import 'services.dart';

// Data models for Bank Account API
class BankAccount {
  final int id;
  final String transactionType;
  final String accHolderName;
  final String accNo;
  final String accType;
  final String opBalance;
  final String note;
  final String status;

  BankAccount({
    required this.id,
    required this.transactionType,
    required this.accHolderName,
    required this.accNo,
    required this.accType,
    required this.opBalance,
    required this.note,
    required this.status,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] ?? 0,
      transactionType: json['transaction_type']?.toString() ?? '',
      accHolderName: json['acc_holder_name']?.toString() ?? '',
      accNo: json['acc_no']?.toString() ?? '',
      accType: json['acc_type']?.toString() ?? '',
      opBalance: json['op_balance']?.toString() ?? '0.00',
      note: json['note']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_type': transactionType,
      'acc_holder_name': accHolderName,
      'acc_no': accNo,
      'acc_type': accType,
      'op_balance': opBalance,
      'note': note,
      'status': status,
    };
  }
}

class BankAccountsResponse {
  final List<BankAccount> data;

  BankAccountsResponse({required this.data});

  factory BankAccountsResponse.fromJson(Map<String, dynamic> json) {
    return BankAccountsResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((account) => BankAccount.fromJson(account))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data.map((account) => account.toJson()).toList()};
  }
}

class CreateBankAccountResponse {
  final bool status;
  final String message;
  final BankAccount? data;

  CreateBankAccountResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CreateBankAccountResponse.fromJson(Map<String, dynamic> json) {
    return CreateBankAccountResponse(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? BankAccount.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data?.toJson()};
  }
}

class SingleBankAccountResponse {
  final bool status;
  final String message;
  final BankAccount data;

  SingleBankAccountResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SingleBankAccountResponse.fromJson(Map<String, dynamic> json) {
    return SingleBankAccountResponse(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? '',
      data: BankAccount.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data.toJson()};
  }
}

class DeleteBankAccountResponse {
  final bool status;
  final String message;

  DeleteBankAccountResponse({required this.status, required this.message});

  factory DeleteBankAccountResponse.fromJson(Map<String, dynamic> json) {
    return DeleteBankAccountResponse(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message};
  }
}

class BankAccountService {
  // Get all bank accounts
  static Future<BankAccountsResponse> getBankAccounts() async {
    try {
      final response = await ApiService.get('/banks');

      return BankAccountsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load bank accounts: $e');
    }
  }

  // Create a new bank account
  static Future<CreateBankAccountResponse> createBankAccount(
    Map<String, dynamic> bankAccountData,
  ) async {
    try {
      final response = await ApiService.post('/banks', bankAccountData);

      // For create API, assume success and parse the response
      final createResponse = CreateBankAccountResponse(
        status: true,
        message: 'Bank account created successfully',
        data: response['data'] != null
            ? BankAccount.fromJson(response['data'])
            : null,
      );

      return createResponse;
    } catch (e) {
      throw Exception('Failed to create bank account: $e');
    }
  }

  // Get a specific bank account by ID
  static Future<SingleBankAccountResponse> getBankAccountById(
    int accountId,
  ) async {
    try {
      final response = await ApiService.get('/banks/$accountId');

      // For single bank account API, the response structure is different
      // It returns data directly without status/message wrapper
      final singleAccountResponse = SingleBankAccountResponse(
        status: true,
        message: 'Bank account loaded successfully',
        data: BankAccount.fromJson(response['data'] ?? response),
      );

      return singleAccountResponse;
    } catch (e) {
      throw Exception('Failed to load bank account: $e');
    }
  }

  // Update a bank account
  static Future<SingleBankAccountResponse> updateBankAccount(
    int accountId,
    Map<String, dynamic> bankAccountData,
  ) async {
    try {
      final response = await ApiService.put(
        '/banks/$accountId',
        bankAccountData,
      );

      // For update API, the response structure is different
      // It returns data directly without status/message wrapper
      final singleAccountResponse = SingleBankAccountResponse(
        status: true,
        message: 'Bank account updated successfully',
        data: BankAccount.fromJson(response['data'] ?? response),
      );

      return singleAccountResponse;
    } catch (e) {
      throw Exception('Failed to update bank account: $e');
    }
  }

  // Delete a bank account
  static Future<DeleteBankAccountResponse> deleteBankAccount(
    int accountId,
  ) async {
    try {
      final response = await ApiService.delete('/banks/$accountId');

      // For delete API, assume success based on the response
      final deleteResponse = DeleteBankAccountResponse(
        status: true,
        message: response['message']?.toString() ?? 'Bank deleted successfully',
      );

      return deleteResponse;
    } catch (e) {
      throw Exception('Failed to delete bank account: $e');
    }
  }
}
