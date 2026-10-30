using System;
using System.Drawing;
using System.Windows.Forms;

public class SearchForm : Form
{
    private DataManager _dataManager = new DataManager();
    private DataGridView dgvResults;

    public SearchForm()
    {
        this.Text = "Поиск";
        this.Size = new Size(1000, 600);
        this.StartPosition = FormStartPosition.CenterParent;
        this.BackColor = Color.FromArgb(20, 30, 45);
        this.ForeColor = Color.White;

        CreateFilterPanel();
    }

    private void CreateFilterPanel()
    {
        var panel = new Panel
        {
            Dock = DockStyle.Top,
            Height = 80,
            BackColor = Color.FromArgb(30, 45, 60)
        };

        var lblMinWR = new Label { Text = "Win rate %:", Left = 10, Top = 10, ForeColor = Color.White };
        var txtMinWR = new TextBox { Left = 120, Top = 10, Width = 50, Text = "50" };

        var lblHero = new Label { Text = "Герой:", Left = 10, Top = 40, ForeColor = Color.White };
        var txtHero = new TextBox { Left = 120, Top = 40, Width = 150 };

        var btnSearch = new Button { Text = "Поиск", Left = 280, Top = 10, Width = 100 };
        btnSearch.Click += (s, e) => PerformSearch(txtMinWR.Text, txtHero.Text);

        panel.Controls.Add(lblMinWR);
        panel.Controls.Add(txtMinWR);
        panel.Controls.Add(lblHero);
        panel.Controls.Add(txtHero);
        panel.Controls.Add(btnSearch);

        this.Controls.Add(panel);

        dgvResults = new DataGridView
        {
            Dock = DockStyle.Fill,
            AllowUserToAddRows = false,
            BackgroundColor = Color.FromArgb(25, 35, 50),
            ForeColor = Color.White
        };

        this.Controls.Add(dgvResults);
    }

    private void PerformSearch(string minWR, string heroName)
    {
        dgvResults.DataSource = _dataManager.SearchHeroes(minWR, heroName);
    }
}