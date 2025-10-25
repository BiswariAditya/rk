import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  FirebaseService._();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection names
  static const String INVOICES = 'invoices';
  static const String CUSTOMERS = 'customers';
  static const String PURCHASE_BILLS = 'purchase_bills';
  static const String SUPPLIERS = 'suppliers';


  // ============= INVOICE OPERATIONS =============

  /// Save invoice to Firestore
  Future<String?> saveInvoice(Map<String, dynamic> invoiceData) async {
    try {
      // Add timestamps
      invoiceData['createdAt'] = FieldValue.serverTimestamp();
      invoiceData['updatedAt'] = FieldValue.serverTimestamp();

      // Add lowercase customer name for search
      if (invoiceData['customerName'] != null) {
        invoiceData['customerNameLower'] =
            invoiceData['customerName'].toString().toLowerCase();
      }

      debugPrint('📝 Attempting to save invoice to Firestore...');
      debugPrint('Invoice data: ${invoiceData.toString()}');

      final docRef = await _firestore.collection(INVOICES).add(invoiceData);

      debugPrint('✅ Invoice saved successfully with ID: ${docRef.id}');
      return docRef.id;

    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase Error saving invoice:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Plugin: ${e.plugin}');
      return null;

    } catch (e, stackTrace) {
      debugPrint('❌ Unknown Error saving invoice: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get all invoices
  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    try {
      final snapshot = await _firestore
          .collection(INVOICES)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching invoices: $e');
      return [];
    }
  }

  /// Get invoices with pagination
  Future<List<Map<String, dynamic>>> getInvoicesPaginated({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(INVOICES)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching paginated invoices: $e');
      return [];
    }
  }

  /// Search invoices by customer name or invoice number
  Future<List<Map<String, dynamic>>> searchInvoices(String searchTerm) async {
    try {
      final searchTermLower = searchTerm.toLowerCase();

      // Search by invoice number
      final invoiceNumQuery = await _firestore
          .collection(INVOICES)
          .where('invoiceNumber', isGreaterThanOrEqualTo: searchTerm)
          .where('invoiceNumber', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      // Search by customer name
      final customerQuery = await _firestore
          .collection(INVOICES)
          .where('customerNameLower', isGreaterThanOrEqualTo: searchTermLower)
          .where('customerNameLower', isLessThanOrEqualTo: '$searchTermLower\uf8ff')
          .get();

      // Combine results and remove duplicates
      final results = <String, Map<String, dynamic>>{};

      for (var doc in invoiceNumQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results[doc.id] = data;
      }

      for (var doc in customerQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results[doc.id] = data;
      }

      return results.values.toList();
    } catch (e) {
      print('Error searching invoices: $e');
      return [];
    }
  }

  /// Get invoice by ID
  Future<Map<String, dynamic>?> getInvoiceById(String id) async {
    try {
      final doc = await _firestore.collection(INVOICES).doc(id).get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching invoice: $e');
      return null;
    }
  }

  /// Update invoice
  Future<bool> updateInvoice(String id, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(INVOICES).doc(id).update(updateData);
      print('Invoice updated successfully');
      return true;
    } catch (e) {
      print('Error updating invoice: $e');
      return false;
    }
  }

  /// Delete invoice
  Future<bool> deleteInvoice(String id) async {
    try {
      await _firestore.collection(INVOICES).doc(id).delete();
      print('Invoice deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting invoice: $e');
      return false;
    }
  }

  /// Stream invoices (real-time updates)
  Stream<List<Map<String, dynamic>>> streamInvoices() {
    return _firestore
        .collection(INVOICES)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  // ============= CUSTOMER OPERATIONS =============

  /// Save customer
  Future<String?> saveCustomer(Map<String, dynamic> customerData) async {
    try {
      // Add lowercase name for case-insensitive search
      customerData['nameLower'] = customerData['name']?.toString().toLowerCase();
      customerData['gstNumber'] = customerData['gstNumber']?.toString().toUpperCase();
      customerData['phoneNumber'] = customerData['phoneNumber']?.toString().toUpperCase();
      customerData['address'] = customerData['address']?.toString().toUpperCase();
      customerData['createdAt'] = FieldValue.serverTimestamp();
      customerData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(CUSTOMERS).add(customerData);
      print('Customer saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving customer: $e');
      return null;
    }
  }

  /// Get all customers
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final snapshot = await _firestore
          .collection(CUSTOMERS)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  /// Search customers by name, GST, or phone
  Future<List<Map<String, dynamic>>> searchCustomers(String searchTerm) async {
    try {
      final searchTermLower = searchTerm.toLowerCase();

      // Search by name (case-insensitive)
      final nameQuery = await _firestore
          .collection(CUSTOMERS)
          .where('nameLower', isGreaterThanOrEqualTo: searchTermLower)
          .where('nameLower', isLessThanOrEqualTo: '$searchTermLower\uf8ff')
          .get();

      // Search by GST
      final gstQuery = await _firestore
          .collection(CUSTOMERS)
          .where('gstNumber', isGreaterThanOrEqualTo: searchTerm.toUpperCase())
          .where('gstNumber', isLessThanOrEqualTo: '${searchTerm.toUpperCase()}\uf8ff')
          .get();

      // Search by phone
      final phoneQuery = await _firestore
          .collection(CUSTOMERS)
          .where('phoneNumber', isGreaterThanOrEqualTo: searchTerm)
          .where('phoneNumber', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      // Combine results
      final results = <String, Map<String, dynamic>>{};

      for (var doc in nameQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results[doc.id] = data;
      }

      for (var doc in gstQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results[doc.id] = data;
      }

      for (var doc in phoneQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results[doc.id] = data;
      }

      return results.values.toList();
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  /// Get customer by ID
  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    try {
      final doc = await _firestore.collection(CUSTOMERS).doc(id).get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching customer: $e');
      return null;
    }
  }

  /// Update customer
  Future<bool> updateCustomer(String id, Map<String, dynamic> updateData) async {
    try {
      updateData['nameLower'] = updateData['name']?.toString().toLowerCase();
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(CUSTOMERS).doc(id).update(updateData);
      print('Customer updated successfully');
      return true;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  /// Delete customer
  Future<bool> deleteCustomer(String id) async {
    try {
      await _firestore.collection(CUSTOMERS).doc(id).delete();
      print('Customer deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting customer: $e');
      return false;
    }
  }

  /// Stream customers (real-time updates)
  Stream<List<Map<String, dynamic>>> streamCustomers() {
    return _firestore
        .collection(CUSTOMERS)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  // ============= PURCHASE BILL OPERATIONS =============

  /// Save purchase bill
  Future<String?> savePurchaseBill(Map<String, dynamic> billData) async {
    try {
      billData['supplierNameLower'] = billData['supplierName']?.toString().toLowerCase();
      billData['createdAt'] = FieldValue.serverTimestamp();
      billData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(PURCHASE_BILLS).add(billData);
      print('Purchase bill saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving purchase bill: $e');
      return null;
    }
  }

  /// Get all purchase bills
  Future<List<Map<String, dynamic>>> getAllPurchaseBills() async {
    try {
      final snapshot = await _firestore
          .collection(PURCHASE_BILLS)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching purchase bills: $e');
      return [];
    }
  }

  /// Search purchase bills
  Future<List<Map<String, dynamic>>> searchPurchaseBills(String searchTerm) async {
    try {
      final searchTermLower = searchTerm.toLowerCase();

      final billNumQuery = await _firestore
          .collection(PURCHASE_BILLS)
          .where('billNumber', isGreaterThanOrEqualTo: searchTerm)
          .where('billNumber', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      final supplierQuery = await _firestore
          .collection(PURCHASE_BILLS)
          .where('supplierNameLower', isGreaterThanOrEqualTo: searchTermLower)
          .where('supplierNameLower', isLessThanOrEqualTo: '$searchTermLower\uf8ff')
          .get();

      final results = <String, Map<String, dynamic>>{};

      for (var doc in billNumQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results[doc.id] = data;
      }

      for (var doc in supplierQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        results[doc.id] = data;
      }

      return results.values.toList();
    } catch (e) {
      print('Error searching purchase bills: $e');
      return [];
    }
  }

  /// Update purchase bill
  Future<bool> updatePurchaseBill(String id, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(PURCHASE_BILLS).doc(id).update(updateData);
      print('Purchase bill updated successfully');
      return true;
    } catch (e) {
      print('Error updating purchase bill: $e');
      return false;
    }
  }

  /// Delete purchase bill
  Future<bool> deletePurchaseBill(String id) async {
    try {
      await _firestore.collection(PURCHASE_BILLS).doc(id).delete();
      print('Purchase bill deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting purchase bill: $e');
      return false;
    }
  }

  /// Stream purchase bills (real-time updates)
  Stream<List<Map<String, dynamic>>> streamPurchaseBills() {
    return _firestore
        .collection(PURCHASE_BILLS)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  // ============= SUPPLIER OPERATIONS =============

  /// Save supplier
  Future<String?> saveSupplier(Map<String, dynamic> supplierData) async {
    try {
      supplierData['nameLower'] = supplierData['name']?.toString().toLowerCase();
      supplierData['createdAt'] = FieldValue.serverTimestamp();
      supplierData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(SUPPLIERS).add(supplierData);
      print('Supplier saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving supplier: $e');
      return null;
    }
  }

  /// Get all suppliers
  Future<List<Map<String, dynamic>>> getAllSuppliers() async {
    try {
      final snapshot = await _firestore
          .collection(SUPPLIERS)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching suppliers: $e');
      return [];
    }
  }

  /// Search suppliers
  Future<List<Map<String, dynamic>>> searchSuppliers(String searchTerm) async {
    try {
      final searchTermLower = searchTerm.toLowerCase();

      final query = await _firestore
          .collection(SUPPLIERS)
          .where('nameLower', isGreaterThanOrEqualTo: searchTermLower)
          .where('nameLower', isLessThanOrEqualTo: '$searchTermLower\uf8ff')
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error searching suppliers: $e');
      return [];
    }
  }

  // ============= ANALYTICS =============

  /// Get total sales for date range
  Future<double> getTotalSales({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection(INVOICES);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      double total = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['totalAmount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Error calculating total sales: $e');
      return 0;
    }
  }

  /// Get total purchases for date range
  Future<double> getTotalPurchases({DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection(PURCHASE_BILLS);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      double total = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['totalAmount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Error calculating total purchases: $e');
      return 0;
    }
  }

  /// Get invoice count
  Future<int?> getInvoiceCount() async {
    try {
      final snapshot = await _firestore.collection(INVOICES).count().get();
      return snapshot.count;
    } catch (e) {
      print('Error getting invoice count: $e');
      return 0;
    }
  }

  /// Get customer count
  Future<int?> getCustomerCount() async {
    try {
      final snapshot = await _firestore.collection(CUSTOMERS).count().get();
      return snapshot.count;
    } catch (e) {
      print('Error getting customer count: $e');
      return 0;
    }
  }

  /// Get recent invoices (last N days)
  Future<List<Map<String, dynamic>>> getRecentInvoices({int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection(INVOICES)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching recent invoices: $e');
      return [];
    }
  }

  // ============= STORAGE OPERATIONS =============

  /// Upload PDF to Firebase Storage
  Future<String?> uploadPDF(File file, String fileName) async {
    try {
      final ref = _storage.ref().child('invoices/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('PDF uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading PDF: $e');
      return null;
    }
  }

  /// Delete PDF from Firebase Storage
  Future<bool> deletePDF(String fileName) async {
    try {
      final ref = _storage.ref().child('invoices/$fileName');
      await ref.delete();
      print('PDF deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting PDF: $e');
      return false;
    }
  }

  /// Get PDF download URL
  Future<String?> getPDFUrl(String fileName) async {
    try {
      final ref = _storage.ref().child('invoices/$fileName');
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error getting PDF URL: $e');
      return null;
    }
  }

  // ============= BATCH OPERATIONS =============

  /// Batch write multiple documents
  Future<bool> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();

      for (var operation in operations) {
        final collection = operation['collection'] as String;
        final data = operation['data'] as Map<String, dynamic>;
        final type = operation['type'] as String; // 'add', 'update', 'delete'

        if (type == 'add') {
          final docRef = _firestore.collection(collection).doc();
          batch.set(docRef, data);
        } else if (type == 'update') {
          final docId = operation['docId'] as String;
          final docRef = _firestore.collection(collection).doc(docId);
          batch.update(docRef, data);
        } else if (type == 'delete') {
          final docId = operation['docId'] as String;
          final docRef = _firestore.collection(collection).doc(docId);
          batch.delete(docRef);
        }
      }

      await batch.commit();
      print('Batch write successful');
      return true;
    } catch (e) {
      print('Error in batch write: $e');
      return false;
    }
  }

  // ============= OFFLINE PERSISTENCE =============

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      await _firestore.enableNetwork();
      print('Offline persistence enabled');
    } catch (e) {
      print('Error enabling offline persistence: $e');
    }
  }

  /// Disable network (for testing offline mode)
  Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
      print('Network disabled');
    } catch (e) {
      print('Error disabling network: $e');
    }
  }

  /// Enable network
  Future<void> enableNetwork() async {
    try {
      await _firestore.enableNetwork();
      print('Network enabled');
    } catch (e) {
      print('Error enabling network: $e');
    }
  }

  // ============= HELPER METHODS =============

  /// Convert Firestore Timestamp to DateTime
  DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  /// Format date for display
  String formatDate(dynamic timestamp) {
    final date = timestampToDateTime(timestamp);
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Check if document exists
  Future<bool> documentExists(String collection, String docId) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking document existence: $e');
      return false;
    }
  }

  /// Get collection size
  Future<int?> getCollectionSize(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).count().get();
      return snapshot.count;
    } catch (e) {
      print('Error getting collection size: $e');
      return 0;
    }
  }
}