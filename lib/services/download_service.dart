import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MovieDownload {
  final String movieId;
  final String title;
  final String posterUrl;
  final String filePath;
  final DateTime downloadDate;
  final int fileSize; // in bytes

  MovieDownload({
    required this.movieId,
    required this.title,
    required this.posterUrl,
    required this.filePath,
    required this.downloadDate,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'title': title,
      'posterUrl': posterUrl,
      'filePath': filePath,
      'downloadDate': downloadDate.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  factory MovieDownload.fromJson(Map<String, dynamic> json) {
    return MovieDownload(
      movieId: json['movieId'],
      title: json['title'],
      posterUrl: json['posterUrl'],
      filePath: json['filePath'],
      downloadDate: DateTime.parse(json['downloadDate']),
      fileSize: json['fileSize'],
    );
  }
}

class DownloadService {
  static const String _prefsKey = 'downloaded_movies';
  
  // Get all downloaded movies
  static Future<List<MovieDownload>> getDownloadedMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? moviesJson = prefs.getStringList(_prefsKey);
    
    if (moviesJson == null) {
      return [];
    }
    
    return moviesJson
        .map((json) => MovieDownload.fromJson(jsonDecode(json)))
        .toList();
  }
  
  // Check if a movie is already downloaded
  static Future<bool> isMovieDownloaded(String movieId) async {
    final movies = await getDownloadedMovies();
    return movies.any((movie) => movie.movieId == movieId);
  }
  
  // Get a specific downloaded movie
  static Future<MovieDownload?> getDownloadedMovie(String movieId) async {
    final movies = await getDownloadedMovies();
    try {
      return movies.firstWhere((movie) => movie.movieId == movieId);
    } catch (e) {
      return null;
    }
  }
  
  // Save downloaded movie info
  static Future<void> saveDownloadedMovie(MovieDownload movie) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> moviesJson = prefs.getStringList(_prefsKey) ?? [];
    
    // Remove if already exists (to update)
    final existingIndex = moviesJson.indexWhere((json) {
      final existing = MovieDownload.fromJson(jsonDecode(json));
      return existing.movieId == movie.movieId;
    });
    
    if (existingIndex >= 0) {
      moviesJson.removeAt(existingIndex);
    }
    
    // Add the new movie
    moviesJson.add(jsonEncode(movie.toJson()));
    
    // Save back to prefs
    await prefs.setStringList(_prefsKey, moviesJson);
  }
  
  // Remove a downloaded movie
  static Future<void> removeDownloadedMovie(String movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> moviesJson = prefs.getStringList(_prefsKey) ?? [];
    
    // Find and remove the movie
    final newList = moviesJson.where((json) {
      final movie = MovieDownload.fromJson(jsonDecode(json));
      return movie.movieId != movieId;
    }).toList();
    
    // Delete the actual file
    final movie = await getDownloadedMovie(movieId);
    if (movie != null) {
      final file = File(movie.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    // Save back to prefs
    await prefs.setStringList(_prefsKey, newList);
  }
  
  // Download a movie
  static Future<MovieDownload?> downloadMovie({
    required String movieId,
    required String title,
    required String posterUrl,
    required String downloadUrl,
  }) async {
    try {
      // Get the documents directory for storing the movie
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/movies/$movieId.mp4';
      
      // Create the directory if it doesn't exist
      final fileDirectory = Directory('${directory.path}/movies');
      if (!await fileDirectory.exists()) {
        await fileDirectory.create(recursive: true);
      }
      
      // Download the file
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Create and save the movie download info
        final movieDownload = MovieDownload(
          movieId: movieId,
          title: title,
          posterUrl: posterUrl,
          filePath: filePath,
          downloadDate: DateTime.now(),
          fileSize: response.bodyBytes.length,
        );
        
        await saveDownloadedMovie(movieDownload);
        return movieDownload;
      } else {
        debugPrint('Failed to download movie: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading movie: $e');
      return null;
    }
  }
  
  // Get the file size in a human-readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
