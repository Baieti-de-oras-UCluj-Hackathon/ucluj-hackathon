import sqlite3
conn = sqlite3.connect('c:/Users/xrebe/OneDrive/Desktop/HackatonU/ucluj-hackathon/backend/umbraro.db')
cursor = conn.cursor()
cursor.execute("UPDATE users SET full_name = UPPER(email)")
conn.commit()
conn.close()
print("Updated users successfully")
