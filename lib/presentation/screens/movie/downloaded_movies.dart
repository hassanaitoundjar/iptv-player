part of '../screens.dart';

class DownloadedMoviesScreen extends StatefulWidget {
  const DownloadedMoviesScreen({super.key});

  @override
  State<DownloadedMoviesScreen> createState() => _DownloadedMoviesScreenState();
}

class _DownloadedMoviesScreenState extends State<DownloadedMoviesScreen> {
  late Future<List<MovieDownload>> _downloadedMoviesFuture;

  @override
  void initState() {
    super.initState();
    _loadDownloadedMovies();
  }

  void _loadDownloadedMovies() {
    _downloadedMoviesFuture = DownloadService.getDownloadedMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Movies'),
        backgroundColor: kColorPrimaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadDownloadedMovies();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: kDecorBackground,
        child: FutureBuilder<List<MovieDownload>>(
          future: _downloadedMoviesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading downloaded movies: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final downloadedMovies = snapshot.data ?? [];

            if (downloadedMovies.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      FontAwesomeIcons.film,
                      color: Colors.white54,
                      size: 70,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Downloaded Movies',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your downloaded movies will appear here',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kColorPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        Get.to(() => const MovieCategoriesScreen());
                      },
                      child: const Text('Browse Movies'),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: downloadedMovies.length,
              itemBuilder: (context, index) {
                final movie = downloadedMovies[index];
                return _buildMovieCard(movie);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMovieCard(MovieDownload movie) {
    return GestureDetector(
      onTap: () {
        _showMovieOptions(movie);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    movie.posterUrl.isNotEmpty
                        ? Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.movie,
                                  color: Colors.white54,
                                  size: 50,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white54,
                              size: 50,
                            ),
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: kColorPrimary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              FontAwesomeIcons.download,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatFileSize(movie.fileSize),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Downloaded: ${_formatDate(movie.downloadDate)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovieOptions(MovieDownload movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(movie.title),
        content: const Text('What would you like to do with this movie?'),
        actions: [
          TextButton(
            child: const Text('Play'),
            onPressed: () {
              Navigator.pop(context);
              Get.to(() => FullVideoScreen(
                    link: movie.filePath,
                    title: movie.title,
                    isLive: false,
                    isLocalFile: true,
                  ));
            },
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.pop(context);
              await DownloadService.removeDownloadedMovie(movie.movieId);
              setState(() {
                _loadDownloadedMovies();
              });
              Get.snackbar(
                'Movie Deleted',
                '${movie.title} has been removed from your downloads',
                backgroundColor: Colors.red.withOpacity(0.7),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
