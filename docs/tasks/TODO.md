# HomePage Restructuring Tasks

## Current Issues
- [ ] Multiple duplicate method definitions (_ensureSignedIn, _loadNextPage, _rebuildMarkers, etc.)
- [ ] Incomplete class structures and unmatched braces
- [ ] Code fragments outside the HomePage class
- [ ] Missing state variable declarations
- [ ] Syntax errors and incomplete code blocks

## Plan
- [ ] Declare all necessary state variables at the top of _HomePageState
- [ ] Remove all duplicate method definitions, keeping only the most complete versions
- [ ] Properly close the HomePage class
- [ ] Ensure PostCard widget is separate and complete
- [ ] Fix any syntax errors and unmatched braces
- [ ] Verify all referenced variables and methods are defined

## State Variables Needed
- [ ] Location and map related: _currentPos, _currentZoom, _mapController, _lastSearchBounds, _showSearchAreaButton
- [ ] Posts data: _postResults, _visiblePostResults, _postsLastDoc, _postsHasMore, _postsPageSize
- [ ] UI state: _loading, _activePostId, _expandedCardId, _currentCarouselPage
- [ ] Filters: _selectedLevel, _selectedInstruments, _selectedGenres, _maxDistanceKm
- [ ] Clustering: _useClustering, _clusterManager, _visibleClusterItems
- [ ] Markers: _markers, _markerCache
- [ ] Carousel: _carouselController
- [ ] Profile: _activeProfile
- [ ] Interests: _sentInterests

## Methods to Consolidate
- [ ] _ensureSignedIn (keep the anonymous sign-in version)
- [ ] _loadNextPagePosts (consolidate from various versions)
- [ ] _rebuildMarkers (keep the most complete version with clustering)
- [ ] _buildMapView (keep the version with clustering support)
- [ ] _buildFloatingCarousel (keep the version with PostCard)
- [ ] _onMapIdle, _searchThisArea, _centerMapOnPosts
- [ ] _showMarkerOptionsSheet, _showInterestDialog, _sendInterestOptimistically
- [ ] _showFiltersDialog
- [ ] Helper methods: _distanceKm, _deg2rad, _boundsEqual, _latLngInBounds, _isMyProfile

## Post-Edit Verification
- [ ] Run Flutter analyze to check for syntax errors
- [ ] Test the app to ensure HomePage loads correctly
- [ ] Verify map, carousel, and marker functionality
