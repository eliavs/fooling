def places(tab):
    from polyglot.text import Text
    places = []
    first_album = tab
    text_place = ''
    all_places = ''
    for place in first_album['word']:
        place + all_places
        try:
            pl = Text(place).entities
        except Exception as e:
            print(e)
            continue
        try:
            if pl[0].tag == 'I-LOC':
                places.append(pl[0])
                text_place = place + text_place
                print(pl[0])
        except Exception as e:
            #print(e)
            pass
    return type(places), places, all_places