using System;
using System.Drawing;
using System.Windows.Forms;

public class MatchDetailForm : Form
{
    private int _matchId;
    private DataManager _dataManager = new DataManager();

    public MatchDetailForm(int matchId)
    {
        _matchId = matchId;
        this.Text = $"Матч #{matchId}";
        this.Size = new Size(1000, 700);
        this.StartPosition = FormStartPosition.CenterParent;
        this.BackColor = Color.FromArgb(20, 30, 45);
        this.ForeColor = Color.White;

        LoadMatchDetails();
    }

    private void LoadMatchDetails()
    {
        var dgv = new DataGridView
        {
            Dock = DockStyle.Fill,
            AllowUserToAddRows = false,
            BackgroundColor = Color.FromArgb(25, 35, 50),
            ForeColor = Color.White
        };

        dgv.DataSource = _dataManager.GetMatchDetails(_matchId);
        this.Controls.Add(dgv);
    }
}