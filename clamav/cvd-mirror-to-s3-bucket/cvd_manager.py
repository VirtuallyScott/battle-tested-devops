#!/usr/bin/env python3
"""
ClamAV Database Management Utility

A comprehensive utility script that provides a unified interface to all
ClamAV database management functions.
"""

import argparse
import sys
from pathlib import Path

# Import our individual modules
try:
    import update_databases
    import serve_mirror
    import config_manager
    import schedule_updates
except ImportError as e:
    print(f"Error importing modules: {e}")
    print("Make sure all script files are in the same directory")
    sys.exit(1)


def main():
    """Main function with unified command interface."""
    parser = argparse.ArgumentParser(
        description='ClamAV Database Management Utility',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s update                    # Update databases
  %(prog)s update -v                 # Update with verbose output
  %(prog)s serve                     # Start HTTP mirror server
  %(prog)s serve -p 9000             # Start server on port 9000
  %(prog)s config show               # Show current configuration
  %(prog)s config set-dbdir /path    # Set database directory
  %(prog)s schedule --interval 6     # Schedule updates every 6 hours
  %(prog)s schedule --cron           # Generate cron entry
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Update command
    update_parser = subparsers.add_parser('update', help='Update ClamAV databases')
    update_parser.add_argument('-v', '--verbose', action='store_true',
                              help='Enable verbose output')
    update_parser.add_argument('-l', '--list', action='store_true',
                              help='List current databases')
    update_parser.add_argument('-c', '--config', action='store_true',
                              help='Show current configuration')
    
    # Serve command
    serve_parser = subparsers.add_parser('serve', help='Start HTTP mirror server')
    serve_parser.add_argument('-p', '--port', type=int, default=8000,
                             help='Port to serve on (default: 8000)')
    serve_parser.add_argument('-v', '--verbose', action='store_true',
                             help='Enable verbose output')
    serve_parser.add_argument('--check', action='store_true',
                             help='Check database directory and exit')
    
    # Config command
    config_parser = subparsers.add_parser('config', help='Manage configuration')
    config_subparsers = config_parser.add_subparsers(dest='config_command')
    
    config_subparsers.add_parser('show', help='Show current configuration')
    
    dbdir_parser = config_subparsers.add_parser('set-dbdir', help='Set database directory')
    dbdir_parser.add_argument('directory', help='Database directory path')
    
    logdir_parser = config_subparsers.add_parser('set-logdir', help='Set log directory')
    logdir_parser.add_argument('directory', help='Log directory path')
    
    ns_parser = config_subparsers.add_parser('set-nameserver', help='Set DNS nameserver')
    ns_parser.add_argument('nameserver', help='DNS nameserver IP')
    
    add_parser = config_subparsers.add_parser('add-database', help='Add custom database')
    add_parser.add_argument('name', help='Database name (e.g., linux.cvd)')
    add_parser.add_argument('url', help='Database URL')
    
    config_subparsers.add_parser('list', help='List configured databases')
    config_subparsers.add_parser('backup', help='Backup configuration')
    
    config_parser.add_argument('-v', '--verbose', action='store_true',
                              help='Enable verbose output')
    
    # Schedule command
    schedule_parser = subparsers.add_parser('schedule', help='Schedule database updates')
    schedule_parser.add_argument('-i', '--interval', type=int, default=4,
                                help='Update interval in hours (default: 4)')
    schedule_parser.add_argument('-v', '--verbose', action='store_true',
                                help='Enable verbose output')
    schedule_parser.add_argument('--daemon', action='store_true',
                                help='Run as background daemon')
    schedule_parser.add_argument('--cron', action='store_true',
                                help='Generate cron entry and exit')
    schedule_parser.add_argument('--once', action='store_true',
                                help='Run update once and exit')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    # Route to appropriate module
    if args.command == 'update':
        # Call update_databases module
        sys.argv = ['update_databases.py']
        if args.verbose:
            sys.argv.append('-v')
        if args.list:
            sys.argv.append('-l')
        if args.config:
            sys.argv.append('-c')
        
        update_databases.main()
    
    elif args.command == 'serve':
        # Call serve_mirror module
        sys.argv = ['serve_mirror.py']
        if args.port != 8000:
            sys.argv.extend(['-p', str(args.port)])
        if args.verbose:
            sys.argv.append('-v')
        if args.check:
            sys.argv.append('--check')
        
        serve_mirror.main()
    
    elif args.command == 'config':
        # Call config_manager module
        sys.argv = ['config_manager.py']
        if args.verbose:
            sys.argv.append('-v')
        
        if args.config_command:
            sys.argv.append(args.config_command)
            
            # Add arguments based on subcommand
            if args.config_command == 'set-dbdir':
                sys.argv.append(args.directory)
            elif args.config_command == 'set-logdir':
                sys.argv.append(args.directory)
            elif args.config_command == 'set-nameserver':
                sys.argv.append(args.nameserver)
            elif args.config_command == 'add-database':
                sys.argv.extend([args.name, args.url])
        
        config_manager.main()
    
    elif args.command == 'schedule':
        # Call schedule_updates module
        sys.argv = ['schedule_updates.py']
        if args.interval != 4:
            sys.argv.extend(['-i', str(args.interval)])
        if args.verbose:
            sys.argv.append('-v')
        if args.daemon:
            sys.argv.append('--daemon')
        if args.cron:
            sys.argv.append('--cron')
        if args.once:
            sys.argv.append('--once')
        
        schedule_updates.main()


if __name__ == '__main__':
    main()