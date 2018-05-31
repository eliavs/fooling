import sys
print(sys)
import logging
from polyglot.downloader import downloader
import polyglot
#print(downloader.supported_languages_table("ner2", 3))
print(polyglot.polyglot_path)
logging.basicConfig(filename='example.log',level=logging.DEBUG)
logging.debug(sys.version)
logging.debug(polyglot.polyglot_path)
logging.debug('This message should go to the log file')
def places(tab):
    from polyglot.text import Text
    places = []
    first_album = tab
    text_place = ''
    all_places = ''
    for place in first_album['word']:
        try:
            print(place)
            pl = Text(place).entities
            logging.debug(pl)
        except Exception as e:
           # print(e)
            logging.debug(e)
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
