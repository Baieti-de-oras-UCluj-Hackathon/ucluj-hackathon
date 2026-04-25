import sqlite3
conn = sqlite3.connect('c:/Users/xrebe/OneDrive/Desktop/HackatonU/ucluj-hackathon/backend/umbraro.db')
cur = conn.cursor()

# Get users
cur.execute('SELECT email, full_name FROM users')
users = {u[0]: u[1] for u in cur.fetchall() if u[1]}

# Get messages
cur.execute('SELECT id, author_name FROM messages')
msgs = cur.fetchall()

updated = 0
for mid, author in msgs:
    if author in users:
        cur.execute('UPDATE messages SET author_name = ? WHERE id = ?', (users[author], mid))
        updated += 1

conn.commit()
conn.close()
print(f'Updated {updated} messages')
