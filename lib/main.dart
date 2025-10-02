import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const LifeGameApp());

class LifeGameApp extends StatelessWidget {
  const LifeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeGame',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
      ),
      home: const RootScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// ------------------------------ CONFIG PROGRESO ------------------------------
/// Rangos (niveles): 0..6  ⇔  D,C,B,A,S,SS,SSS
const double kMaxLevel = 6.0;
const int kLevelsCount = 7; // 0..6 → 7 anillos
const double kXpToLevelFactor = 0.01; // 100 XP → +1 nivel

const List<String> kRanks = ['D', 'C', 'B', 'A', 'S', 'SS', 'SSS'];
String levelToRank(double lv) => kRanks[lv.clamp(0, kMaxLevel).round()];

/// XP sugerido por dificultad
int xpForDifficulty(int difficulty) {
  switch (difficulty) {
    case 0: return 10; // D
    case 1: return 15; // C
    case 2: return 20; // B
    case 3: return 30; // A
    case 4: return 45; // S
    case 5: return 60; // SS
    case 6: return 80; // SSS
    default: return 20;
  }
}

/// Colores para el badge de dificultad
Color difficultyColor(int difficulty, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  switch (difficulty) {
    case 0: return scheme.secondaryContainer; // D
    case 1: return scheme.tertiaryContainer;  // C
    case 2: return scheme.surfaceTint.withOpacity(.25); // B
    case 3: return Colors.amber.shade400;     // A
    case 4: return Colors.orange.shade500;    // S
    case 5: return Colors.red.shade400;       // SS
    case 6: return Colors.deepPurple.shade400; // SSS
    default: return scheme.secondaryContainer;
  }
}

/// ------------------------------ REGISTRO + PROGRESO COMPARTIDO ------------------------------

class SectionData {
  final String name;            // Apartado
  final List<String> labels;    // Subapartados (9)
  final List<double> values0to100; // Valores iniciales 0..100 (para convertir a niveles)

  const SectionData({
    required this.name,
    required this.labels,
    required this.values0to100,
  });
}

class SectionRegistry {
  static SectionData? byName(String name) {
    try {
      return sections.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  static final sections = <SectionData>[
    SectionData(
      name: 'Social Skills',
      labels: [
        'Escucha Activa','Storytelling','Humor','Asertividad','Lenguaje Corporal',
        'Networking','Conversaciones\ndifíciles','Empatía','Iniciativa Social'
      ],
      values0to100: [60,55,45,50,62,48,40,58,52],
    ),
    SectionData(
      name: 'Mental Health',
      labels: [
        'Gestión de Estrés','Resiliencia','Autoconocimiento','Optimismo','Autoestima',
        'Equilibrio\ntrabajo/ocio','Apoyo Psicológico','Mindfulness','Hábitos mentales'
      ],
      values0to100: [64,58,62,55,50,48,40,57,52],
    ),
    SectionData(
      name: 'Physical Health',
      labels: [
        'Fuerza','Resistencia\nCardio','Movilidad','Sueño','Nutrición',
        'Hábitos médicos','Descanso','Composición\nCorporal','Hábitos de\nEnergía'
      ],
      values0to100: [65,55,50,52,58,45,54,49,51],
    ),
    SectionData(
      name: 'Atractiveness',
      labels: [
        'Estilo','Higiene','Forma Física','Lenguaje\nCorporal','Carisma',
        'Autenticidad','Uso de Redes','Voz','Confianza'
      ],
      values0to100: [62,70,58,60,55,52,48,50,57],
    ),
    SectionData(
      name: 'Productivity',
      labels: [
        'Foco','Gestión de\nEnergía','Planificación','Cumplimiento\nde tareas',
        'No procrastinar','Descanso Activo','Adaptabilidad','Producción\n(Leverage)','Sistemas'
      ],
      values0to100: [56,58,60,52,48,50,55,57,54],
    ),
    SectionData(
      name: 'Finances',
      labels: [
        'Ingresos Activos','Ingresos Pasivos','Ahorro mensual','Inversión\nde Crec.',
        'Fondo de\nEmergencia','Gestión del\nGasto','Diversificación','Estabilidad\nFinanciera','Generosidad'
      ],
      values0to100: [50,40,55,52,45,48,42,47,30],
    ),
    SectionData(
      name: 'Relationships',
      labels: [
        'Vínculos\nfamiliares','Amistades\nprofundas','Red de Apoyo','Tiempo invertido',
        'Expresión\nemocional','Resolución de\nconflictos','Conexiones\nuevas','Generosidad','Relación en\npareja'
      ],
      values0to100: [60,55,52,48,46,50,44,58,40],
    ),
    SectionData(
      name: 'Knowledge',
      labels: [
        'Aprendizaje\nconstante','Pensamiento\nCrítico','Comprensión','Memoria Activa',
        'Aplicación\npráctica','Mentoría\nRecibida','Mentoría\nOfrecida','Curiosidad','Experiencia'
      ],
      values0to100: [62,58,55,50,56,40,42,60,53],
    ),
    SectionData(
      name: 'Spirituality',
      labels: [
        'Presencia','Coherencia\n(valores/acciones)','Compasión','Gratitud','Propósito/Sentido',
        'Autoconsciencia','Desapego','Comunidad','Naturaleza/\nSilencio'
      ],
      values0to100: [55,50,52,58,54,56,48,46,60],
    ),
  ];
}

/// Estado global de progreso (niveles 0..6) para Inicio (apartados) y cada Apartado (subapartados).
class ProgressRepo {
  ProgressRepo._() {
    // Apartados (Inicio): promedio de subapartados iniciales → nivel
    final cats = SectionRegistry.sections.map((s) {
      final avg = s.values0to100.reduce((a,b)=>a+b) / s.values0to100.length;
      return (avg / 100.0) * kMaxLevel;
    }).toList();
    homeLevels = ValueNotifier<List<double>>(cats);

    // Subapartados de cada sección
    for (final s in SectionRegistry.sections) {
      final lv = s.values0to100.map((v) => (v / 100.0) * kMaxLevel).toList();
      sectionLevels[s.name] = ValueNotifier<List<double>>(lv);
    }
  }

  static final ProgressRepo I = ProgressRepo._();

  late final ValueNotifier<List<double>> homeLevels; // por apartado (orden de sections)
  final Map<String, ValueNotifier<List<double>>> sectionLevels = {};

  int indexOfCategory(String categoryName) =>
      SectionRegistry.sections.indexWhere((s) => s.name == categoryName);

  /// Incrementa nivel de un apartado en Inicio.
  void bumpCategory(String categoryName, double delta) {
    final idx = indexOfCategory(categoryName);
    if (idx < 0) return;
    final l = List<double>.from(homeLevels.value);
    l[idx] = (l[idx] + delta).clamp(0, kMaxLevel);
    homeLevels.value = l;
  }

  /// Incrementa nivel de un subapartado y recalcula el promedio para Inicio.
  void bumpSubcategory(String categoryName, String subcategory, double delta) {
    final vn = sectionLevels[categoryName];
    if (vn == null) return;
    final section = SectionRegistry.byName(categoryName)!;
    final i = section.labels.indexOf(subcategory);
    if (i < 0) return;

    final list = List<double>.from(vn.value);
    list[i] = (list[i] + delta).clamp(0, kMaxLevel);
    vn.value = list;

    // Recalcular promedio y reflejar en Inicio
    final avg = list.reduce((a,b)=>a+b) / list.length;
    final idxCat = indexOfCategory(categoryName);
    final cats = List<double>.from(homeLevels.value);
    cats[idxCat] = avg.clamp(0, kMaxLevel);
    homeLevels.value = cats;
  }
}

/// ------------------------------ MODELOS DE MISIÓN ------------------------------

class Mission {
  final String id;
  final String category;      // Apartado
  String subcategory;         // Subapartado
  int xp;
  int difficulty;             // 0..6  ⇔  D..SSS
  String title;
  String description;
  final bool isUserCreated;
  bool completed;

  Mission({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.xp,
    required this.difficulty,
    required this.title,
    this.description = '',
    this.isUserCreated = false,
    this.completed = false,
  });
}

class UserMission extends Mission {
  UserMission({
    required super.id,
    required super.category,
    required super.subcategory,
    required super.xp,
    required super.difficulty,
    required super.title,
    super.description = '',
  }) : super(isUserCreated: true);
}

/// ------------------------------ DIÁLOGOS / OVERLAY ------------------------------

Future<bool> confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar misión'),
      content: const Text('¿Seguro que quieres eliminar esta misión?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí')),
      ],
    ),
  );
  return result ?? false;
}

Future<void> editUserMissionDialog(
  BuildContext context,
  UserMission m,
  List<String> possibleSubcats,
) async {
  final titleCtl = TextEditingController(text: m.title);
  final descCtl = TextEditingController(text: m.description);
  final xpCtl = TextEditingController(text: '${m.xp}');
  String subcat = m.subcategory;
  int diff = m.difficulty;

  bool showUseSuggested = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
      return StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + viewInsets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Editar misión', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: subcat,
                decoration: const InputDecoration(labelText: 'Subapartado'),
                items: [for (final s in possibleSubcats) DropdownMenuItem(value: s, child: Text(s))],
                onChanged: (v) => subcat = v ?? subcat,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: diff,
                decoration: const InputDecoration(labelText: 'Dificultad'),
                items: [
                  for (int i = 0; i < kRanks.length; i++)
                    DropdownMenuItem(value: i, child: Text(kRanks[i])),
                ],
                onChanged: (v) {
                  setSt(() {
                    diff = v ?? diff;
                    showUseSuggested = true;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: xpCtl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'XP',
                  helperText: showUseSuggested ? 'Nueva dificultad: XP sugerido ${xpForDifficulty(diff)}' : null,
                  suffixIcon: showUseSuggested
                      ? TextButton(
                          onPressed: () {
                            xpCtl.text = '${xpForDifficulty(diff)}';
                            setSt(() => showUseSuggested = false);
                          },
                          child: const Text('Usar sugerido'),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  m.title = titleCtl.text.trim().isEmpty ? m.title : titleCtl.text.trim();
                  m.description = descCtl.text.trim();
                  m.subcategory = subcat;
                  m.difficulty = diff;
                  m.xp = int.tryParse(xpCtl.text.trim()) ?? m.xp;
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      });
    },
  );
}

Future<UserMission?> openCreateMissionFlow(
  BuildContext context, {
  SectionData? fixedSection,
}) async {
  return await showModalBottomSheet<UserMission?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final titleCtl = TextEditingController();
      final descCtl = TextEditingController();
      int difficulty = 2; // B por defecto
      final xpCtl = TextEditingController(text: '${xpForDifficulty(difficulty)}');

      String? category = fixedSection?.name ?? SectionRegistry.sections.first.name;
      List<String> subcats =
          fixedSection?.labels ?? SectionRegistry.byName(category!)!.labels;
      String? subcategory = subcats.first;

      return StatefulBuilder(builder: (ctx, setSt) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + viewInsets),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nueva misión', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (fixedSection == null) ...[
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Apartado'),
                    items: [
                      for (final s in SectionRegistry.sections)
                        DropdownMenuItem(value: s.name, child: Text(s.name)),
                    ],
                    onChanged: (v) {
                      setSt(() {
                        category = v!;
                        subcats = SectionRegistry.byName(category!)!.labels;
                        subcategory = subcats.first;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ] else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Apartado: ${fixedSection!.name}',
                        style: Theme.of(ctx).textTheme.bodyMedium),
                  ),
                DropdownButtonFormField<String>(
                  value: subcategory,
                  decoration: const InputDecoration(labelText: 'Subapartado'),
                  items: [for (final s in subcats) DropdownMenuItem(value: s, child: Text(s))],
                  onChanged: (v) => setSt(() => subcategory = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: difficulty,
                  decoration: const InputDecoration(labelText: 'Dificultad'),
                  items: [
                    for (int i = 0; i < kRanks.length; i++)
                      DropdownMenuItem(value: i, child: Text(kRanks[i])),
                  ],
                  onChanged: (v) {
                    setSt(() {
                      difficulty = v ?? difficulty;
                      xpCtl.text = '${xpForDifficulty(difficulty)}'; // autocompletar XP
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: xpCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'XP',
                    helperText: 'Se autocompleta según la dificultad (puedes modificarlo)',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (titleCtl.text.trim().isEmpty || subcategory == null) {
                            Navigator.pop(ctx, null);
                            return;
                          }
                          final secName = fixedSection?.name ?? category!;
                          final mission = UserMission(
                            id: 'u_${DateTime.now().millisecondsSinceEpoch}',
                            category: secName,
                            subcategory: subcategory!,
                            xp: int.tryParse(xpCtl.text.trim()) ?? xpForDifficulty(difficulty),
                            difficulty: difficulty,
                            title: titleCtl.text.trim(),
                            description: descCtl.text.trim(),
                          );
                          Navigator.pop(ctx, mission);
                        },
                        child: const Text('Crear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

/// Overlay pequeño/estético para “Misión Completada”
void showCompletionOverlay(BuildContext context, String text) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (_) => SafeArea(
      child: Align(
        alignment: const Alignment(0, -0.85),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 250),
          builder: (ctx, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.95 + 0.05 * t, child: child),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26, offset: Offset(0,4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 1400), () => entry.remove());
}

/// ------------------------------ ROOT + NAV ------------------------------

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  static const orderedSections = <String>[
    'Social Skills','Mental Health','Physical Health','Atractiveness',
    'Productivity','Finances','Relationships','Knowledge','Spirituality',
  ];

  void _openSectionsPanel() async {
    setState(() => _currentIndex = 1);
    final selectedName = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Apartados',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [for (final name in orderedSections)
                  ChoiceChip(label: Text(name), selected: false, onSelected: (_) => Navigator.pop(ctx, name)),
                ],
              ),
            ],
          ),
        );
      },
    );
    setState(() => _currentIndex = 0);
    if (selectedName != null) {
      final data = SectionRegistry.byName(selectedName);
      if (data != null) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatsSectionPage(section: data)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomePage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => i == 0 ? setState(() => _currentIndex = 0) : _openSectionsPanel(),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.dashboard_customize_outlined), selectedIcon: Icon(Icons.dashboard_customize), label: 'Apartados'),
        ],
      ),
    );
  }
}

/// ------------------------------ HOME (INICIO) ------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = SectionRegistry.sections.map((s) => s.name).toList();

  final List<Mission> missions = [
    Mission(
      id: 'm1', category: 'Social Skills', subcategory: 'Iniciativa Social', xp: 50,
      difficulty: 3, // A
      title: 'Hablar a 5 personas por la calle', description: 'Sal y conversa con 5 personas.'
    ),
    Mission(
      id: 'm2', category: 'Productivity', subcategory: 'Foco', xp: 20,
      difficulty: 2, // B
      title: 'Deep work 45 minutos', description: 'Concentración sin distracciones.'
    ),
    Mission(
      id: 'm3', category: 'Physical Health', subcategory: 'Fuerza', xp: 20,
      difficulty: 2, // B
      title: 'Entrenar 1h en el gimnasio'
    ),
  ];

  Future<void> _addUserMission() async {
    final um = await openCreateMissionFlow(context);
    if (um != null) setState(() => missions.insert(0, um));
  }

  Future<void> _handleComplete(Mission m) async {
    setState(() => m.completed = true);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => missions.removeWhere((x) => x.id == m.id));

    // Aumenta nivel del APARTADO (Inicio) según XP
    ProgressRepo.I.bumpCategory(m.category, m.xp * kXpToLevelFactor);

    showCompletionOverlay(context, 'Misión Completada (+${m.xp} XP)');
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width * 0.05;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUserMission,
        icon: const Icon(Icons.add),
        label: const Text('Nueva misión'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(left: padding, right: padding, bottom: 16),
          children: [
            const SizedBox(height: 8),
            Text('My Stats',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            // Radar de apartados (niveles 0..6)
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                height: 300,
                child: ValueListenableBuilder<List<double>>(
                  valueListenable: ProgressRepo.I.homeLevels,
                  builder: (_, levels, __) => RadarStatsCard(
                    labels: categories.map((c) {
                      final lv = levels[categories.indexOf(c)];
                      return '$c\n(${levelToRank(lv)})';
                    }).toList(),
                    values: levels,
                    maxValue: kMaxLevel,
                    levelsCount: kLevelsCount,
                    backgroundColor: Colors.black,
                    areaColor: const Color(0xFF9EF5E8).withOpacity(.6),
                    gridColor: Colors.white30,
                    labelColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Misions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            ...missions.map(
              (m) => MissionCard(
                mission: m,
                onEdit: (m is UserMission)
                    ? () async {
                        await editUserMissionDialog(context, m, SectionRegistry.byName(m.category)!.labels);
                        setState(() {});
                      }
                    : null,
                onDelete: () async {
                  final ok = await confirmDelete(context);
                  if (ok) setState(() => missions.removeWhere((x) => x.id == m.id));
                },
                onComplete: () => _handleComplete(m),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------ PÁGINA DE APARTADO ------------------------------

class StatsSectionPage extends StatefulWidget {
  const StatsSectionPage({super.key, required this.section});
  final SectionData section;

  @override
  State<StatsSectionPage> createState() => _StatsSectionPageState();
}

class _StatsSectionPageState extends State<StatsSectionPage> {
  late List<Mission> missions;

  ValueNotifier<List<double>> get subLevels => ProgressRepo.I.sectionLevels[widget.section.name]!;

  @override
  void initState() {
    super.initState();
    missions = [
      Mission(
        id: '${widget.section.name}_sys_1',
        category: widget.section.name,
        subcategory: widget.section.labels.first,
        xp: 30,
        difficulty: 2, // B
        title: 'Tarea relacionada con ${widget.section.labels.first}',
      ),
      UserMission(
        id: '${widget.section.name}_usr_1',
        category: widget.section.name,
        subcategory: widget.section.labels[1],
        xp: 20,
        difficulty: 3, // A
        title: 'Otra acción de ${widget.section.labels[1]}',
        description: 'Descripción ejemplo',
      ),
    ];
  }

  Future<void> _addUserMission() async {
    final um = await openCreateMissionFlow(context, fixedSection: widget.section);
    if (um != null) setState(() => missions.insert(0, um));
  }

  Future<void> _handleComplete(Mission m) async {
    setState(() => m.completed = true);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => missions.removeWhere((x) => x.id == m.id));

    // Aumenta nivel del SUBAPARTADO y sincroniza promedio al apartado de Inicio
    ProgressRepo.I.bumpSubcategory(m.category, m.subcategory, m.xp * kXpToLevelFactor);

    showCompletionOverlay(context, 'Misión Completada (+${m.xp} XP)');
  }

  void _openOtherSections() async {
    final others = SectionRegistry.sections.where((s) => s.name != widget.section.name).toList(growable: false);
    final selectedName = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Wrap(
          spacing: 8, runSpacing: 8,
          children: [for (final s in others) ChoiceChip(label: Text(s.name), selected: false, onSelected: (_) => Navigator.pop(ctx, s.name))],
        ),
      ),
    );
    if (selectedName != null) {
      final data = SectionRegistry.byName(selectedName);
      if (data != null && mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StatsSectionPage(section: data)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width * 0.05;

    return Scaffold(
      appBar: AppBar(title: Text(widget.section.name), scrolledUnderElevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUserMission, icon: const Icon(Icons.add), label: const Text('Nueva misión'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(left: padding, right: padding, bottom: 16),
          children: [
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                height: 300,
                child: ValueListenableBuilder<List<double>>(
                  valueListenable: subLevels,
                  builder: (_, levels, __) => RadarStatsCard(
                    labels: [
                      for (var i = 0; i < widget.section.labels.length; i++)
                        '${widget.section.labels[i]}\n(${levelToRank(levels[i])})'
                    ],
                    values: levels,
                    maxValue: kMaxLevel,
                    levelsCount: kLevelsCount,
                    backgroundColor: Colors.black,
                    areaColor: const Color(0xFF9EF5E8).withOpacity(.6),
                    gridColor: Colors.white30,
                    labelColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Misions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            ...missions.map(
              (m) => MissionCard(
                mission: m,
                onEdit: (m is UserMission)
                    ? () async {
                        await editUserMissionDialog(context, m, widget.section.labels);
                        setState(() {});
                      }
                    : null,
                onDelete: () async {
                  final ok = await confirmDelete(context);
                  if (ok) setState(() => missions.removeWhere((x) => x.id == m.id));
                },
                onComplete: () => _handleComplete(m),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) => i == 1 ? _openOtherSections() : null,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.star_border_rounded),
              selectedIcon: const Icon(Icons.star_rounded),
              label: widget.section.name),
          const NavigationDestination(
              icon: Icon(Icons.dashboard_customize_outlined),
              selectedIcon: Icon(Icons.dashboard_customize),
              label: 'Apartados'),
        ],
      ),
    );
  }
}

/// ------------------------------ CARD DE MISIÓN ------------------------------

class MissionCard extends StatefulWidget {
  const MissionCard({
    super.key,
    required this.mission,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
  });

  final Mission mission;
  final Future<void> Function()? onEdit; // null => no editable (sistema)
  final Future<void> Function() onDelete;
  final Future<void> Function() onComplete;

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> with SingleTickerProviderStateMixin {
  late bool checked;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    checked = widget.mission.completed;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween(begin: 1.0, end: 1.10).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool v) async {
    setState(() => checked = v);
    if (v) {
      await _ctrl.forward();
      await _ctrl.reverse();
      await widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;

    final titleStyle = TextStyle(
      fontWeight: FontWeight.w600,
      decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
      color: checked ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : null,
    );

    final subtitleStyle = TextStyle(
      decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
      color: checked ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6) : null,
    );

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: difficultyColor(m.difficulty, context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        kRanks[m.difficulty],
        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
      ),
    );

    return ScaleTransition(
      scale: _scale,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: ListTile(
          leading: Checkbox(
            value: checked,
            onChanged: (v) => _toggle(v ?? false),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            activeColor: Colors.green,
            checkColor: Colors.white,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  badge,
                  const SizedBox(width: 8),
                  Flexible(child: Text('${m.subcategory} - ${m.xp}XP', style: titleStyle)),
                ],
              ),
            ],
          ),
          subtitle: Text(m.title, style: subtitleStyle),
          trailing: _ThreeDotsMenu(
            canEdit: widget.onEdit != null,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          ),
        ),
      ),
    );
  }
}

class _ThreeDotsMenu extends StatelessWidget {
  const _ThreeDotsMenu({
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final bool canEdit;
  final Future<void> Function()? onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF7B61FF);
    return Container(
      height: 40, width: 40,
      decoration: BoxDecoration(color: purple.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
      child: PopupMenuButton<String>(
        tooltip: 'Options',
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (v) async {
          if (v == 'edit' && canEdit) {
            await onEdit?.call();
          } else if (v == 'delete') {
            final ok = await confirmDelete(context);
            if (ok) await onDelete();
          }
        },
        itemBuilder: (ctx) {
          final items = <PopupMenuEntry<String>>[];
          if (canEdit) items.add(const PopupMenuItem(value: 'edit', child: Text('Edit')));
          items.add(const PopupMenuItem(value: 'delete', child: Text('Delete')));
          return items;
        },
        icon: const Icon(Icons.more_vert, color: Colors.white),
      ),
    );
  }
}

/// ------------------------------ RADAR CHART (niveles) ------------------------------

class RadarStatsCard extends StatelessWidget {
  const RadarStatsCard({
    super.key,
    required this.labels,
    required this.values,
    required this.maxValue,
    this.levelsCount = 7,
    this.backgroundColor = Colors.black,
    this.areaColor = const Color(0xFF9EF5E8),
    this.gridColor = Colors.white30,
    this.labelColor = Colors.white,
  });

  final List<String> labels;       // ejes
  final List<double> values;       // niveles 0..maxValue
  final double maxValue;           // kMaxLevel
  final int levelsCount;           // anillos (7)
  final Color backgroundColor;
  final Color areaColor;
  final Color gridColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    assert(labels.length == values.length && labels.isNotEmpty);
    return Container(
      color: backgroundColor,
      child: CustomPaint(
        painter: _RadarPainter(
          labels: labels,
          values: values,
          maxValue: maxValue,
          levelsCount: levelsCount,
          areaColor: areaColor,
          gridColor: gridColor,
          labelColor: labelColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.labels,
    required this.values,
    required this.maxValue,
    required this.levelsCount,
    required this.areaColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<String> labels;
  final List<double> values; // 0..maxValue (niveles)
  final double maxValue;
  final int levelsCount;
  final Color areaColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.42;
    final angle = (2 * pi) / labels.length;

    // Grid
    final gridPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = gridColor;
    for (int l = 1; l <= levelsCount; l++) {
      final r = radius * (l / levelsCount);
      final path = Path();
      for (int i = 0; i < labels.length; i++) {
        final a = -pi / 2 + angle * i;
        final p = center + Offset(cos(a), sin(a)) * r;
        if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Ejes
    final axisPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = gridColor.withOpacity(0.8);
    for (int i = 0; i < labels.length; i++) {
      final a = -pi / 2 + angle * i;
      final p = center + Offset(cos(a), sin(a)) * radius;
      canvas.drawLine(center, p, axisPaint);
    }

    // Área
    final areaPath = Path();
    for (int i = 0; i < values.length; i++) {
      final v = (values[i].clamp(0, maxValue)) / maxValue;
      final a = -pi / 2 + angle * i;
      final p = center + Offset(cos(a), sin(a)) * (radius * v);
      if (i == 0) areaPath.moveTo(p.dx, p.dy); else areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.close();

    final fill = Paint()..style = PaintingStyle.fill..color = areaColor;
    final stroke = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = areaColor.withOpacity(0.9);
    canvas.drawPath(areaPath, fill);
    canvas.drawPath(areaPath, stroke);

    // Etiquetas
    for (int i = 0; i < labels.length; i++) {
      final a = -pi / 2 + angle * i;
      final p = center + Offset(cos(a), sin(a)) * (radius + 14);

      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(fontSize: 11, color: labelColor, height: 1.1, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr, maxLines: 3,
      )..layout(maxWidth: 120);

      final dx = p.dx - tp.width / 2;
      final dy = p.dy - tp.height / 2;
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) {
    return old.values != values || old.labels != labels || old.maxValue != maxValue ||
        old.areaColor != areaColor || old.gridColor != gridColor || old.labelColor != labelColor ||
        old.levelsCount != levelsCount;
  }
}
