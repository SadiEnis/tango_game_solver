// Tango Bulmacası Çözümleyen Yapay Zeka Algoritması

// ** Not: main.dart.(js - .js.deps - .js.map) dosyaları web için gerekli olan dosyalardır.
// Bunlar Dart kodunun JavaScript'e derlenmiş hali. Bu dosyalar olmadan web uygulaması çalışmaz.
// Dart backend kodu, web uygulaması için gerekli olan JavaScript dosyalarına dönüştürülür.
import 'dart:html';
import 'dart:js' as js;

enum CellType { empty, dark, light }
enum ConstraintType { equal, diff }

class Cell {
  // Her hücre için tip ve kısıt türleri tanımlanıyor.
  // Hücre tipleri: empty (boş), dark (koyu), light (açık).
  // Kısıt türleri: equal (=), diff (x). Bunlar bazı hücreler arasında ilişki kurmak için kullanılıyor.
  // Örneğin, bir hücre dark ise yanındaki hücre de dark olmalı veya zıt renk olmalı gibi.
  
  CellType type;
  List<ConstraintType> rightConstraints;
  List<ConstraintType> bottomConstraints;
  
  Cell({
    this.type = CellType.empty,
    List<ConstraintType>? rightConstraints,
    List<ConstraintType>? bottomConstraints,
  }) : rightConstraints = rightConstraints ?? [],
       bottomConstraints = bottomConstraints ?? [];
       
  String toSymbol() {
    switch (type) {
      case CellType.empty:
        return '_';
      case CellType.dark:
        return 'D';
      case CellType.light:
        return 'L';
    }
  }
}

class TangoGame {
  // Tango oyunu için grid boyutu ve hücrelerin tutulduğu liste tanımlanıyor.

  late List<List<Cell>> grid;
  late int size;
  
  TangoGame(this.size) {
    grid = List.generate(size, (_) => 
        List.generate(size, (_) => Cell()));
  }
  
  // Copy grid state for web display
  List<List<Cell>> copyGrid() {
    List<List<Cell>> newGrid = List.generate(size, (_) => 
        List.generate(size, (_) => Cell()));
    
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        newGrid[i][j].type = grid[i][j].type;
        newGrid[i][j].rightConstraints = List.from(grid[i][j].rightConstraints);
        newGrid[i][j].bottomConstraints = List.from(grid[i][j].bottomConstraints);
      }
    }
    return newGrid;
  }
  
  void setupSampleConstraints() {
    // Örnek kısıtlar ve hücre tipleri ayarlanıyor. Bu, oyunun başlangıç durumunu belirliyor.
    // Bu örnek web ara yüzünde Örnek oyun istenildiğinde kullanılıyor. 

    if (size == 6) {
      grid[0][1].type = CellType.dark;
      grid[0][2].type = CellType.light;
      grid[0][3].type = CellType.light;
      grid[0][4].type = CellType.dark;

      grid[1][0].type = CellType.dark;
      grid[1][5].type = CellType.dark;

      grid[2][0].type = CellType.light;
      grid[2][5].type = CellType.dark;

      grid[3][0].type = CellType.light;
      grid[3][5].type = CellType.light;

      grid[4][0].type = CellType.dark;
      grid[4][5].type = CellType.light;

      grid[5][1].type = CellType.light;
      grid[5][2].type = CellType.dark;
      grid[5][3].type = CellType.dark;
      grid[5][4].type = CellType.light;

      grid[1][3].rightConstraints.add(ConstraintType.diff);
      grid[2][3].rightConstraints.add(ConstraintType.diff);
      grid[3][1].rightConstraints.add(ConstraintType.equal);
      grid[4][1].rightConstraints.add(ConstraintType.diff);

      grid[1][1].bottomConstraints.add(ConstraintType.equal);
      grid[1][2].bottomConstraints.add(ConstraintType.diff);
      grid[3][3].bottomConstraints.add(ConstraintType.diff);
      grid[3][4].bottomConstraints.add(ConstraintType.diff);
    }
  }
}

class TangoSolver {
  // TangoSolver sınıfı, TangoGame nesnesini alır ve çözümleme işlemlerini yapar.
  // Bu sınıf, kural tabanlı (rule-Based) ve geri izleme (backtracking) algoritmalarını kullanarak bulmacayı çözer.
  // Çözümleme işlemleri sırasında loglama yapar ve kullanıcıya bilgi verir.
  
  TangoGame game; 
  List<String> log = [];
  
  TangoSolver(this.game); // Bu sınıf tanımlarnırken oyun tahtası da girdi olarak verilir.
  
  void addLog(String message) {
    // Log mesajlarını ekrana yazdırır ve log listesini günceller.
    // Bu metod, çözümleme sürecinde kullanıcıya bilgi vermek için kullanılır.

    log.add(message);
    final logElement = querySelector('#log-output');
    if (logElement != null) {
      logElement.text = log.join('\n');
      logElement.scrollTop = logElement.scrollHeight;
    }
  }

  bool solve() {
    // Bu metod, Tango bulmacasını çözmek için kural tabanlı ve geri izleme algoritmaların kullanıldığı metoddur.
    log.clear();
    addLog('🎯 TANGO SOLVER BAŞLADI');
    addLog('Hibrit Algorithm: Rule-Based + Backtracking');
    addLog('═══════════════════════════════════════════\n');
    
    int totalCells = game.size * game.size;
    int filledCells = 0;
    int constraints = 0;
    
    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size; j++) {
        if (game.grid[i][j].type != CellType.empty) filledCells++;
        constraints += game.grid[i][j].rightConstraints.length;
        constraints += game.grid[i][j].bottomConstraints.length;
      }
    } 
    // Toplam hücre sayısı, dolu hücre sayısı ve kısıt sayısını hesapla.
    // Bu hesapların yapılmasının nedeni Algoritma log alanında kullanıcıya bilgi vermek. 36 kareden oluşuyor bir miktarı dolu diyelim ki ona göre yüzdelik ilerleme ortaya çıkıyor.
    
    addLog('📋 BAŞLANGIÇ DURUMU:');
    addLog('  • Grid boyutu: ${game.size}x${game.size} ($totalCells hücre)');
    addLog('  • Önceden dolu: $filledCells hücre');
    addLog('  • Boş hücre: ${totalCells - filledCells}');
    addLog('  • Toplam kısıt: $constraints adet\n');
    // Yukarıda tuttuğumuz verileri log alanına yazdırıyoruz.
    // Başlangıç durumu rapor ediliyor.
    
    addLog('🔧 AŞAMA 1: Rule-Based Algorithm');
    addLog('───────────────────────────────────────────');
    bool ruleBasedResult = solveWithRules(); // Kural tabanlı algoritma ile çözümleme başlatılıyor. Metod aşağıda tanımlı
    
    if (isComplete() && isValid()) {
      addLog('\n🎉 Rule-Based algoritma tek başına çözümü buldu!');
      addLog('───────────────────────────────────────────');
      return true;
    } // Eğer kural tabanlı algoritma ile çözüm bulunursa, true döner ve işlem sonlanır. Backtracking algoritması devreye girmez.
    
    addLog('\n🧩 AŞAMA 2: Backtracking Algorithm');
    addLog('───────────────────────────────────────────');
    addLog('Rule-based çözümün üzerine backtracking uygulanıyor...\n');
    
    bool backtrackResult = solveWithBacktracking(); // Geri izleme algoritması ile çözümleme başlatılıyor. Metod aşağıda tanımlı.
    
    bool complete = isComplete();
    bool valid = isValid();
    
    addLog('\n📊 FINAL SONUÇ:');
    addLog('═══════════════════════════════════════════');
    addLog('  ${complete ? "✅" : "❌"} Çözüm Tamamlandı: ${complete ? "EVET" : "HAYIR"}');
    addLog('  ${valid ? "✅" : "❌"} Çözüm Geçerli: ${valid ? "EVET" : "HAYIR"}');
    // Çözümün tamamlanıp tamamlanmadığı ve geçerli olup olmadığı kontrol ediliyor.
    
    if (complete && valid) {
      String method = ruleBasedResult && backtrackResult ? 'Rule-Based + Backtracking' : 'Sadece Rule-Based';
      addLog('  🎯 Kullanılan Yöntem: $method');
      addLog('  🏆 PUZZLE BAŞARIYLA ÇÖZÜLDÜ!');
    } else {
      addLog('  ❌ Çözüm bulunamadı veya geçersiz');
    }
    // Sonuç hakkında gerekli bilgiler veriliyor.
    
    return complete && valid;
  }


  bool solveWithRules() {
    // Kural Tabanlı Algoritma eğer şu ise bunu yap gibi kuralları uygular.
    // Oyun bir puzzle olduğu için çok sayıda kuralı var. Algoritma bu kuralları uygularak boş hücreleri doldurmaya çalışır.

    addLog('📋 Kural tabanlı çözüm başlatılıyor...');
    addLog('🔍 Başlangıç grid durumu kontrol ediliyor...');
    
    int emptyCells = 0;
    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size; j++) {
        if (game.grid[i][j].type == CellType.empty) emptyCells++;
      }
    }
    addLog('📊 Toplam ${game.size * game.size} hücre, $emptyCells tanesi boş');
    
    bool changed = true;
    int iterations = 0;
    
    while (changed && iterations < 50) { // Maks çalışacağı iterasyon sayısına bir sınır koydum. Sonsuz döngüye girmiyor. False dönüyor ve çözüm bulunamıyor.
      changed = false;
      iterations++;
      
      addLog('🔄 İterasyon $iterations:');

      // Her bir oyun kuralı için ayrı ayrı metod tanımlandı.
      // Bu metodlar, kural tabanlı algoritmanın temelini oluşturur. Her biri belirli bir kuralı uygular ve değişiklik yapılıp yapılmadığını kontrol eder.
      // Oyunun geçerli durumu için ilgili kural uygulanır.
      
      if (applyConstraintRules()) {
        changed = true;
        addLog('  ✅ Kısıt kuralları uygulandı');
      } // = ve x kuralları uygulanıyor.
      
      if (applyAdjacentRules()) {
        changed = true;
        addLog('  ✅ Yan yana kuralları uygulandı');
      } // Yan yana kurallar uygulanıyor. 2 tane yan yana dark veya light hücre varsa 3. boş hücreye zıt renk atanıyor oyun kuralları gereği.
      
      if (applyBalanceRules()) {
        changed = true;
        addLog('  ✅ Denge kuralları uygulandı');
      } // Satır ve sütun dengesi kontrol ediliyor. Her satır veya sütunda aynı sayıda dark ve light hücre olmalı.
      
      if (applyForcedMoves()) {
        changed = true;
        addLog('  ✅ Zorunlu hamleler uygulandı');
      } // Zorunlu hamle şudur: Eğer bir hücre dark veya light ise ve yanındaki 2 hücre de aynı renkte ise, ortadaki boş hücreye zıt renk atanıyor.
      
      int currentEmpty = 0;
      for (int i = 0; i < game.size; i++) {
        for (int j = 0; j < game.size; j++) {
          if (game.grid[i][j].type == CellType.empty) currentEmpty++;
        }
      } // Her iterasyondan sonra boş hücre sayısı güncelleniyor ve sonraki iterasyonda bu sayıya göre işlem yapılıyor.

      if (changed) {
        addLog('  📈 ${emptyCells - currentEmpty} hücre dolduruldu (kalan: $currentEmpty)');
        emptyCells = currentEmpty;
      } else {
        addLog('  ⏸️  Daha fazla kural uygulanamıyor');
      } // Yapılan değişiklikler loglanıyor. Eğer değişiklik yapılmadıysa döngüden çıkılıyor. Haliyle log yapılması gerekmiyor.
      
      if (currentEmpty == 0) {
        addLog('  🎉 Tüm hücreler rule-based ile dolduruldu!');
        break;
      } // Hücreler tamamen doldurulduysa döngüyü break ile sonlandırıyoruz. 
    }
    
    return true; // Rule-based algoritma her zaman true döner çünkü kural tabanlı algoritma boş hücreleri doldurmak için çalışır.
    // Eğer kural tabanlı algoritma ile çözüm bulunamazsa, backtracking algoritması devreye girer. Detay için solveWithBacktracking metoduna bakabilirsiniz.
  }

    bool solveWithBacktracking() {

    addLog('🧩 Backtracking algoritması başlatılıyor...');

    int emptyCells = 0;
    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size; j++) {
        if (game.grid[i][j].type == CellType.empty) emptyCells++;
      }
    } // Boş hücre sayısı hesaplanıyor ve loglanıyor.

    addLog('🔍 Backtracking için $emptyCells boş hücre kaldı');
    
    int attempts = 0;
    return backtrack(0, 0, attempts);
  }

  // Backtracking algoritması, hücreleri doldurmak için deneme-yanılma yöntemi kullanır.
  // Her hücre için önce dark, sonra light denemesi yapar. Eğer her iki deneme de geçerli değilse geri alır ve diğer seçenekleri dener.
  // Bu algoritma, kural tabanlı algoritmanın tamamlayıcısıdır ve kural tabanlı algoritma ile çözülemeyen durumlarda devreye girer.


    bool backtrack(int row, int col, int attempts) { 
      // row ve col parametreleri, grid üzerindeki hücrenin konumunu belirtir. attempts ise deneme sayısını tutar.

    if (row == game.size) {
      addLog('🎯 Backtracking tamamlandı! ($attempts deneme ile çözüm bulundu)');
      return isValid();
    } // Eğer satır sayısı grid boyutuna ulaştıysa, tüm grid doldurulmuş demektir. Bu durumda geçerli çözüm kontrol ediliyor.
    // Eğer geçerli çözüm ise true döner ve backtracking algoritması başarılı bir şekilde tamamlanmış olur.
    
    // Bu metod recursive olarak çalışır. Her hücre için önce dark, sonra light denemesi yapar.

    if (col == game.size) {
      return backtrack(row + 1, 0, attempts);
    } // Eğer satır sayısı grid boyutuna ulaştıysa, tüm grid doldurulmuş demektir. Bu durumda geçerli çözüm kontrol ediliyor.
    
    if (game.grid[row][col].type != CellType.empty) {
      return backtrack(row, col + 1, attempts);
    } // Eğer hücre zaten dolu ise, bir sonraki hücreye geçilir. Bu durumda tekrar backtrack metodu çağrılır.
    
    if (attempts % 500 == 0 && attempts > 0) {
      addLog('🔍 Backtracking: $attempts deneme, pozisyon ($row,$col)');
    } // Her 500 denemede bir loglanır. Bu, algoritmanın ilerlemesini takip etmek için kullanılır.
    // Eğer deneme sayısı çok artarsa bilgimiz olması açısından loglanır.
    
    
    game.grid[row][col].type = CellType.dark;
    if (isValidMove(row, col)) {
      if (attempts % 2000 == 0 && attempts > 0) {
        addLog('  ✅ ($row,$col) için Dark deneniyor...');
      }
      if (backtrack(row, col + 1, attempts + 1)) {
        return true;
      }
    } // Dark hücre deneniyor. Eğer geçerli bir hamle ise, bir sonraki hücreye geçilir.
    
    game.grid[row][col].type = CellType.light;
    if (isValidMove(row, col)) {
      if (attempts % 2000 == 0 && attempts > 0) {
        addLog('  ✅ ($row,$col) için Light deneniyor...');
      }
      if (backtrack(row, col + 1, attempts + 1)) {
        return true;
      }
    } // Dark gibi Light denemesi de yapılabiliyor.
    
    
    game.grid[row][col].type = CellType.empty;
    if (attempts % 5000 == 0 && attempts > 0) {
      addLog('  ⏪ ($row,$col) geri alındı, başka seçenekler deneniyor...');
    }
    return false;
  } // Eğer her iki deneme de geçerli değilse, hücre boşaltılır ve geri alınır. Bu durumda false döner ve bir önceki hücreye geri dönülür.
  
  bool isValidMove(int row, int col) { // Bu metod, hücrenin geçerli bir hamle olup olmadığını kontrol eder.
    return isValidConstraints(row, col) && 
           isValidAdjacent(row, col) && 
           isValidBalance(row, col);
  } // Üçlü yan yana var mı kontrol edilir ya da aynı sayıda dark ve light hücre var mı kontrol edilir. = ve x kuralları da test edilir.
  
  // Aşağıdaki iç içe for'lar oyun tahtasını dolaşır.

  bool applyConstraintRules() { // Bu metod, kısıt kurallarını uygular. Yani = ve x kurallarını uygular.
    bool changed = false;       // Eğer kısıt kuralları uygulanırsa, changed true olur ve döngü devam eder.
    
    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size; j++) {
        Cell current = game.grid[i][j];
        
        if (j < game.size - 1) {
          Cell right = game.grid[i][j + 1];

          for (var constraint in current.rightConstraints) {
            if (constraint == ConstraintType.equal) {
              if (current.type != CellType.empty && right.type == CellType.empty) {
                right.type = current.type;
                changed = true;
                addLog('    📍 Eşitlik: (${i},${j+1}) = ${current.type}');
              } else if (right.type != CellType.empty && current.type == CellType.empty) {
                current.type = right.type;
                changed = true;
                addLog('    📍 Eşitlik: (${i},${j}) = ${right.type}');
              } 
            } // Eğer kısıt türü = ise, hücrelerin tipleri eşitleniyor. Eğer bir hücre dolu ise ve diğer hücre boş ise, dolu hücrenin tipi boş hücreye atanıyor.
            else if (constraint == ConstraintType.diff) {
              if (current.type != CellType.empty && right.type == CellType.empty) {
                right.type = current.type == CellType.dark ? CellType.light : CellType.dark;
                changed = true;
                addLog('    📍 Zıtlık: (${i},${j+1}) = ${right.type}');
              } else if (right.type != CellType.empty && current.type == CellType.empty) {
                current.type = right.type == CellType.dark ? CellType.light : CellType.dark;
                changed = true;
                addLog('    📍 Zıtlık: (${i},${j}) = ${current.type}');
              }
            } // Eğer kısıt türü x ise, hücrelerin tipleri zıtlaştırılıyor. Eğer bir hücre dolu ise ve diğer hücre boş ise, dolu hücrenin tipi boş hücreye zıt renk atanıyor.
          }
        } 
        
        if (i < game.size - 1) {
          Cell bottom = game.grid[i + 1][j];
          
          for (var constraint in current.bottomConstraints) {
            if (constraint == ConstraintType.equal) {
              if (current.type != CellType.empty && bottom.type == CellType.empty) {
                bottom.type = current.type;
                changed = true;
                addLog('    📍 Eşitlik: (${i+1},${j}) = ${current.type}');
              } else if (bottom.type != CellType.empty && current.type == CellType.empty) {
                current.type = bottom.type;
                changed = true;
                addLog('    📍 Eşitlik: (${i},${j}) = ${bottom.type}');
              }
            } 
            else if (constraint == ConstraintType.diff) {
              if (current.type != CellType.empty && bottom.type == CellType.empty) {
                bottom.type = current.type == CellType.dark ? CellType.light : CellType.dark;
                changed = true;
                addLog('    📍 Zıtlık: (${i+1},${j}) = ${bottom.type}');
              } else if (bottom.type != CellType.empty && current.type == CellType.empty) {
                current.type = bottom.type == CellType.dark ? CellType.light : CellType.dark;
                changed = true;
                addLog('    📍 Zıtlık: (${i},${j}) = ${current.type}');
              }
            }
          }
        }
      }
    }
    
    return changed;
  }
  
  bool applyAdjacentRules() {
    // Bu metod, yan yana kurallarını uygular.
    // Yani 2 tane yan yana dark veya light hücre varsa 3. boş hücreye zıt renk atanıyor.
    bool changed = false;
    
    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size - 2; j++) {
        if (game.grid[i][j].type != CellType.empty && 
            game.grid[i][j].type == game.grid[i][j + 1].type &&
            game.grid[i][j + 2].type == CellType.empty) {
          game.grid[i][j + 2].type = game.grid[i][j].type == CellType.dark ? 
              CellType.light : CellType.dark;
          changed = true;
          addLog('    🚫 Yan yana: (${i},${j+2}) = ${game.grid[i][j + 2].type}');
        }
        
        if (game.grid[i][j].type == CellType.empty &&
            j + 2 < game.size &&
            game.grid[i][j + 1].type != CellType.empty && 
            game.grid[i][j + 1].type == game.grid[i][j + 2].type) {
          game.grid[i][j].type = game.grid[i][j + 1].type == CellType.dark ? 
              CellType.light : CellType.dark;
          changed = true;
          addLog('    🚫 Yan yana: (${i},${j}) = ${game.grid[i][j].type}');
        }
      }
    }
    
    for (int i = 0; i < game.size - 2; i++) {
      for (int j = 0; j < game.size; j++) {
        if (game.grid[i][j].type != CellType.empty && 
            game.grid[i][j].type == game.grid[i + 1][j].type &&
            game.grid[i + 2][j].type == CellType.empty) {
          game.grid[i + 2][j].type = game.grid[i][j].type == CellType.dark ? 
              CellType.light : CellType.dark;
          changed = true;
          addLog('    🚫 Yan yana: (${i+2},${j}) = ${game.grid[i + 2][j].type}');
        }
        
        if (game.grid[i][j].type == CellType.empty &&
            i + 2 < game.size &&
            game.grid[i + 1][j].type != CellType.empty && 
            game.grid[i + 1][j].type == game.grid[i + 2][j].type) {
          game.grid[i][j].type = game.grid[i + 1][j].type == CellType.dark ? 
              CellType.light : CellType.dark;
          changed = true;
          addLog('    🚫 Yan yana: (${i},${j}) = ${game.grid[i][j].type}');
        }
      }
    }
    
    return changed;
  }
  
  bool applyBalanceRules() {
    // Bu metod, satır ve sütun dengesi kurallarını uygular.
    // Yani her satır ve sütunda aynı sayıda dark ve light hücre olmalı.
    // Eğer bir satırda veya sütunda dark hücre sayısı maxAllowed sayısına ulaştıysa, boş hücreler light olarak doldurulur.
    // Eğer bir satırda veya sütunda light hücre sayısı maxAllowed sayısına ulaştıysa, boş hücreler dark olarak doldurulur.

    bool changed = false;
    
    for (int i = 0; i < game.size; i++) {
      int darkCount = 0;
      int lightCount = 0;
      List<int> emptyPositions = [];
      
      for (int j = 0; j < game.size; j++) {
        switch (game.grid[i][j].type) {
          case CellType.dark:
            darkCount++;
            break;
          case CellType.light:
            lightCount++;
            break;
          case CellType.empty:
            emptyPositions.add(j);
            break;
        }
      }
      
      int maxAllowed = game.size ~/ 2;
      
      if (darkCount == maxAllowed && emptyPositions.isNotEmpty) {
        for (int j in emptyPositions) {
          game.grid[i][j].type = CellType.light;
          changed = true;
          addLog('    ⚖️ Satır dengesi: (${i},${j}) = light');
        }
      } else if (lightCount == maxAllowed && emptyPositions.isNotEmpty) {
        for (int j in emptyPositions) {
          game.grid[i][j].type = CellType.dark;
          changed = true;
          addLog('    ⚖️ Satır dengesi: (${i},${j}) = dark');
        }
      }
    }
    
    for (int j = 0; j < game.size; j++) {
      int darkCount = 0;
      int lightCount = 0;
      List<int> emptyPositions = [];
      
      for (int i = 0; i < game.size; i++) {
        switch (game.grid[i][j].type) {
          case CellType.dark:
            darkCount++;
            break;
          case CellType.light:
            lightCount++;
            break;
          case CellType.empty:
            emptyPositions.add(i);
            break;
        }
      }
      
      int maxAllowed = game.size ~/ 2;
      
      if (darkCount == maxAllowed && emptyPositions.isNotEmpty) {
        for (int i in emptyPositions) {
          game.grid[i][j].type = CellType.light;
          changed = true;
          addLog('    ⚖️ Sütun dengesi: (${i},${j}) = light');
        }
      } else if (lightCount == maxAllowed && emptyPositions.isNotEmpty) {
        for (int i in emptyPositions) {
          game.grid[i][j].type = CellType.dark;
          changed = true;
          addLog('    ⚖️ Sütun dengesi: (${i},${j}) = dark');
        }
      }
    }
    
    return changed;
  }
  
  bool applyForcedMoves() {
    // Bu metod, zorunlu hamleleri uygular.
    // Yani eğer bir hücre dark veya light ise ve yanındaki 2 hücre de aynı renkte ise, ortadaki boş hücreye zıt renk atanıyor.
    // X - D - D --> X = L

    bool changed = false;
    
    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size - 2; j++) {
        if (game.grid[i][j].type != CellType.empty && 
            game.grid[i][j].type == game.grid[i][j + 2].type &&
            game.grid[i][j + 1].type == CellType.empty) {
          game.grid[i][j + 1].type = game.grid[i][j].type == CellType.dark ? 
              CellType.light : CellType.dark;
          changed = true;
          addLog('    🎯 Zorunlu hamle: (${i},${j+1}) = ${game.grid[i][j + 1].type}');
        }
      }
    }
    
    for (int i = 0; i < game.size - 2; i++) {
      for (int j = 0; j < game.size; j++) {
        if (game.grid[i][j].type != CellType.empty && 
            game.grid[i][j].type == game.grid[i + 2][j].type &&
            game.grid[i + 1][j].type == CellType.empty) {
          game.grid[i + 1][j].type = game.grid[i][j].type == CellType.dark ? 
              CellType.light : CellType.dark;
          changed = true;
          addLog('    🎯 Zorunlu hamle: (${i+1},${j}) = ${game.grid[i + 1][j].type}');
        }
      }
    }
    
    return changed;
  }
  
  bool isValidConstraints(int row, int col) {
    // Bu metod, hücrenin kısıt kurallarına uygun olup olmadığını kontrol eder.
    // Yani = ve x kurallarına uygun mu kontrol eder.

    Cell current = game.grid[row][col];
    
    if (col < game.size - 1) {
      Cell right = game.grid[row][col + 1];
      if (right.type != CellType.empty) {
        for (var constraint in current.rightConstraints) {
          if (constraint == ConstraintType.equal && current.type != right.type) {
            return false;
          }
          if (constraint == ConstraintType.diff && current.type == right.type) {
            return false;
          }
        }
      }
    }
    
    if (col > 0) {
      Cell left = game.grid[row][col - 1];
      if (left.type != CellType.empty) {
        for (var constraint in left.rightConstraints) {
          if (constraint == ConstraintType.equal && current.type != left.type) {
            return false;
          }
          if (constraint == ConstraintType.diff && current.type == left.type) {
            return false;
          }
        }
      }
    }
    
    if (row < game.size - 1) {
      Cell bottom = game.grid[row + 1][col];
      if (bottom.type != CellType.empty) {
        for (var constraint in current.bottomConstraints) {
          if (constraint == ConstraintType.equal && current.type != bottom.type) {
            return false;
          }
          if (constraint == ConstraintType.diff && current.type == bottom.type) {
            return false;
          }
        }
      }
    }
    
    if (row > 0) {
      Cell top = game.grid[row - 1][col];
      if (top.type != CellType.empty) {
        for (var constraint in top.bottomConstraints) {
          if (constraint == ConstraintType.equal && current.type != top.type) {
            return false;
          }
          if (constraint == ConstraintType.diff && current.type == top.type) {
            return false;
          }
        }
      }
    }
    
    return true;
  }
  
  bool isValidAdjacent(int row, int col) {
    // Bu metod, hücrenin yan yana kurallarına uygun olup olmadığını kontrol eder.
    // Yani 2 tane yan yana dark veya light hücre varsa 3. boş hücreye zıt renk atanıyor.
    // X - D - D - X --> X = L

    CellType currentType = game.grid[row][col].type;
    
    int leftSame = 0;
    int rightSame = 0;
    
    for (int i = col - 1; i >= 0 && game.grid[row][i].type == currentType; i--) {
      leftSame++;
    } // Soldan başlayarak aynı tipteki hücreleri sayar.
    
    for (int i = col + 1; i < game.size && game.grid[row][i].type == currentType; i++) {
      rightSame++;
    } // Sağdan başlayarak aynı tipteki hücreleri sayar.
    
    if (leftSame + rightSame >= 2) return false; // Eğer soldan ve sağdan gelen aynı tipteki hücrelerin sayısı 2 veya daha fazlaysa, bu kural ihlali demektir.
    
    int topSame = 0;
    int bottomSame = 0;
    
    for (int i = row - 1; i >= 0 && game.grid[i][col].type == currentType; i--) {
      topSame++;
    } // Yukarıdan başlayarak aynı tipteki hücreleri sayar.
    
    for (int i = row + 1; i < game.size && game.grid[i][col].type == currentType; i++) {
      bottomSame++;
    } // Aşağıdan başlayarak aynı tipteki hücreleri sayar.
    
    if (topSame + bottomSame >= 2) return false; // Eğer yukarıdan ve aşağıdan gelen aynı tipteki hücrelerin sayısı 2 veya daha fazlaysa, bu kural ihlali demektir.
    
    return true;
  }
  
  bool isValidBalance(int row, int col) {
    // Bu metod, hücrenin satır ve sütun dengesi kurallarına uygun olup olmadığını kontrol eder.
    // Yani her satır ve sütunda aynı sayıda dark ve light hücre olmalı.

    int maxAllowed = game.size ~/ 2;
    
    int rowdark = 0;
    int rowlight = 0;
    
    for (int j = 0; j < game.size; j++) {
      switch (game.grid[row][j].type) {
        case CellType.dark:
          rowdark++;
          break;
        case CellType.light:
          rowlight++;
          break;
        case CellType.empty:
          break;
      }
    } // Satırdaki dark ve light hücre sayısını sayar. 
    // Eğer satırdaki dark veya light hücre sayısı maxAllowed sayısından fazlaysa, bu kural ihlali demektir.
    
    if (rowdark > maxAllowed || rowlight > maxAllowed) {
      return false;
    }
    
    int coldark = 0;
    int collight = 0;
    
    for (int i = 0; i < game.size; i++) {
      switch (game.grid[i][col].type) {
        case CellType.dark:
          coldark++;
          break;
        case CellType.light:
          collight++;
          break;
        case CellType.empty:
          break;
      }
    } // Sütundaki dark ve light hücre sayısını sayar.
    
    if (coldark > maxAllowed || collight > maxAllowed) {
      return false;
    }
    
    return true;
  }
  
  bool isComplete() { // Bu metod, oyunun tamamlanıp tamamlanmadığını kontrol eder.
    // Yani tüm hücreler dolu mu kontrol eder.
    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size; j++) {
        if (game.grid[i][j].type == CellType.empty) {
          return false;
        }
      }
    }
    return true;
  }


  // Tahta tamamlanmış olabilir doğru olduğu anlamına gelmez.
  // Aşağıdaki metod, oyunun geçerli olup olmadığını kontrol eder.
  
  bool isValid() {
    return checkConstraints() && checkAdjacent() && checkBalance();
    // Yukarıda tanımlanan metodlar geçerli olup olmadığını kontrol eder.
  }
  
  // Aşağıdaki check metodları yukarıdaki isValid metodunun tüm tahtaya uygulanmış halidir.
  bool checkConstraints() {

    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size; j++) {
        Cell current = game.grid[i][j];
        
        if (current.type == CellType.empty) continue;
        
        if (j < game.size - 1) {
          Cell right = game.grid[i][j + 1];
          if (right.type != CellType.empty) {
            for (var constraint in current.rightConstraints) {
              if (constraint == ConstraintType.equal && current.type != right.type) {
                addLog('❌ Kısıt ihlali: (${i},${j}) = ${current.type} ≠ (${i},${j+1}) = ${right.type}');
                return false;
              }
              if (constraint == ConstraintType.diff && current.type == right.type) {
                addLog('❌ Kısıt ihlali: (${i},${j}) = ${current.type} == (${i},${j+1}) = ${right.type}');
                return false;
              }
            }
          }
        }
        
        if (i < game.size - 1) {
          Cell bottom = game.grid[i + 1][j];
          if (bottom.type != CellType.empty) {
            for (var constraint in current.bottomConstraints) {
              if (constraint == ConstraintType.equal && current.type != bottom.type) {
                addLog('❌ Kısıt ihlali: (${i},${j}) = ${current.type} ≠ (${i+1},${j}) = ${bottom.type}');
                return false;
              }
              if (constraint == ConstraintType.diff && current.type == bottom.type) {
                addLog('❌ Kısıt ihlali: (${i},${j}) = ${current.type} == (${i+1},${j}) = ${bottom.type}');
                return false;
              }
            }
          }
        }
      }
    }
    return true;
  }
  
  bool checkAdjacent() {
    for (int i = 0; i < game.size; i++) {
      for (int j = 0; j < game.size - 2; j++) {
        if (game.grid[i][j].type != CellType.empty &&
            game.grid[i][j].type == game.grid[i][j + 1].type &&
            game.grid[i][j].type == game.grid[i][j + 2].type) {
          addLog('❌ Yan yana ihlali: Satır $i, sütunlar $j-${j+2}: ${game.grid[i][j].type}');
          return false;
        }
      }
    }
    
    for (int i = 0; i < game.size - 2; i++) {
      for (int j = 0; j < game.size; j++) {
        if (game.grid[i][j].type != CellType.empty &&
            game.grid[i][j].type == game.grid[i + 1][j].type &&
            game.grid[i][j].type == game.grid[i + 2][j].type) {
          addLog('❌ Yan yana ihlali: Sütun $j, satırlar $i-${i+2}: ${game.grid[i][j].type}');
          return false;
        }
      }
    }
    
    return true;
  }
  
  bool checkBalance() {
    int maxAllowed = game.size ~/ 2;
    
    for (int i = 0; i < game.size; i++) {
      int darkCount = 0;
      int lightCount = 0;
      
      for (int j = 0; j < game.size; j++) {
        if (game.grid[i][j].type == CellType.dark) darkCount++;
        if (game.grid[i][j].type == CellType.light) lightCount++;
      }
      
      if (darkCount != maxAllowed || lightCount != maxAllowed) {
        addLog('❌ Denge ihlali: Satır $i - B:$darkCount, L:$lightCount (olması gereken: $maxAllowed)');
        return false;
      }
    }
    
    for (int j = 0; j < game.size; j++) {
      int darkCount = 0;
      int lightCount = 0;
      
      for (int i = 0; i < game.size; i++) {
        if (game.grid[i][j].type == CellType.dark) darkCount++;
        if (game.grid[i][j].type == CellType.light) lightCount++;
      }
      
      if (darkCount != maxAllowed || lightCount != maxAllowed) {
        addLog('❌ Denge ihlali: Sütun $j - B:$darkCount, L:$lightCount (olması gereken: $maxAllowed)');
        return false;
      }
    }
    
    return true;
  }
}




// Aşağıdaki sınıf, web arayüzünü yönetir.
// Bu sınıf, kullanıcı etkileşimlerini ve görsel güncellemeleri yönetir.
// Bu kısım için dürüst olacağım büyük oranda Generative AI desteği alındı.
// Daha önce Dart'ı HTML için Backend olarak kullanmamıştım ve ders kapsamında olmadığı için biraz rahat davrandım yapay zeka kullanımı açısından.
// Ancak tamamen benim direktiflerimin uygulanmasıyla oluşturuldu.

class TangoWebUI {
  int currentSize = 6;
  TangoGame? currentGame;
  Element? inputGridElement;
  Element? solutionGridElement;
  
  void initialize() {
    setupGridSize();
    createInputGrid();
    setupEventListeners();
  }
    void setupGridSize() {
    final sizeButtons = querySelectorAll('.size-btn');
    for (var button in sizeButtons) {
      button.onClick.listen((event) {
        setGridSize(6); // Always use 6x6
      });
    }
  }
  
  void setGridSize(int size) {
    currentSize = 6; // Force 6x6 only
    
    // Update active button
    querySelectorAll('.size-btn').forEach((btn) => btn.classes.remove('active'));
    querySelector('.size-btn')?.classes.add('active');
    
    createInputGrid();
    hideSolution();
  }    void createInputGrid() {
    currentGame = TangoGame(currentSize);
    inputGridElement = querySelector('#input-grid');
    
    if (inputGridElement == null) return;
    
    inputGridElement!.children.clear();
    // No need to add/remove grid classes since we only support 6x6
    
    // Calculate grid positions including constraints
    for (int i = 0; i < currentSize; i++) {
      for (int j = 0; j < currentSize; j++) {
        // Add cell
        final cell = DivElement()
          ..classes.add('cell')
          ..classes.add('empty')
          ..text = '_'
          ..onClick.listen((_) => cycleCellType(i, j));
        
        inputGridElement!.children.add(cell);
        
        // Add right constraint if not last column
        if (j < currentSize - 1) {
          final rightConstraint = DivElement()
            ..classes.add('constraint')
            ..text = ' '
            ..onClick.listen((_) => cycleConstraint(i, j, true));
          
          inputGridElement!.children.add(rightConstraint);
        }
      }
      
      // Add bottom constraints row if not last row
      if (i < currentSize - 1) {
        for (int j = 0; j < currentSize; j++) {
          final bottomConstraint = DivElement()
            ..classes.add('constraint')
            ..text = ' '
            ..onClick.listen((_) => cycleConstraint(i, j, false));
          
          inputGridElement!.children.add(bottomConstraint);
          
          // Add spacer for right constraints if not last column
          if (j < currentSize - 1) {
            final spacer = DivElement()
              ..classes.add('constraint')
              ..text = ' ';
            inputGridElement!.children.add(spacer);
          }
        }
      }
    }
  }
    void cycleCellType(int row, int col) {
    if (currentGame == null) return;
    
    final cell = currentGame!.grid[row][col];
    
    switch (cell.type) {
      case CellType.empty:
        cell.type = CellType.light;
        break;
      case CellType.light:
        cell.type = CellType.dark;
        break;
      case CellType.dark:
        cell.type = CellType.empty;
        break;
    }
    
    updateInputGridDisplay();
  }
  
  void cycleConstraint(int row, int col, bool isRight) {
    if (currentGame == null) return;
    
    final cell = currentGame!.grid[row][col];
    final constraints = isRight ? cell.rightConstraints : cell.bottomConstraints;
    
    if (constraints.isEmpty) {
      constraints.add(ConstraintType.equal);
    } else if (constraints.contains(ConstraintType.equal)) {
      constraints.clear();
      constraints.add(ConstraintType.diff);
    } else {
      constraints.clear();
    }
    
    updateInputGridDisplay();
  }
  
  void updateInputGridDisplay() {
    if (currentGame == null || inputGridElement == null) return;
    
    final cells = inputGridElement!.querySelectorAll('.cell');
    final constraints = inputGridElement!.querySelectorAll('.constraint');
    
    int cellIndex = 0;
    int constraintIndex = 0;
    
    for (int i = 0; i < currentSize; i++) {
      for (int j = 0; j < currentSize; j++) {
        final cell = currentGame!.grid[i][j];
        final cellElement = cells[cellIndex++];
        
        cellElement.classes.removeAll(['empty', 'dark', 'light']);
        
        switch (cell.type) {
          case CellType.empty:
            cellElement.classes.add('empty');
            cellElement.text = '_';
            break;
          case CellType.dark:
            cellElement.classes.add('dark');
            cellElement.text = 'D';
            break;
          case CellType.light:
            cellElement.classes.add('light');
            cellElement.text = 'L';
            break;
        }
        
        // Update right constraint if not last column
        if (j < currentSize - 1) {
          final constraintElement = constraints[constraintIndex++];
          constraintElement.classes.removeAll(['equal', 'diff']);
          
          if (cell.rightConstraints.contains(ConstraintType.equal)) {
            constraintElement.classes.add('equal');
            constraintElement.text = '=';
          } else if (cell.rightConstraints.contains(ConstraintType.diff)) {
            constraintElement.classes.add('diff');
            constraintElement.text = '×';
          } else {
            constraintElement.text = ' ';
          }
        }
      }
      
      // Update bottom constraints if not last row
      if (i < currentSize - 1) {
        for (int j = 0; j < currentSize; j++) {
          final cell = currentGame!.grid[i][j];
          final constraintElement = constraints[constraintIndex++];
          constraintElement.classes.removeAll(['equal', 'diff']);
          
          if (cell.bottomConstraints.contains(ConstraintType.equal)) {
            constraintElement.classes.add('equal');
            constraintElement.text = '=';
          } else if (cell.bottomConstraints.contains(ConstraintType.diff)) {
            constraintElement.classes.add('diff');
            constraintElement.text = '×';
          } else {
            constraintElement.text = ' ';
          }
          
          // Skip spacer constraint if not last column
          if (j < currentSize - 1) {
            constraintIndex++;
          }
        }
      }
    }
  }
    void solvePuzzle() {
    if (currentGame == null) return;
    
    // Auto-expand log section when solving starts
    final logSection = querySelector('#log-section');
    final logToggle = querySelector('#log-toggle');
    if (logSection != null && logToggle != null) {
      if (logSection.classes.contains('collapsed')) {
        logSection.classes.remove('collapsed');
        logToggle.text = '▲';
      }
    }
    
    final solver = TangoSolver(currentGame!);
    final solved = solver.solve();
    
    if (solved) {
      showSolution();
    }
  }
    void showSolution() {
    final solutionSection = querySelector('#solution-section');
    solutionGridElement = querySelector('#solution-grid');
    
    if (solutionSection == null || solutionGridElement == null || currentGame == null) return;
      solutionSection.style.display = 'block';
    
    solutionGridElement!.children.clear();
    // No need to add/remove grid classes since we only support 6x6
    
    // Create solution grid display (same structure as input grid)
    for (int i = 0; i < currentSize; i++) {
      for (int j = 0; j < currentSize; j++) {
        final cell = currentGame!.grid[i][j];
        final cellElement = DivElement()..classes.add('cell');
        
        switch (cell.type) {
          case CellType.empty:
            cellElement.classes.add('empty');
            cellElement.text = '_';
            break;
          case CellType.dark:
            cellElement.classes.add('dark');
            cellElement.text = 'D';
            break;
          case CellType.light:
            cellElement.classes.add('light');
            cellElement.text = 'L';
            break;
        }
        
        solutionGridElement!.children.add(cellElement);
        
        // Add right constraint if not last column
        if (j < currentSize - 1) {
          final rightConstraint = DivElement()..classes.add('constraint');
          
          if (cell.rightConstraints.contains(ConstraintType.equal)) {
            rightConstraint.classes.add('equal');
            rightConstraint.text = '=';
          } else if (cell.rightConstraints.contains(ConstraintType.diff)) {
            rightConstraint.classes.add('diff');
            rightConstraint.text = '×';
          } else {
            rightConstraint.text = ' ';
          }
          
          solutionGridElement!.children.add(rightConstraint);
        }
      }
      
      // Add bottom constraints row if not last row
      if (i < currentSize - 1) {
        for (int j = 0; j < currentSize; j++) {
          final cell = currentGame!.grid[i][j];
          final bottomConstraint = DivElement()..classes.add('constraint');
          
          if (cell.bottomConstraints.contains(ConstraintType.equal)) {
            bottomConstraint.classes.add('equal');
            bottomConstraint.text = '=';
          } else if (cell.bottomConstraints.contains(ConstraintType.diff)) {
            bottomConstraint.classes.add('diff');
            bottomConstraint.text = '×';
          } else {
            bottomConstraint.text = ' ';
          }
          
          solutionGridElement!.children.add(bottomConstraint);
          
          // Add spacer for right constraints if not last column
          if (j < currentSize - 1) {
            final spacer = DivElement()
              ..classes.add('constraint')
              ..text = ' ';
            solutionGridElement!.children.add(spacer);
          }
        }
      }
    }
  }
  
  void hideSolution() {
    final solutionSection = querySelector('#solution-section');
    solutionSection?.style.display = 'none';
  }
  
  void clearGrid() {
    if (currentGame == null) return;
    
    // Clear all cells and constraints
    for (int i = 0; i < currentSize; i++) {
      for (int j = 0; j < currentSize; j++) {
        currentGame!.grid[i][j].type = CellType.empty;
        currentGame!.grid[i][j].rightConstraints.clear();
        currentGame!.grid[i][j].bottomConstraints.clear();
      }
    }
    
    updateInputGridDisplay();
    hideSolution();
    
    // Clear log
    final logElement = querySelector('#log-output');
    logElement?.text = '';
  }
  
  void loadSample() {
    if (currentGame == null) return;
    
    clearGrid();
    currentGame!.setupSampleConstraints();
    updateInputGridDisplay();
  }    void setupEventListeners() {
    querySelector('#solve-btn')?.onClick.listen((_) => solvePuzzle());
    querySelector('#clear-btn')?.onClick.listen((_) => clearGrid());
    querySelector('#sample-btn')?.onClick.listen((_) => loadSample());
    querySelector('.collapsible')?.onClick.listen((_) => toggleLog());
  }
  
  void toggleLog() {
    final logSection = querySelector('#log-section');
    final logToggle = querySelector('#log-toggle');
    
    if (logSection != null && logToggle != null) {
      if (logSection.classes.contains('collapsed')) {
        logSection.classes.remove('collapsed');
        logToggle.text = '▲';
      } else {
        logSection.classes.add('collapsed');
        logToggle.text = '▼';
      }
    }
  }
}

// Global functions for button handlers
TangoWebUI ui = TangoWebUI();

void setGridSize(int size) => ui.setGridSize(size);
void solvePuzzle() => ui.solvePuzzle();
void clearGrid() => ui.clearGrid();
void loadSample() => ui.loadSample();
void toggleLog() => ui.toggleLog();

void main() {
  ui.initialize();
  
  // Expose functions to JavaScript global context
  js.context['setGridSize'] = setGridSize;
  js.context['solvePuzzle'] = solvePuzzle;
  js.context['clearGrid'] = clearGrid;
  js.context['loadSample'] = loadSample;
  js.context['toggleLog'] = toggleLog;
}
