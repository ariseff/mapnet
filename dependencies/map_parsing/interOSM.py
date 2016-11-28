def get_intersections(osm, input_type='file'):
    """
    This method reads the passed osm file (xml) and finds intersections (i.e., nodes that are shared by two or more roads).

    (derived from a Stack Overflow post by Kotaro)
    """
    import xml.etree.ElementTree as ET
    intersection_coordinates = []
    if input_type == 'file':
        tree = ET.parse(osm)
        root = tree.getroot()
        children = root.getchildren()
    elif input_type == 'str':
        tree = ET.fromstring(osm)
        children = tree.getchildren()

    counter = {}
    interWays = {}
    for child in children:
        if child.tag == 'way':
            # Check if the way represents a "highway (road)"
            # If the current way is not a road,
            # continue without checking any nodes
            road = False
            road_types = ('motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'residential', 'service')  #  residential, service 
            for item in child:
                if item.tag == 'tag' and item.attrib['k'] == 'highway' and item.attrib['v'] in road_types: 
                    road = True

            if not road:
                continue

            for item in child:
                if item.tag == 'nd':
                    nd_ref = item.attrib['ref']
                    if not nd_ref in counter:
                        counter[nd_ref] = 0
                    counter[nd_ref] += 1

    # Find nodes that are shared with more than one way, which
    # might correspond to intersections
    intersections = filter(lambda x: counter[x] > 1,  counter) 


    # Extract intersection coordinates
    # You can plot the results using this url:
    # http://www.darrinward.com/lat-long/
    for child in children:
        if child.tag == 'node' and child.attrib['id'] in intersections:
            coordinate = child.attrib['lat'] + ',' + child.attrib['lon']
            intersection_coordinates.append(coordinate)
    return intersection_coordinates