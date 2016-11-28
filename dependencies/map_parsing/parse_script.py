import time
start = time.time()

mapFile = 'map.osm'

import interOSM
writeFile = 'intersections.txt'
f = open(writeFile, 'w')
ic = interOSM.get_intersections(mapFile, 'file')
for coord in ic:
	f.write(coord + '\n')
f.close()


import allWayNodes
writeFile = 'allNodes.txt'
f = open(writeFile, 'w')
nc = allWayNodes.allWayNodes(mapFile, 'file')
for coord in nc:
	f.write(coord + '\n')
f.close()

print 'It took', time.time()-start, 'seconds to parse the OSM map.'
