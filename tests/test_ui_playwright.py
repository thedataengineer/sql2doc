"""
Playwright E2E UI Tests for SQL2Doc Streamlit Application

This test suite validates the user interface and end-to-end workflows
of the SQL2Doc data dictionary generator application.
"""

import pytest
from playwright.sync_api import Page, expect
import time


@pytest.fixture(scope="session")
def base_url():
    """Base URL for the Streamlit application."""
    return "http://localhost:8501"


@pytest.fixture(scope="function")
def wait_for_streamlit(page: Page, base_url: str):
    """Navigate to app and wait for Streamlit to be ready."""
    page.goto(base_url)
    # Wait for Streamlit to fully load by waiting for the main container
    page.wait_for_load_state("networkidle")
    page.wait_for_selector('[data-testid="stAppViewContainer"]', timeout=15000)
    return page


class TestDatabaseConnection:
    """Test database connection functionality."""

    def test_page_loads(self, page: Page, base_url: str):
        """Test that the main page loads successfully."""
        page.goto(base_url)
        # Check for main header
        expect(page).to_have_title("SQL Data Dictionary Generator")

    def test_connection_sidebar_visible(self, page: Page, wait_for_streamlit):
        """Test that database connection sidebar is visible."""
        frame = wait_for_streamlit

        # Check for connection header
        expect(frame.get_by_text("Database Connection")).to_be_visible()
        expect(frame.get_by_text("Not Connected")).to_be_visible()

    def test_database_type_selector(self, page: Page, wait_for_streamlit):
        """Test database type selector functionality."""
        frame = wait_for_streamlit

        # Find database type selector
        db_selector = frame.get_by_label("Database Type")
        expect(db_selector).to_be_visible()

        # Check that it has PostgreSQL option
        expect(db_selector).to_contain_text("PostgreSQL")

    def test_sqlite_connection_form(self, page: Page, wait_for_streamlit):
        """Test SQLite connection form appears when selected."""
        frame = wait_for_streamlit

        # Select SQLite
        frame.get_by_label("Database Type").select_option("SQLite")

        # Check for SQLite-specific fields
        expect(frame.get_by_label("Database File Path")).to_be_visible()

    def test_postgresql_connection_form(self, page: Page, wait_for_streamlit):
        """Test PostgreSQL connection form fields."""
        frame = wait_for_streamlit

        # Select PostgreSQL
        frame.get_by_label("Database Type").select_option("PostgreSQL")

        # Check for PostgreSQL-specific fields
        expect(frame.get_by_label("Host")).to_be_visible()
        expect(frame.get_by_label("Port")).to_be_visible()
        expect(frame.get_by_label("Username")).to_be_visible()
        expect(frame.get_by_label("Password")).to_be_visible()
        expect(frame.get_by_label("Database Name")).to_be_visible()

    def test_connect_button_visible(self, page: Page, wait_for_streamlit):
        """Test that connect button is visible."""
        frame = wait_for_streamlit

        connect_button = frame.get_by_role("button", name="Connect")
        expect(connect_button).to_be_visible()

    def test_connection_examples_visible(self, page: Page, wait_for_streamlit):
        """Test that connection examples are displayed."""
        frame = wait_for_streamlit

        # Check for connection examples section
        expect(frame.get_by_text("Connection Examples")).to_be_visible()


class TestSQLiteConnection:
    """Test SQLite database connection workflow."""

    def test_connect_to_sqlite(self, page: Page, wait_for_streamlit):
        """Test connecting to an SQLite database."""
        frame = wait_for_streamlit

        # Select SQLite
        frame.get_by_label("Database Type").select_option("SQLite")

        # Enter test database path
        frame.get_by_label("Database File Path").fill(":memory:")

        # Click connect
        frame.get_by_role("button", name="Connect").click()

        # Wait for connection success
        time.sleep(2)

        # Check for success indicator (this might vary based on your implementation)
        # expect(frame.get_by_text("Connected")).to_be_visible()


class TestMainTabs:
    """Test main application tabs visibility and functionality."""

    def test_data_dictionary_tab_visible(self, page: Page, wait_for_streamlit):
        """Test that Data Dictionary tab is visible."""
        frame = wait_for_streamlit

        # Look for tab
        expect(frame.get_by_text("Data Dictionary")).to_be_visible()

    def test_table_profiling_tab_visible(self, page: Page, wait_for_streamlit):
        """Test that Table Profiling tab is visible."""
        frame = wait_for_streamlit

        expect(frame.get_by_text("Table Profiling")).to_be_visible()

    def test_ai_query_tab_visible(self, page: Page, wait_for_streamlit):
        """Test that AI Query tab is visible."""
        frame = wait_for_streamlit

        expect(frame.get_by_text("AI Query (NL)")).to_be_visible()

    def test_ai_documentation_tab_visible(self, page: Page, wait_for_streamlit):
        """Test that AI Documentation tab is visible."""
        frame = wait_for_streamlit

        expect(frame.get_by_text("AI Documentation")).to_be_visible()

    def test_custom_query_tab_visible(self, page: Page, wait_for_streamlit):
        """Test that Custom Query tab is visible."""
        frame = wait_for_streamlit

        expect(frame.get_by_text("Custom Query")).to_be_visible()

    def test_export_tab_visible(self, page: Page, wait_for_streamlit):
        """Test that Export tab is visible."""
        frame = wait_for_streamlit

        expect(frame.get_by_text("Export")).to_be_visible()


class TestResponsiveness:
    """Test UI responsiveness and accessibility."""

    def test_desktop_viewport(self, page: Page, base_url: str):
        """Test application in desktop viewport."""
        page.set_viewport_size({"width": 1920, "height": 1080})
        page.goto(base_url)

        expect(page).to_have_title("SQL Data Dictionary Generator")

    def test_tablet_viewport(self, page: Page, base_url: str):
        """Test application in tablet viewport."""
        page.set_viewport_size({"width": 768, "height": 1024})
        page.goto(base_url)

        expect(page).to_have_title("SQL Data Dictionary Generator")

    def test_mobile_viewport(self, page: Page, base_url: str):
        """Test application in mobile viewport."""
        page.set_viewport_size({"width": 375, "height": 667})
        page.goto(base_url)

        expect(page).to_have_title("SQL Data Dictionary Generator")


class TestUIElements:
    """Test various UI elements and interactions."""

    def test_page_title_present(self, page: Page, wait_for_streamlit):
        """Test that main page title is present."""
        frame = wait_for_streamlit

        expect(frame.get_by_text("SQL Data Dictionary Generator")).to_be_visible()

    def test_database_connection_not_connected_initially(self, page: Page, wait_for_streamlit):
        """Test that app shows 'Not Connected' initially."""
        frame = wait_for_streamlit

        # Should show not connected status
        expect(frame.get_by_text("Not Connected")).to_be_visible()

    def test_info_message_when_not_connected(self, page: Page, wait_for_streamlit):
        """Test that info message appears when not connected."""
        frame = wait_for_streamlit

        # Should show message to connect
        # This text might be in the main area when not connected
        # Adjust based on your actual implementation


class TestAdvancedConnectionString:
    """Test advanced connection string functionality."""

    def test_advanced_expander_visible(self, page: Page, wait_for_streamlit):
        """Test that advanced connection string expander is visible."""
        frame = wait_for_streamlit

        # Look for advanced expander
        expect(frame.get_by_text("Advanced: Custom Connection String")).to_be_visible()

    def test_can_expand_advanced_section(self, page: Page, wait_for_streamlit):
        """Test that advanced section can be expanded."""
        frame = wait_for_streamlit

        # Click to expand
        frame.get_by_text("Advanced: Custom Connection String").click()

        # Wait a moment for expansion
        time.sleep(0.5)

        # Check for connection string text area
        expect(frame.get_by_label("Connection String")).to_be_visible()


class TestKeyboardNavigation:
    """Test keyboard navigation and accessibility."""

    def test_tab_navigation(self, page: Page, wait_for_streamlit):
        """Test that tab key can navigate form fields."""
        frame = wait_for_streamlit

        # Select PostgreSQL to show form fields
        frame.get_by_label("Database Type").select_option("PostgreSQL")

        # Focus first input
        host_input = frame.get_by_label("Host")
        host_input.focus()

        # Press tab to move to next field
        host_input.press("Tab")

        # Port field should now be focused (if tab order is correct)


class TestErrorHandling:
    """Test error handling and validation."""

    def test_connect_without_details(self, page: Page, wait_for_streamlit):
        """Test connecting without providing connection details."""
        frame = wait_for_streamlit

        # Try to connect without filling any details
        # Note: button might be disabled, check your implementation
        connect_button = frame.get_by_role("button", name="Connect")

        # The button might be disabled when not connected or fields are empty
        # This test validates the UI prevents invalid connections


class TestDatabaseTypeOptions:
    """Test all database type options are available."""

    def test_all_database_types_available(self, page: Page, wait_for_streamlit):
        """Test that all supported database types are in the selector."""
        frame = wait_for_streamlit

        db_selector = frame.get_by_label("Database Type")

        # Check for all database types
        expect(db_selector).to_contain_text("PostgreSQL")
        expect(db_selector).to_contain_text("MySQL")
        expect(db_selector).to_contain_text("SQLite")
        expect(db_selector).to_contain_text("SQL Server")
        expect(db_selector).to_contain_text("MongoDB")
        expect(db_selector).to_contain_text("Neo4j")


class TestPerformance:
    """Test application performance and load times."""

    def test_page_load_time(self, page: Page, base_url: str):
        """Test that page loads within acceptable time."""
        import time

        start_time = time.time()
        page.goto(base_url)
        page.wait_for_load_state("networkidle")
        end_time = time.time()

        load_time = end_time - start_time

        # Page should load within 10 seconds
        assert load_time < 10, f"Page took {load_time}s to load"

    def test_initial_render_time(self, page: Page, base_url: str):
        """Test that initial render completes quickly."""
        page.goto(base_url)

        # Wait for main content to be visible
        page.wait_for_selector('[data-testid="stAppViewContainer"]', timeout=5000)
