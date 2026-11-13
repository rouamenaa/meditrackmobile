import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

const _kNavy = Color(0xFF0A2540);
const _kGreen = Color(0xFF0B6B5D);

/// Carte unifiée et compacte « Weather-Based Sports Recommendations »
/// Combine les conditions météo en temps réel (Open-Meteo) et les recommandations sportives adaptées.
class WeatherSportCard extends StatefulWidget {
  final VoidCallback? onOpenRecommendations;

  const WeatherSportCard({super.key, this.onOpenRecommendations});

  @override
  State<WeatherSportCard> createState() => _WeatherSportCardState();
}

class _WeatherSportCardState extends State<WeatherSportCard> {
  final _weatherService = WeatherService.instance;
  WeatherData? _weather;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWeather(forceRefresh: false);
  }

  Future<void> _fetchWeather({required bool forceRefresh}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
          await _weatherService.getCurrentWeather(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _weather = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Weather currently unavailable';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne fine décorative supérieure
            Container(
              height: 3.5,
              color: _weather?.isOutdoorFriendly == true
                  ? const Color(0xFF10B981) // Émeraude (Outdoor)
                  : const Color(0xFFF59E0B), // Ambre (Indoor)
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildContent(_weather!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kGreen,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading weather & recommendations...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? 'Weather unavailable',
              style: const TextStyle(color: Colors.grey, fontSize: 12.5),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: _kNavy),
            tooltip: 'Retry',
            onPressed: () => _fetchWeather(forceRefresh: true),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(WeatherData weather) {
    final isOutdoor = weather.isOutdoorFriendly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre unifié de la carte + Bouton Refresh
        Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 16, color: _kGreen),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Weather-Based Sports Recommendations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kNavy,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _fetchWeather(forceRefresh: true),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 17,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 1. En-tête météo (Icône, Température, Description, Badge Outdoor/Indoor)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: weather.weatherColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                weather.weatherIcon,
                color: weather.weatherColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${weather.temperature.round()}°C',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      weather.weatherDescription,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Indicateur Outdoor ou Indoor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: isOutdoor
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOutdoor
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOutdoor
                        ? Icons.nature_people_rounded
                        : Icons.home_rounded,
                    size: 13,
                    color: isOutdoor
                        ? const Color(0xFF047857)
                        : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOutdoor ? 'Outdoor' : 'Indoor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOutdoor
                          ? const Color(0xFF047857)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 2. Recommandation principale avec raison d'être
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: _kGreen,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      weather.primarySportRecommendation,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _kNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                weather.weatherSportAdvice,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 3. Activités suggérées (Tags) + Lien vers toutes les suggestions
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 5,
                runSpacing: 4,
                children: weather.recommendedSports.map((sport) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _kGreen.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      sport,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kGreen,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (widget.onOpenRecommendations != null) ...[
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: widget.onOpenRecommendations,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _kGreen,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: _kGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
