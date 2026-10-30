using System;
using System.Drawing;
using System.Windows.Forms;

public class StatisticsForm : Form
{
    private DataManager _dataManager = new DataManager();
    private int _profileId;

    public StatisticsForm(int profileId)
    {
        _profileId = profileId;
        this.Text = "Статистика игрока";
        this.Size = new Size(900, 600);
        this.StartPosition = FormStartPosition.CenterParent;
        this.BackColor = Color.FromArgb(20, 30, 45);
        this.ForeColor = Color.White;

        CreateTabs();
    }

    private void CreateTabs()
    {
        var tabControl = new TabControl { Dock = DockStyle.Fill };

        var tabHeroes = new TabPage("По героям");
        var dgvHeroes = new DataGridView
        {
            Dock = DockStyle.Fill,
            AllowUserToAddRows = false,
            BackgroundColor = Color.FromArgb(25, 35, 50),
            ForeColor = Color.White
        };
        dgvHeroes.DataSource = _dataManager.GetPlayerStats(_profileId);
        tabHeroes.Controls.Add(dgvHeroes);

        var tabRoles = new TabPage("По ролям");
        var dgvRoles = new DataGridView
        {
            Dock = DockStyle.Fill,
            AllowUserToAddRows = false,
            BackgroundColor = Color.FromArgb(25, 35, 50),
            ForeColor = Color.White
        };
        dgvRoles.DataSource = _dataManager.GetRoleStats(_profileId);
        tabRoles.Controls.Add(dgvRoles);

        tabControl.TabPages.Add(tabHeroes);
        tabControl.TabPages.Add(tabRoles);

        this.Controls.Add(tabControl);
    }
}