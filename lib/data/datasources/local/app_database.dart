import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('guiss_gestion.db');
    return _database!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    // PRODUITS
    await db.execute('''
      CREATE TABLE produits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,

        prix_achat_total REAL NOT NULL,
        prix_vente_unitaire REAL NOT NULL,

        unite_achat TEXT NOT NULL,
        unite_vente TEXT NOT NULL,

        quantite_par_unite REAL NOT NULL,

        stock REAL NOT NULL,

        fournisseur TEXT,
        telephone_fournisseur TEXT,
        categorie TEXT,
        description TEXT,

        date_creation TEXT NOT NULL
      )
    ''');

    // VENTES
    await db.execute('''
      CREATE TABLE ventes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produit_id INTEGER NOT NULL,
        nom_produit TEXT NOT NULL,
        quantite REAL NOT NULL,
        prix_achat_unitaire REAL NOT NULL,
        prix_vente_prevu REAL NOT NULL,
        prix_vendu_unitaire REAL NOT NULL,
        total REAL NOT NULL,
        benefice_reel REAL NOT NULL,
        type_vente TEXT NOT NULL, 
        client_nom TEXT,
        date_vente TEXT NOT NULL,
        FOREIGN KEY (produit_id) REFERENCES produits(id) ON DELETE CASCADE
      )
    ''');

    // CREDITS
    await db.execute('''
      CREATE TABLE credits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_nom TEXT NOT NULL,
        telephone_client TEXT,
        montant_total REAL NOT NULL,
        montant_paye REAL NOT NULL DEFAULT 0,
        reste REAL NOT NULL,
        statut TEXT NOT NULL,
        note TEXT,
        date_credit TEXT NOT NULL
      )
    ''');

    // PAIEMENTS CREDIT
    await db.execute('''
      CREATE TABLE paiements_credit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        credit_id INTEGER NOT NULL,
        montant REAL NOT NULL,
        date_paiement TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (credit_id) REFERENCES credits(id) ON DELETE CASCADE
      )
    ''');

    // PARAMETRES BOUTIQUE
    await db.execute('''
      CREATE TABLE parametres_boutique (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_boutique TEXT,
        proprietaire TEXT,
        telephone TEXT,
        adresse TEXT,
        devise TEXT DEFAULT 'FCFA',
        date_creation TEXT NOT NULL
      )
    ''');

    // LICENCES / ESSAI 7 JOURS
    await db.execute('''
      CREATE TABLE licences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_installation TEXT NOT NULL,
        date_expiration TEXT NOT NULL,
        est_active INTEGER NOT NULL DEFAULT 1,
        code_activation TEXT,
        type_abonnement TEXT DEFAULT 'essai'
      )
    ''');
  }
}