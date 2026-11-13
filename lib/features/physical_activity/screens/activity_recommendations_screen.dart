import 'package:flutter/material.dart';
import '../../auth/models/user.dart';
import '../../auth/services/session.dart';
import '../models/activity_recommendation.dart';
import '../models/physical_activity.dart';
import '../models/weather_data.dart';
import '../services/activity_recommendation_service.dart';
import '../services/activity_service.dart';
import '../services/weather_service.dart';
import 'activity_form_screen.dart';

/// Écran moderne des Recommandations Personnalisées d'Activité Physique
class ActivityRecommendationsScreen extends StatefulWidget {
  final User? user;

  const ActivityRecommendationsScreen({super.key, this.user});

  @override
  State<ActivityRecommendationsScreen> createState() =>
      _ActivityRecommendationsScreenState();
}

class _ActivityRecommendationsScreenState
    extends State<ActivityRecommendationsScreen> {
  final ActivityService _activityService = ActivityService();
  final ActivityRecommendationService _recommendationService =
      ActivityRecommendationService.instance;

  bool _loading = true;
  User? _currentUser;
  List<PhysicalActivity> _history = [];
  ActivityWeeklySummary _weeklySummary = const ActivityWeeklySummary(
    totalMinutes: 0,
    totalCalories: 0,
    totalDistanceKm: 0,
    sessionCount: 0,
  );
  List<ActivityRecommendation> _recommendations = [];
  List<String> _healthTips = [];
  WeatherData? _weather;

  String? get _effectiveUserId =>
      widget.user?.id ?? Session.instance.user?.id;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final user = widget.user ?? Session.instance.user;
    final history = await _activityService.getAll(userId: _effectiveUserId);
    final summary =
        await _activityService.getWeeklySummary(userId: _effectiveUserId);
    final tips = await _recommendationService.fetchExternalHealthTips();
    final weather = await WeatherService.instance.getCurrentWeather();

    final recs = _recommendationService.generateRecommendations(
      user: user,
      history: history,
      summary: summary,
    );

    final weatherRec = _recommendationService.generateWeatherRecommendation(
      weather: weather,
      user: user,
    );

    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _history = history;
      _weeklySummary = summary;
      _weather = weather;
      _recommendations = [weatherRec, ...recs];
      _healthTips = tips;
      _loading = false;
    });
  }

  Future<void> _startRecommendation(ActivityRecommendation rec) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(
          userId: _effectiveUserId,
          initialType: rec.activityType,
          initialDuration: rec.durationMinutes,
          initialIntensity: rec.intensity,
          initialNotes: 'Session based on recommendation: "${rec.title}"',
        ),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session "${rec.title}" saved successfully!'),
          backgroundColor: const Color(0xFF00685D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Actualise immédiatement les recommandations selon la nouvelle séance
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimary = Color(0xFF0B6B5D);
    const kTextPrimary = Color(0xFF0A2540);
    const kSurface = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: const Text(
          'Workout Recommendations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kTextPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kPrimary),
            tooltip: 'Refresh recommendations',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // 1. Carte Profil Santé & Progression OMS
                  _buildPatientProfileCard(),

                  const SizedBox(height: 16),

                  // 2. Avertissement Déontologique Médical Formel
                  _buildMedicalDisclaimerBanner(),

                  const SizedBox(height: 20),

                  // 3. Titre de la section Recommandations
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: kPrimary, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recommended activities',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      if (_weather != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_weather!.weatherIcon,
                                  size: 13, color: const Color(0xFF1D4ED8)),
                              const SizedBox(width: 4),
                              Text(
                                '${_weather!.temperature.round()}°C',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${_recommendations.length} items',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 4. Cartes des Recommandations
                  ..._recommendations.map((rec) => _buildRecommendationCard(rec)),

                  const SizedBox(height: 20),

                  // 5. Section Conseils & Motivation (API externe & Hygiène de vie)
                  if (_healthTips.isNotEmpty) _buildHealthTipsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildPatientProfileCard() {
    const kPrimary = Color(0xFF0B6B5D);
    const kTextPrimary = Color(0xFF0A2540);

    final user = _currentUser;
    final ageLabel = user?.age != null ? '${user!.age} yrs' : 'Not specified';
    final genderLabel = user?.sexe ?? 'Not specified';
    final condition = user?.conditionMedicale;
    final hasCondition = condition != null && condition.trim().isNotEmpty;

    final progress = _weeklySummary.goalProgress;
    final totalMin = _weeklySummary.totalMinutes;
    final goalMin = _weeklySummary.weeklyGoalMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: kPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? '${user.prenom} ${user.nom}' : 'MediTrack Patient',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time analyzed health profile',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_history.length} total workouts',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Attributs réels du patient (sans données inventées)
          Row(
            children: [
              _buildProfilePill(Icons.cake_outlined, 'Age', ageLabel),
              const SizedBox(width: 8),
              _buildProfilePill(Icons.transgender_rounded, 'Sex', genderLabel),
              const SizedBox(width: 8),
              _buildProfilePill(
                Icons.medical_information_outlined,
                'Condition',
                hasCondition ? condition : 'None',
                isHighlight: hasCondition,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progression de la semaine vers l'objectif OMS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current weekly volume:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              Text(
                '$totalMin min / $goalMin min (${(progress * 100).toInt()}%)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePill(IconData icon, String label, String value,
      {bool isHighlight = false}) {
    const kTextPrimary = Color(0xFF1D3557);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlight
              ? Colors.amber.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight ? Colors.amber.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 13,
                    color: isHighlight ? Colors.orange.shade800 : Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.orange.shade900 : kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D7FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: Color(0xFF1D4ED8), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medical Guidance & Safety',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'These suggestions are based on WHO physical activity guidelines. They do not constitute a medical prescription. If you have an underlying medical condition or ongoing treatment, always consult your physician.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.blue.shade900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(ActivityRecommendation rec) {
    const kPrimary = Color(0xFF0B6B5D);
    const kTextPrimary = Color(0xFF0A2540);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : Catégorie, Badge météo & Badge d'intensité
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rec.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ),
                if (rec.source == 'Open-Meteo Weather Advisor')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wb_sunny_rounded,
                            size: 11, color: Color(0xFFB45309)),
                        SizedBox(width: 3),
                        Text(
                          'Weather Matched',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: rec.intensityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: rec.intensityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${rec.intensityLabel} Intensity',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rec.intensityColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Ligne 2 : Icône, Titre et type
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(rec.icon, color: kPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Activity: ${rec.typeLabel}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ligne 3 : Métriques recommandées (Durée, Fréquence, Calories)
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildMetricChip(
                  icon: Icons.timer_outlined,
                  text: '${rec.durationMinutes} min recommended',
                  color: kPrimary,
                ),
                _buildMetricChip(
                  icon: Icons.repeat_rounded,
                  text: '${rec.frequencyPerWeek}x / week',
                  color: const Color(0xFF0058BD),
                ),
                _buildMetricChip(
                  icon: Icons.local_fire_department_outlined,
                  text: '~${rec.estimatedCalories} kcal',
                  color: Colors.deepOrange,
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Ligne 4 : Justification personnalisée
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.psychology_outlined,
                    size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec.reason,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade800,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Ligne 5 : Conseils pratiques de réalisation
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec.description,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            // Ligne 6 : Mise en garde médicale si besoin
            if (rec.medicalAdvice != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rec.medicalAdvice!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Bouton Commencer / Planifier cette séance
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _startRecommendation(rec),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text(
                  'Start this activity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsCard() {
    const kPrimary = Color(0xFF0B6B5D);
    const kTextPrimary = Color(0xFF0A2540);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Health Tips & Best Practices',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._healthTips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
