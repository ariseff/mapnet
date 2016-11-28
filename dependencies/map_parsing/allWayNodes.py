def allWayNodes(osm, input_type='file'):
    """
    This method reads the passed osm file (xml) and extracts all highway nodes.

    (derived from a Stack Overflow post by Kotaro)
    """
    import xml.etree.ElementTree as ET
    node_coordinates = []
    if input_type == 'file':
        tree = ET.parse(osm)
        root = tree.getroot()
        children = root.getchildren()
    elif input_type == 'str':
        tree = ET.fromstring(osm)
        children = tree.getchildren()


    lat = {}
    lon = {}
    for child in children:
        if child.tag == 'way':
        # Check if the way represents a "highway (road)"
        # If the current way is not a road,
        # continue without checking any nodes
            road = False
            road_types = ('motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'residential', 'service')  # motorway_link 
            for item in child:
                if item.tag == 'tag' and item.attrib['k'] == 'highway' and item.attrib['v'] in road_types: 
                    road = True
                    road_type = item.attrib['v']
                    node_coordinates.append('     ') # blank line between ways
                    node_coordinates.append('way id: ' + child.attrib['id']) # delineate start of new "way" (previously [345,345])

            if not road:
                continue


            oneway = False
            speed = 'undefined'
            numLanes = 'undefined'
            cycleway = 'no'	    
            for item in child:  # must keep in order 
                # Add nodes
                if item.tag == 'nd':
                    nd_ref = item.attrib['ref']
                    coordinate = lat[nd_ref] + ',' + lon[nd_ref]
                    node_coordinates.append(coordinate)
                # Check oneway vs. twoway
                if item.tag == 'tag' and item.attrib['k'] == 'oneway' and item.attrib['v'] == 'yes':
                    oneway = True
                # Speed limit
                if item.tag == 'tag' and item.attrib['k'] == 'maxspeed':
                    speed_v = item.attrib['v']
                    speed_end = speed_v.find('mph')
                    if speed_end != -1:
			            speed = speed_v[0:speed_end-1]
                # Number of lanes
                if item.tag == 'tag' and item.attrib['k'] == 'lanes':
                    numLanes = item.attrib['v']
                # Bike path
                if item.tag == 'tag' and item.attrib['k'] == 'cycleway':
                    cycleway = item.attrib['v']


            if road_type == 'motorway':
                oneway = True
            if oneway:
                node_coordinates.append('oneway: true')
            else:
                node_coordinates.append('oneway: false')
            node_coordinates.append('road_type: ' + road_type)
            node_coordinates.append('speed: ' + speed)
            node_coordinates.append('lanes: ' + numLanes)
            node_coordinates.append('cycleway: ' + cycleway)



        elif child.tag == 'node':
        # store lat and lon coordinates
            nd_ref = child.attrib['id']
            lat[nd_ref] = child.attrib['lat']
            lon[nd_ref] = child.attrib['lon']


    return node_coordinates
