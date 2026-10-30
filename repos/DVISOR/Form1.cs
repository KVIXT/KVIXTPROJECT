using static System.Collections.Specialized.BitVector32;

namespace DVISOR
{
    public partial class Form1 : Form
    {
        private readonly DatabaseConnection _db = new DatabaseConnection();
        private readonly DataManager _dataManager = new DataManager();
        private DataGridView dgvProfiles;
        private DataGridView dgvMatches;

        public Form1()
        {
            InitializeComponent();

            Text = "DVISOR - Dota 2 Stats";
            Width = 1200;
            Height = 750;
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Color.FromArgb(20, 30, 45);
            ForeColor = Color.White;

            Load += Form1_Load;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            // Проверка авторизации
            if (Session.CurrentUser == null)
            {
                LoginForm login = new LoginForm();
                login.ShowDialog();
                if (Session.CurrentUser == null)
                {
                    this.Close();
                    return;
                }
            }

            // Загрузка профилей
            if (Session.CurrentUser.is_admin)
            {
                LoadAllProfiles(); // админ видит всех
            }
            else
            {
                LoadUserProfile(Session.CurrentUser.steam_id); // обычный только себя
            }
        }

        private void LoadAllProfiles()
        {
            var dataManager = new DataManager();
            var dt = dataManager.GetPlayerProfiles();
            dgvProfiles.DataSource = dt;
        }

        private void LoadUserProfile(long steamId)
        {
            var dataManager = new DataManager();
            var dt = dataManager.GetPlayerProfiles();

            // Фильтруем только текущего пользователя
            var dv = new System.Data.DataView(dt);
            dv.RowFilter = $"steam_id = {steamId}";
            dgvProfiles.DataSource = dv;
        }

        private void CreateInterface()
        {
            var menu = new MenuStrip();

            var analysisMenu = new ToolStripMenuItem("Анализ");
            analysisMenu.DropDownItems.Add("Статистика выбранного профиля", null, (_, _) => OpenStats());
            analysisMenu.DropDownItems.Add("Поиск по героям", null, (_, _) => new SearchForm().ShowDialog(this));
            menu.Items.Add(analysisMenu);

            MainMenuStrip = menu;
            Controls.Add(menu);



            var split = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Horizontal,
                SplitterDistance = 330,
                BackColor = BackColor
            };

            dgvProfiles = CreateGrid();
            dgvMatches = CreateGrid();

            var profilesPanel = new Panel { Dock = DockStyle.Fill };
            profilesPanel.Controls.Add(dgvProfiles);
            profilesPanel.Controls.Add(CreateHeader("Профили игроков"));

            var importBtn = new Button
{
    Text = "⬇ Импорт матчей",
    Width = 150,
    Height = 35,
    BackColor = Color.FromArgb(40, 60, 80),
    ForeColor = Color.White,
    Left = 10,
    Top = 10
};
importBtn.Click += async (_, _) => await ImportMatches();

var buttonPanel = new Panel
{
    Dock = DockStyle.Top,
    Height = 50,
    BackColor = Color.FromArgb(20, 30, 45)
};
buttonPanel.Controls.Add(importBtn);
split.Panel1.Controls.Add(buttonPanel);
split.Panel1.Controls.SetChildIndex(buttonPanel, 0);

            var matchesPanel = new Panel { Dock = DockStyle.Fill };
            matchesPanel.Controls.Add(dgvMatches);
            matchesPanel.Controls.Add(CreateHeader("Матчи — двойной щелчок открывает подробности"));

            split.Panel1.Controls.Add(profilesPanel);
            split.Panel2.Controls.Add(matchesPanel);
            Controls.Add(split);
            split.BringToFront();

            dgvProfiles.CellClick += (_, e) =>
            {
                if (e.RowIndex >= 0)
                    LoadMatchesFromSelectedProfile(e.RowIndex);
            };

            dgvMatches.CellDoubleClick += (_, e) =>
            {
                if (e.RowIndex < 0) return;

                var value = dgvMatches.Rows[e.RowIndex].Cells["match_id"].Value;
                if (value != null && int.TryParse(value.ToString(), out int matchId))
                    new MatchDetailForm(matchId).ShowDialog(this);
            };
        }

        private static Label CreateHeader(string text)
        {
            return new Label
            {
                Text = text,
                Dock = DockStyle.Top,
                Height = 35,
                Padding = new Padding(10, 8, 0, 0),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(30, 45, 60)
            };
        }

        private static DataGridView CreateGrid()
        {
            return new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                MultiSelect = false,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                BackgroundColor = Color.FromArgb(25, 35, 50),
                ForeColor = Color.White,
                GridColor = Color.FromArgb(50, 65, 85),
                RowHeadersVisible = false
            };
        }

        private void LoadProfiles()
        {
            dgvProfiles.DataSource = _dataManager.GetPlayerProfiles();

            if (dgvProfiles.Rows.Count > 0)
            {
                dgvProfiles.Rows[0].Selected = true;
                LoadMatchesFromSelectedProfile(0);
            }
        }

        private void LoadMatchesFromSelectedProfile(int rowIndex)
        {
            var value = dgvProfiles.Rows[rowIndex].Cells["profile_id"].Value;

            if (value != null && int.TryParse(value.ToString(), out int profileId))
                dgvMatches.DataSource = _dataManager.GetMatches(profileId);
        }

        private void OpenStats()
        {
            if (dgvProfiles.SelectedRows.Count == 0)
            {
                MessageBox.Show("Сначала выбери профиль.");
                return;
            }

            var value = dgvProfiles.SelectedRows[0].Cells["profile_id"].Value;

            if (value != null && int.TryParse(value.ToString(), out int profileId))
                new StatisticsForm(profileId).ShowDialog(this);
        }
        private async Task ImportMatches()
        {
            if (dgvProfiles.SelectedRows.Count == 0)
            {
                MessageBox.Show("Выбери профиль для импорта");
                return;
            }

            var steamId = dgvProfiles.SelectedRows[0].Cells["steam_id"].Value?.ToString();
            if (string.IsNullOrEmpty(steamId))
            {
                MessageBox.Show("Steam ID не найден");
                return;
            }

            MessageBox.Show($"Начинаю загрузку матчей для SteamID {steamId}...");

            var client = new OpenDotaClient();
            var matchesJson = await client.GetPlayerMatchesAsync(steamId, 10);

            if (!string.IsNullOrEmpty(matchesJson))
                MessageBox.Show("Матчи загружены! Вскоре добавим их в БД.");
        }
    }
}