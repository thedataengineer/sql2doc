# Quick Start Guide

## Get Started in 3 Minutes

### 1. Setup (30 seconds)

```bash
# Already done! Environment is set up with:
pyenv virtualenv 3.12.11 sql2doc-env
pyenv local sql2doc-env
pip install -r requirements.txt
```

### 2. Run the Application (10 seconds)

```bash
streamlit run app.py
```

The app will open at `http://localhost:8501`

### 3. Connect to a Database (1 minute)

**Option A: Quick Test with SQLite**
```bash
# Create a test database
sqlite3 test.db "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT);"
sqlite3 test.db "INSERT INTO users VALUES (1, 'John Doe', 'john@example.com');"
```

In the Streamlit UI sidebar:
- Select "SQLite"
- Enter: `test.db`
- Click "Connect"

**Option B: PostgreSQL**
- Select "PostgreSQL"
- Host: `localhost`
- Port: `5432`
- Username: `your_username`
- Password: `your_password`
- Database: `your_database`
- Click "Connect"

**Option C: MySQL**
- Select "MySQL"
- Host: `localhost`
- Port: `3306`
- Username: `your_username`
- Password: `your_password`
- Database: `your_database`
- Click "Connect"

### 4. Generate Your First Data Dictionary (1 minute)

1. Go to "Data Dictionary" tab
2. Check "Include row counts" (optional)
3. Click "Generate Dictionary"
4. Browse your tables and columns!

### 5. Profile Your Data (1 minute)

1. Switch to "Table Profiling" tab
2. Select a table from dropdown
3. Click "Run Profiling"
4. View data quality metrics:
   - NULL values
   - Completeness score
   - Duplicate detection
   - Column statistics

### 6. Export Your Documentation

1. Go to "Export" tab
2. Choose format:
   - JSON for machine-readable
   - Markdown for human-readable docs
3. Click Download

## That's It!

You now have:
- ✅ Complete database documentation
- ✅ Data quality assessment
- ✅ Exportable documentation

## Common Use Cases

### Use Case 1: New Team Member Onboarding
```
1. Connect to company database
2. Generate data dictionary
3. Export to Markdown
4. Share with new team member
```

### Use Case 2: Data Quality Check
```
1. Connect to database
2. Profile all important tables
3. Review completeness scores
4. Identify tables with high NULL rates
5. Generate report for stakeholders
```

### Use Case 3: Database Migration Planning
```
1. Connect to source database
2. Generate complete dictionary
3. Export to JSON
4. Use for migration planning
5. Verify relationships and constraints
```

## Troubleshooting

**Can't connect to database?**
- Check database is running
- Verify credentials
- Check firewall/network access
- Try connection string format from README

**Slow performance?**
- Uncheck "Include row counts"
- Profile tables one at a time
- Check database has indexes

**Tests failing?**
```bash
pytest -v  # Run with verbose output
```

## Next Steps

- Read [README.md](README.md) for detailed usage
- Check [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) for architecture
- Review [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for overview

## Need Help?

Check the documentation:
- Connection examples in README.md
- Query examples in Custom Query tab
- Troubleshooting section in README.md

---

**Enjoy documenting your databases!** 📊🎉
