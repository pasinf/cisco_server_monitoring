#!/usr/bin/python
'''
Nagios plugin for monitoring Cisco C series Servers
Uses XML API supporting script to monitor the events


Author : Prashanth Hari
Email  : prashanth_hari@cable.comcast.com


Revision History
~~~~~~~~
Initial Release Date:04-11-2013

Usage: check_ucs.py [options]

Options:
  -h, --help            show this help message and exit
  -H host, --host=host  Host to query against     Usage Options:
                        ./check_cisco_events [-H | --host] <host>
  -p port, --port=port  XML API Listening Port     Usage Options:
                        ./check_cisco_events [-p | --port] <port>
  -C classname, --class=classname
                        Use this option for filtering the class name from XML
                        API response     Usage Options:
                        ./check_cisco_events [-C | --class] <classname>
  -f fields, --fields=fields
                        Use this option for displaying result fields from XML
                        response     Usage Options:      ./check_cisco_events
                        [-f | --fields] <field1, field2, field3>
  -w warning, --warning=warning
                        Use this option for setting warning threshold
                        Usage Options:      ./check_cisco_events [-w |
                        --warning] <field1:text1, field2:text2>
  -c critical, --critical=critical
                        Use this option for setting critical threshold
                        Usage Options:      ./check_cisco_events [-c |
                        --critical] <field1:text1, field2:text2>
  -r records, --records=records
                        Number of records to filter     Usage Options:
                        ./check_cisco_events [-r | --records]

'''
import commands
import optparse
import sys


## Example - check_cisco_events -C faultInst -f created,rule,cause,severity,affectedDN,descr,dn -w prevSeverity:warning -c severity:major,severity:critical -r 1


#event = '''lastTransition: Wed Mar 13 17:38:13 2013,rule: fltMemoryUnitInoperable,highestSeverity: critical,origSeverity: warning,ack: yes,occur: 2,cause: equipmentInoperable,severity: major,code: F0185,affectedDN: sys/rack-unit-1/board/memarray-1/mem-7,prevSeverity: warning,descr: DIMM 7 is inoperable : Check or replace DIMM,tags: server,created: Wed Mar 13 17:38:13 2013,lc: flapping,type: server,dn: sys/rack-unit-1/fault-F0185,'''


exit_codes = {'OK':0,'WARNING':1,'CRITICAL':2,'UNKNOWN':3,'DEPENDENT':4}

USERNAME = "admin"       ## CIMC Username
PASSWORD = "password"    ## CIMC Password

parser=optparse.OptionParser()

parser.add_option(
    '-H','--host',
    dest='option_host',
    default=False,
    action="store",
    metavar='host',
    nargs=1,
    help='''Host to query against
    Usage Options: 
    ./check_cisco_events [-H | --host] <host>  '''
    )

parser.add_option(
    '-p','--port',
    dest='option_port',
    default=False,
    action="store",
    metavar='port',
    nargs=1,
    help='''XML API Listening Port
    Usage Options: 
    ./check_cisco_events [-p | --port] <port>  '''
    )


parser.add_option(
    '-C','--class',
    dest='option_class',
    default=False,
    action="store",
    metavar='classname',
    nargs=1,
    help='''Use this option for filtering the class name from XML API response
    Usage Options: 
    ./check_cisco_events [-C | --class] <classname>  '''
    )

parser.add_option(
    '-f','--fields',
    dest='option_fields',
    default=False,
    action="store",
    metavar='fields',
    nargs=1,
    help='''Use this option for displaying result fields from XML response
    Usage Options: 
    ./check_cisco_events [-f | --fields] <field1, field2, field3>'''  
    )


parser.add_option(
    '-w','--warning',
    dest='option_warning',
    default=False,
    action="store",
    metavar='warning',
    nargs=1,
    help='''Use this option for setting warning threshold
    Usage Options: 
    ./check_cisco_events [-w | --warning] <field1:text1, field2:text2>'''  
    )

parser.add_option(
    '-c','--critical',
    dest='option_critical',
    default=False,
    action="store",
    metavar='critical',
    nargs=1,
    help='''Use this option for setting critical threshold
    Usage Options: 
    ./check_cisco_events [-c | --critical] <field1:text1, field2:text2>'''  
    )

parser.add_option(
    '-r','--records',
    dest='option_records',
    default=False,
    action="store",
    metavar='records',
    nargs=1,
    help='''Number of records to filter
    Usage Options: 
    ./check_cisco_events [-r | --records] '''  
    )

options,args=parser.parse_args()


if len(sys.argv) == 1:
    print 'No options specified. For Help: ./ipdrtools.py -h | --help'
    parser.print_help()
    sys.exit(exit_codes['UNKNOWN'])


if not options.option_host or not options.option_port or not options.option_class or not options.option_warning or not options.option_critical or not options.option_records:
    print 'Missing some options. For Help: ./ipdrtools.py -h | --help'
    parser.print_help()



HOST = options.option_host
PORT = options.option_port
CLASS = options.option_class
FIELDS = []
WARNING = options.option_warning
CRITICAL = options.option_critical
RECORDS = options.option_records

tmp = WARNING.split(':')
warning_conditions = {}


for vals in WARNING.split(","):
    tmp = vals.split(':')
    warning_conditions = {}
    a = []
    if tmp[0].strip() in warning_conditions:
        tmp[1].strip()
        a = warning_conditions[tmp[0]]
        a.append(tmp[1])
        warning_conditions[tmp[0]] = a
    else:
        a.append(tmp[1].strip())
        warning_conditions[tmp[0].strip()] = a

for vals in CRITICAL.split(","):
    tmp = vals.split(':')
    critical_conditions = {}
    a = []
    if tmp[0].strip() in critical_conditions:
        tmp[1].strip()
        a = critical_conditions[tmp[0]]
        a.append(tmp[1])
        critical_conditions[tmp[0]] = a
    else:
        a.append(tmp[1].strip())
        critical_conditions[tmp[0].strip()] = a
    
    

if options.option_fields:
    a = options.option_fields.split(",")
    FIELDS = [x.strip(' ') for x in a]
else:
    FIELDS.append("FULL")

CMD = '''/usr/bin/perl cisco_monitor.pl --uname=%s --passwd=%s --server=%s  --port=%s --class=%s --filter=%s | head -%s''' % (USERNAME, PASSWORD, HOST, PORT, CLASS, options.option_fields, RECORDS)
try:
    commandOutput = commands.getoutput(CMD)
except Exception, e:
    print "There was an ERROR - %s" % e
    sys.exit(exit_codes['UNKNOWN'])

result_warning = False
result_critical = False


def is_int(a):
    """Returns true if a is an interger"""
    try:
        int (a)
        return True
    except:
        return False

def parseEvents():
    event_vals = {}
    for record in iter(commandOutput.splitlines()):
        record = record.rstrip(',')    
        vals = record.split(',')
        for items in vals:
            a = items.split(":")
            event_vals[a[0].strip()] = a[1].strip()
    return event_vals


def checkEvent(event_fields):
    global result_warning, result_critical
    '''check_cisco_events -C faultInst -f created,rule,cause,severity,affectedDN,descr,dn -w prevSeverity:warning -c severity:major,severity:critical -r 1'''
    if warning_conditions:
        for fields in warning_conditions:
            if fields in event_fields and event_fields[fields] in warning_conditions[fields]:
                result_warning = True
                break
    if critical_conditions:
        for fields in critical_conditions:
            if fields in event_fields and event_fields[fields] in critical_conditions[fields]:
                result_critical = True
                break

            
if __name__ == '__main__':
    events = parseEvents()
    checkEvent(events)
    result = ""
    for i in FIELDS:
            result = result + "%s:%s, " % (i, events[i])
    if result_critical:
        print "CRITICAL - %s" % result
        sys.exit(exit_codes['CRITICAL'])
    elif result_warning:
        print "WARNING - %s" % result
        sys.exit(exit_codes['WARNING'])
    else:
        print "OK - %s" % result
        sys.exit(exit_codes['OK'])

