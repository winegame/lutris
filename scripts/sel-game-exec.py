#!/usr/bin/env python3
import os
import glob
from pathlib import Path
import sqlite3
import subprocess
import sys
import yaml
from gi.repository import GLib


def path_exists(path, check_symlinks=False, exclude_empty=False):
    """Wrapper around system.path_exists that doesn't crash with empty values

    Params:
        path (str): File to the file to check
        check_symlinks (bool): If the path is a broken symlink, return False
        exclude_empty (bool): If true, consider 0 bytes files as non existing
    """
    if not path:
        return False
    if os.path.exists(path):
        if exclude_empty:
            return os.stat(path).st_size > 0
        return True
    if os.path.islink(path):
        print("%s is a broken link", path)
        return not check_symlinks
    return False


def read_yaml_from_file(filename):
    """Read filename and return parsed yaml"""
    if not path_exists(filename):
        return {}

    with open(filename, "r", encoding='utf-8') as yaml_file:
        try:
            yaml_content = yaml.safe_load(yaml_file) or {}
        except (yaml.scanner.ScannerError, yaml.parser.ParserError):
            print("error parsing file %s", filename)
            yaml_content = {}

    return yaml_content


def read_all_game_yaml(game_dir):
    ret = glob.glob(os.path.join(game_dir, '*.yml'))
    for k, path in enumerate(ret):
        ret[k] = read_yaml_from_file(path)
    return ret


def read_game_info_from_db(db):
    conn = sqlite3.connect(db)
    c = conn.cursor()
    cursor = c.execute("SELECT name, directory, configpath FROM games WHERE runner='wine'")
    ret = cursor.fetchall()
    conn.close()
    return ret


CONFIG_DIR = os.path.join(GLib.get_user_config_dir(), "net.winegame.client")
WINE_YAML = os.path.join(CONFIG_DIR, "runners", "wine.yml")
GAME_DIR = os.path.join(CONFIG_DIR, "games")
DATA_DIR = os.path.join(GLib.get_user_data_dir(), "net.winegame.client")
PGA_DB = os.path.join(DATA_DIR, "pga.db")
WINE_DIR = os.path.join(DATA_DIR, "runners", "wine")


games = []
try:
    games = read_game_info_from_db(PGA_DB)
except Exception as e:
    subprocess.run(['zenity', '--width=200', '--error', "--text=游戏信息数据库打开失败：\n" + str(e)])
    exit()

args = ['zenity', '--width=800', '--height=600', '--list',
        '--title=选择游戏', '--column=序号', '--column=名称', '--column=位置']
for index, game in enumerate(games):
    args.append(str(index + 1))
    args.append(game[0])
    args.append(game[1])

# 选择游戏
print('选择游戏...')
text = ''
while True:
    try:
        text = subprocess.check_output(args).strip()
        if len(text) > 0:
            break
    except:
        print('未选择游戏')
        exit()

game = games[int(text) - 1]
print('选择的游戏：', game)

# 读取YAML
wine_yaml = read_yaml_from_file(WINE_YAML)
game_yaml = read_yaml_from_file(os.path.join(GAME_DIR, game[2] + '.yml'))

prefix = game[1]
esync = True
fsync = False
version = ''
wine_path = ''

try:
    prefix = game_yaml['game']['prefix']
except:
    pass
if len(prefix) < 1:
    prefix = os.path.join(Path.home(), '.wine')

try:
    version = wine_yaml['wine']['version']
    if version == 'custom':
        wine_path = wine_yaml['wine']['custom_wine_path']
except:
    pass
try:
    version = game_yaml['wine']['version']
    if version == 'custom':
        wine_path = game_yaml['wine']['custom_wine_path']
except:
    pass
if len(version) < 1:
    version = 'lutris-fshack-7.2-x86_64'
if len(wine_path) < 1:
    wine_path = os.path.join(WINE_DIR, version, 'bin', 'wine')

try:
    esync = wine_yaml['wine']['esync']
except:
    pass
try:
    esync = game_yaml['wine']['esync']
except:
    pass

try:
    fsync = wine_yaml['wine']['fsync']
except:
    pass
try:
    fsync = game_yaml['wine']['fsync']
except:
    pass

print('Wine容器：', prefix)
print('Wine路径：', wine_path)

envs = os.environ
envs['WINEPREFIX'] = prefix
envs['WINEDLLOVERRIDES'] = 'winedbg.exe='
if esync:
    envs['WINEESYNC'] = '1'
if fsync:
    envs['WINEFSYNC'] = '1'

args = sys.argv
args[0] = wine_path
print('启动命令：', args)

os.execve(wine_path, args, envs)
