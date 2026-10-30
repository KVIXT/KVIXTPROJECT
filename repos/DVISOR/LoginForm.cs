using System;
using System.Windows.Forms;

namespace DVISOR
{
    public partial class LoginForm : Form
    {
        public LoginForm()
        {
            InitializeComponent();
        }

        private void btnLogin_Click(object sender, EventArgs e)
        {
            string username = txtUsername.Text;
            string password = txtPassword.Text;

            if (username == "admin" && password == "admin")
            {
                var dataManager = new DataManager();
                var dt = dataManager.GetPlayerProfiles();

                if (dt.Rows.Count > 0)
                {
                    Session.CurrentUser = new PlayerProfile
                    {
                        profile_id = (int)dt.Rows[0]["profile_id"],
                        steam_id = (long)dt.Rows[0]["steam_id"],
                        player_name = dt.Rows[0]["player_name"].ToString(),
                        rank = dt.Rows[0]["rank"].ToString(),
                        mmr = (int)dt.Rows[0]["mmr"],
                        total_matches = (int)dt.Rows[0]["total_matches"],
                        total_wins = (int)dt.Rows[0]["total_wins"],
                        is_admin = true
                    };

                    this.DialogResult = DialogResult.OK;
                    this.Close();
                }
            }
            else
            {
                MessageBox.Show("Неверные учётные данные");
                txtPassword.Clear();
            }
        }
    }
}