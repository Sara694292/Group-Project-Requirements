import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  HijriCalendar.setLocal('ar'); 

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: const QuranApp(),
    ),
  );
}

// ==========================================
// 1. STATE MANAGEMENT
// ==========================================
class AppState extends ChangeNotifier {
  final SharedPreferences prefs;

  late bool isDarkMode;
  late bool isRTL;
  late int selectedGradientIndex;
  late double fontSize;
  late String bookmarkedItem;
  List<String> notebookEntries = [];
  List<String> highlightedSurahs = [];
  List<String> favoriteAudios = [];

  final List<List<Color>> appGradients = [
    [const Color(0xFF004D40), const Color(0xFF009688)], // Green
    [const Color(0xFF1A237E), const Color(0xFF3F51B5)], // Navy
    [const Color(0xFF4A148C), const Color(0xFF9C27B0)], // Purple
    [const Color(0xFFB71C1C), const Color(0xFFE53935)], // Red
    [const Color(0xFF212121), const Color(0xFF607D8B)], // Slate
  ];

  AppState(this.prefs) {
    isDarkMode = prefs.getBool('isDarkMode') ?? false;
    isRTL = prefs.getBool('isRTL') ?? true;
    selectedGradientIndex = prefs.getInt('gradientIndex') ?? 0;
    fontSize = prefs.getDouble('fontSize') ?? 24.0;
    bookmarkedItem = prefs.getString('bookmark') ?? '';
    notebookEntries = prefs.getStringList('notebook') ?? [];
    highlightedSurahs = prefs.getStringList('highlights') ?? [];
    favoriteAudios = prefs.getStringList('favAudios') ?? [];
  }

  LinearGradient get currentGradient => LinearGradient(
        colors: appGradients[selectedGradientIndex],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  Color get primaryColor => appGradients[selectedGradientIndex][0];

  void toggleTheme(bool value) {
    isDarkMode = value;
    prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  void toggleDirection(bool value) {
    isRTL = value;
    prefs.setBool('isRTL', value);
    notifyListeners();
  }

  void setGradient(int index) {
    selectedGradientIndex = index;
    prefs.setInt('gradientIndex', index);
    notifyListeners();
  }

  void setFontSize(double size) {
    fontSize = size;
    prefs.setDouble('fontSize', size);
    notifyListeners();
  }

  void toggleHighlight(String surahNumber) {
    highlightedSurahs.contains(surahNumber)
        ? highlightedSurahs.remove(surahNumber)
        : highlightedSurahs.add(surahNumber);
    prefs.setStringList('highlights', highlightedSurahs);
    notifyListeners();
  }

  void toggleFavoriteAudio(String surahNumber) {
    favoriteAudios.contains(surahNumber)
        ? favoriteAudios.remove(surahNumber)
        : favoriteAudios.add(surahNumber);
    prefs.setStringList('favAudios', favoriteAudios);
    notifyListeners();
  }

  void saveToNotebook(String text) {
    if (!notebookEntries.contains(text)) {
      notebookEntries.add(text);
      prefs.setStringList('notebook', notebookEntries);
      notifyListeners();
    }
  }

  void deleteFromNotebook(int index) {
    notebookEntries.removeAt(index);
    prefs.setStringList('notebook', notebookEntries);
    notifyListeners();
  }
}

// ==========================================
// 2. MAIN APP ROOT
// ==========================================
class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'Al Quran Pro',
      debugShowCheckedModeBanner: false,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: appState.isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: appState.primaryColor, brightness: Brightness.light),
        useMaterial3: true,
        textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: appState.primaryColor, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainTabController(),
    );
  }
}

// ==========================================
// 3. BOTTOM NAVIGATION
// ==========================================
class MainTabController extends StatefulWidget {
  const MainTabController({super.key});
  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const HomeTabScreen(),
    const AudioPlayerScreen(),
    const HighlightsScreen(),
    const NotebookScreen(),
    const CalendarScreen(),
    const SettingsAboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        // ignore: deprecated_member_use
        indicatorColor: appState.primaryColor.withOpacity(0.3),
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'سەرەکی'),
          NavigationDestination(icon: Icon(Icons.headset), label: 'دەنگ'),
          NavigationDestination(icon: Icon(Icons.star), label: 'دڵخواز'),
          NavigationDestination(icon: Icon(Icons.book), label: 'تێبینی'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'بەروار'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'ڕێکخستن'),
        ],
      ),
    );
  }
}

// ==========================================
// 4. HOME TAB
// ==========================================
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});
  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> with SingleTickerProviderStateMixin {
  late TabController _topTabController;
  List<dynamic> allSurahs = [];
  List<dynamic> filteredSurahs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _topTabController = TabController(length: 3, vsync: this);
    fetchSurahList();
  }

  Future<void> fetchSurahList() async {
    try {
      final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          allSurahs = data;
          filteredSurahs = data;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void searchSurah(String query) {
    setState(() {
      filteredSurahs = allSurahs.where((s) {
        return s['englishName'].toString().toLowerCase().contains(query.toLowerCase()) ||
               s['name'].toString().contains(query) ||
               s['number'].toString().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('قورئانی پیرۆز', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appState.currentGradient)),
        bottom: TabBar(
          controller: _topTabController,
          labelColor: Colors.white, unselectedLabelColor: Colors.white70, indicatorColor: Colors.amber,
          tabs: const [Tab(text: 'سورەتەکان'), Tab(text: 'جوزء'), Tab(text: 'لاپەڕە')],
        ),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(
        controller: _topTabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: searchSurah,
                  style: GoogleFonts.vazirmatn(),
                  decoration: InputDecoration(
                    hintText: "گەڕان بۆ ناوی سورەت یان ژمارە...",
                    hintStyle: GoogleFonts.vazirmatn(fontSize: 14),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = filteredSurahs[index];
                    final isStar = appState.highlightedSurahs.contains(surah['number'].toString());
                    return ListTile(
                      // ignore: deprecated_member_use
                      leading: CircleAvatar(backgroundColor: appState.primaryColor.withOpacity(0.2), child: Text('${surah['number']}')),
                      title: Text(surah['englishName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(surah['englishNameTranslation']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isStar ? Icons.star : Icons.star_border, color: isStar ? Colors.amber : Colors.grey),
                            onPressed: () => appState.toggleHighlight(surah['number'].toString()),
                          ),
                          Text(surah['name'], style: GoogleFonts.amiri(fontSize: 22, color: appState.primaryColor)),
                        ],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ReaderScreen(type: 'surah', id: surah['number'], title: surah['englishName']),
                      )),
                    );
                  },
                ),
              ),
            ],
          ),
          GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: 30,
            itemBuilder: (context, index) => InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(type: 'juz', id: index + 1, title: 'جوزء ${index + 1}'))),
              // ignore: deprecated_member_use
              child: Card(color: appState.primaryColor.withOpacity(0.1), child: Center(child: Text('جوزء ${index + 1}'))),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: 604,
            itemBuilder: (context, index) => InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(type: 'page', id: index + 1, title: 'لاپەڕە ${index + 1}'))),
              // ignore: deprecated_member_use
              child: Card(color: appState.primaryColor.withOpacity(0.1), child: Center(child: Text('${index + 1}'))),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. AUDIO PLAYER (RECITER LIST & BROWSER DOWNLOAD FIX)
// ==========================================
class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});
  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? currentlyPlayingSurah;
  bool isPlaying = false;

  // لیستی قورئان خوێنەکان
  final List<Map<String, String>> reciters = [
    {'name': 'عەبدولباست عەبدولسەمەد', 'url': 'https://server7.mp3quran.net/basit/'},
    {'name': 'میشاری ڕاشد ئەلعەفاسی', 'url': 'https://server8.mp3quran.net/afs/'},
    {'name': 'ماهر ئەلموعەیقلی', 'url': 'https://server12.mp3quran.net/maher/'},
    {'name': 'یاسر ئەلدۆسەری', 'url': 'https://server11.mp3quran.net/yasser/'},
  ];

  late String selectedReciterUrl;

  @override
  void initState() {
    super.initState();
    selectedReciterUrl = reciters[0]['url']!;
  }

  void togglePlay(int surahNumber) async {
    try {
      if (currentlyPlayingSurah == surahNumber && isPlaying) {
        await _audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("خەریکی بارکردنی دەنگە...")));
        String formattedNum = surahNumber.toString().padLeft(3, '0');
        await _audioPlayer.play(UrlSource("$selectedReciterUrl$formattedNum.mp3"));
        setState(() { isPlaying = true; currentlyPlayingSurah = surahNumber; });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("هەڵە: $e")));
    }
  }

  // باشترین ڕێگە بۆ داگرتن بەبێ دروستبوونی کێشە (لەلایەن وێبگەڕەوە دادەبەزێت)
  Future<void> downloadAudio(int surahNumber) async {
    String formattedNum = surahNumber.toString().padLeft(3, '0');
    final url = Uri.parse("$selectedReciterUrl$formattedNum.mp3");
    
    // کردنەوەی لینکەکە لە وێبگەڕدا بۆ ئەوەی بێ کێشە دابەزێتە ناو مۆبایلەکە
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("بەستەری داگرتن لە وێبگەڕ کرایەوە، تکایە ڕێگە بە داگرتنەکە بدە.")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ببوورە نەتوانرا بەستەری داگرتن بکرێتەوە.")));
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('دەنگی قورئان', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appState.currentGradient)),
      ),
      body: Column(
        children: [
          // بەشی هەڵبژاردنی قورئان خوێن
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // ignore: deprecated_member_use
            color: appState.primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("قورئان خوێن:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                DropdownButton<String>(
                  value: selectedReciterUrl,
                  underline: const SizedBox(),
                  style: GoogleFonts.vazirmatn(color: appState.primaryColor, fontWeight: FontWeight.bold),
                  items: reciters.map((r) => DropdownMenuItem(
                    value: r['url'],
                    child: Text(r['name']!),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedReciterUrl = val!;
                      _audioPlayer.stop();
                      isPlaying = false;
                      currentlyPlayingSurah = null;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 114,
              itemBuilder: (context, index) {
                final surahNum = index + 1;
                final isActive = currentlyPlayingSurah == surahNum;
                final isFav = appState.favoriteAudios.contains(surahNum.toString());

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  // ignore: deprecated_member_use
                  color: isActive ? appState.primaryColor.withOpacity(0.1) : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive ? appState.primaryColor : Colors.grey,
                      child: Text("$surahNum", style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text("سورەتی $surahNum", style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                          tooltip: "زیادکردن بۆ دڵخوازەکان",
                          onPressed: () => appState.toggleFavoriteAudio(surahNum.toString()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.blueGrey),
                          tooltip: "داونلۆدکردنی سورەتەکە",
                          onPressed: () => downloadAudio(surahNum),
                        ),
                        IconButton(
                          icon: Icon(isActive && isPlaying ? Icons.pause_circle : Icons.play_circle, size: 36, color: appState.primaryColor),
                          onPressed: () => togglePlay(surahNum),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. READER SCREEN (TAP TO ADD NOTE)
// ==========================================
class ReaderScreen extends StatefulWidget {
  final String type; 
  final int id;
  final String title;
  const ReaderScreen({super.key, required this.type, required this.id, required this.title});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<dynamic> ayahs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    String url = '';
    if (widget.type == 'surah') url = 'https://api.alquran.cloud/v1/surah/${widget.id}/quran-uthmani';
    if (widget.type == 'juz') url = 'https://api.alquran.cloud/v1/juz/${widget.id}/quran-uthmani';
    if (widget.type == 'page') url = 'https://api.alquran.cloud/v1/page/${widget.id}/quran-uthmani';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() { ayahs = json.decode(response.body)['data']['ayahs']; isLoading = false; });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.amiri(fontSize: 22, color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appState.currentGradient)),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: ayahs.length,
        // ignore: deprecated_member_use
        separatorBuilder: (_, __) => Divider(color: appState.primaryColor.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final ayah = ayahs[index];
          return GestureDetector(
            onTap: () { 
              appState.saveToNotebook(ayah['text']);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ئایەتەکە خەزن کرا لە تێبینییەکاندا")));
            },
            child: Container(
              color: Colors.transparent, 
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 14, child: Text('${ayah['numberInSurah'] ?? index+1}', style: const TextStyle(fontSize: 10))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        ayah['text'],
                        style: GoogleFonts.amiri(fontSize: appState.fontSize, height: 2.0),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 7. HIGHLIGHTS & NOTEBOOK
// ==========================================
class HighlightsScreen extends StatelessWidget {
  const HighlightsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('سورەتە دڵخوازەکان', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appState.currentGradient)),
      ),
      body: appState.highlightedSurahs.isEmpty 
          ? const Center(child: Text("هیچ سورەتێک نیشانە نەکراوە")) 
          : ListView.builder(
              itemCount: appState.highlightedSurahs.length,
              itemBuilder: (context, index) => ListTile(
                title: Text("سورەتی ژمارە ${appState.highlightedSurahs[index]}"),
                trailing: const Icon(Icons.star, color: Colors.amber),
              ),
            ),
    );
  }
}

class NotebookScreen extends StatelessWidget {
  const NotebookScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تێبینییەکانم', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appState.currentGradient)),
      ),
      body: appState.notebookEntries.isEmpty 
          ? const Center(child: Text("دەفتەری تێبینی بەتاڵە")) 
          : ListView.builder(
              itemCount: appState.notebookEntries.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(appState.notebookEntries[index], style: GoogleFonts.amiri(fontSize: 18, height: 1.8), textDirection: TextDirection.rtl),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => appState.deleteFromNotebook(index),
                  ),
                ),
              ),
            ),
    );
  }
}

// ==========================================
// 8. CALENDAR
// ==========================================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    var hijri = HijriCalendar.fromDate(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بەرواری کۆچی', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appState.currentGradient)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("بەرواری زاینی:", style: GoogleFonts.vazirmatn(fontSize: 16)),
            Text("${selectedDate.toLocal()}".split(' ')[0], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("بەرواری کۆچی:", style: GoogleFonts.vazirmatn(fontSize: 16)),
            Text(hijri.toFormat("dd MMMM yyyy"), style: GoogleFonts.amiri(fontSize: 30, color: appState.primaryColor)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: const Text('گۆڕینی بەروار'),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 9. SETTINGS & INFORMATION (WITH GITHUB)
// ==========================================
class SettingsAboutScreen extends StatelessWidget {
  const SettingsAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // تێبینی: ئەمە لینکێکی گشتییە و هیچ ناوێکی کەسی تێدا نییە بەپێی داواکارییەکەت
    const String githubUrl = 'https://github.com/';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ڕێکخستن و زانیاری', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appState.currentGradient)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("ڕێکخستنەکانی ڕووکار"),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('دۆخی تاریک (Dark Mode)'),
                  secondary: Icon(appState.isDarkMode ? Icons.nightlight : Icons.wb_sunny),
                  value: appState.isDarkMode,
                  onChanged: (val) => appState.toggleTheme(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('ئاراستەی ڕاست بۆ چەپ (RTL)'),
                  secondary: const Icon(Icons.format_textdirection_r_to_l),
                  value: appState.isRTL,
                  onChanged: (val) => appState.toggleDirection(val),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('هەڵبژاردنی ڕەنگ (Theme Color)'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 12,
                      children: List.generate(appState.appGradients.length, (index) {
                        return GestureDetector(
                          onTap: () => appState.setGradient(index),
                          child: CircleAvatar(
                            backgroundColor: appState.appGradients[index][0],
                            child: appState.selectedGradientIndex == index 
                                ? const Icon(Icons.check, color: Colors.white) 
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('قەبارەی فۆنتی عەرەبی'),
                  subtitle: Slider(
                    value: appState.fontSize,
                    min: 16.0, max: 40.0,
                    onChanged: (val) => appState.setFontSize(val),
                  ),
                  trailing: Text(appState.fontSize.round().toString()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle("دەربارەی ئەپڵیکەیشنەکە"),
          Card(
            elevation: 0,
            // ignore: deprecated_member_use
            color: appState.primaryColor.withOpacity(0.05),
            // ignore: deprecated_member_use
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: appState.primaryColor.withOpacity(0.2))),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(Icons.menu_book, size: 50, color: appState.primaryColor),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      "پڕۆژەی قورئانی پیرۆز (Quran App)",
                      style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold, fontSize: 18, color: appState.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "ئەم ئەپڵیکەیشنە سەرچاوەیەکی گشتگیر و پێشکەوتووە بۆ خوێندنەوە و گوێگرتن لە قورئانی پیرۆز. بەتایبەت دیزاین کراوە تاوەکو بەکارهێنەر بە ئاسانترین شێوە سوودی لێ ببینێت و دەستی بگات بە هەموو خزمەتگوزارییەکان بەبێ هەبوونی کێشە.",
                    style: GoogleFonts.vazirmatn(height: 1.8, fontSize: 14),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "تایبەتمەندییە سەرەکییەکانی ئەپەکە:",
                    style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  _buildBulletPoint("خوێندنەوەی دەقی قورئان بە ڕێنووسی عوسمانی دروست و بێ هەڵە لەگەڵ توانای گەڕان بۆ ئایەت و سورەتەکان."),
                  _buildBulletPoint("هەڵبژاردنی چەندین قورئان خوێنی جیاواز (وەک عەبدولباست، میشاری، ماهر و یاسر) بۆ گوێگرتن لە سورەتەکان."),
                  _buildBulletPoint("دابەزاندنی (Download) دەنگی سورەتەکان ڕاستەوخۆ بۆ ناو مۆبایلەکەت لە ڕێگەی وێبگەڕی مۆبایلەوە بەبێ دروستبوونی کێشە."),
                  _buildBulletPoint("زیادکردنی سورەت و دەنگەکان بۆ لیستی دڵخوازەکان (Favorites) بۆ ئەوەی خێراتر پێیان بگەیت."),
                  _buildBulletPoint("خەزنکردنی هەر ئایەتێک ڕاستەوخۆ بۆ ناو دەفتەری تێبینییەکان تەنها بە یەک کلیک کردن لەسەر ئایەتەکە."),
                  _buildBulletPoint("گۆڕینی بەروار لە زاینییەوە بۆ کۆچی بە شێوەیەکی زۆر ورد و ئاسان."),
                  _buildBulletPoint("کۆنترۆڵی تەواوی ڕووکار: گۆڕینی ڕەنگەکان، گەورە و بچووک کردنی قەبارەی فۆنت، و دۆخی تاریک (Dark Mode)."),
                  
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  // بەشی Github بەبێ ناوی کەسی
                  Text(
                    "سەرچاوەی کراوە (Open Source):",
                    style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.code),
                    title: const Text('پەڕەی گیت‌هەب (GitHub)'),
                    subtitle: const Text('کلیک بکە بۆ کردنەوە، پەنجەی لەسەر ڕابگرە بۆ کۆپیکردن.'),
                    onTap: () async {
                      final Uri url = Uri.parse(githubUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نەتوانرا بەستەرەکە بکرێتەوە')));
                      }
                    },
                    onLongPress: () {
                      Clipboard.setData(const ClipboardData(text: githubUrl));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بەستەری GitHub کۆپی کرا')));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(title, style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[700])),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.vazirmatn(fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }
}