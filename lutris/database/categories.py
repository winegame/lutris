import re

from lutris import settings
from lutris.database import sql


def strip_category_name(name):
    """"This strips the name given, and also removes extra internal whitespace."""
    name = (name or "").strip()
    if not is_reserved_category(name):
        name = re.sub(' +', ' ', name)  # Remove excessive whitespaces
    return name


def is_reserved_category(name):
    """True of name is None, blank or is a name Lutris uses internally, or
    starts with '.' for future expansion."""
    return not name or name[0] == "." or name in ["all", "favorite"]


def get_categories():
    """Get the list of every category in database."""
    return sql.db_select(settings.PGA_DB, "categories", )


def get_category(name):
    """Return a category by name"""
    categories = sql.db_select(settings.PGA_DB, "categories", condition=("name", name))
    if categories:
        return categories[0]


def get_game_ids_for_category(category_name):
    """Get the ids of games in database."""
    query = (
        "SELECT game_id FROM games_categories "
        "JOIN categories ON categories.id = games_categories.category_id "
        "WHERE categories.name=?"
    )
    return [
        game["game_id"]
        for game in sql.db_query(settings.PGA_DB, query, (category_name,))
    ]


def get_categories_in_game(game_id):
    """Get the categories of a game in database."""
    query = (
        "SELECT categories.name FROM categories "
        "JOIN games_categories ON categories.id = games_categories.category_id "
        "JOIN games ON games.id = games_categories.game_id "
        "WHERE games.id=?"
    )
    return [
        category["name"]
        for category in sql.db_query(settings.PGA_DB, query, (game_id,))
    ]


def add_category(category_name):
    """Add a category to the database"""
    return sql.db_insert(settings.PGA_DB, "categories", {"name": category_name})


def add_game_to_category(game_id, category_id):
    """Add a category to a game"""
    return sql.db_insert(settings.PGA_DB, "games_categories", {"game_id": game_id, "category_id": category_id})


def remove_category_from_game(game_id, category_id):
    """Remove a category from a game"""
    query = "DELETE FROM games_categories WHERE category_id=? AND game_id=?"
    with sql.db_cursor(settings.PGA_DB) as cursor:
        sql.cursor_execute(cursor, query, (category_id, game_id))


def remove_unused_categories():
    """Remove all categories that have no games associated with them"""
    query = (
        "SELECT categories.* FROM categories "
        "LEFT JOIN games_categories ON categories.id = games_categories.category_id "
        "WHERE games_categories.category_id IS NULL"
    )

    empty_categories = sql.db_query(settings.PGA_DB, query)
    for category in empty_categories:
        if category['name'] == 'favorite':
            continue

        query = "DELETE FROM categories WHERE categories.id=?"
        with sql.db_cursor(settings.PGA_DB) as cursor:
            sql.cursor_execute(cursor, query, (category['id'],))
