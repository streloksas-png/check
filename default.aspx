<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Collections.Generic" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>MECM Dashboard, ё Man</title>
    <script src="assets/chart.umd.js" integrity="sha384-hfkuqrKeWFmnTMWN31VWyoe8xgdTADD11kgxmdpx2uyE6j5Az5uZq6u6AKYYmAOw"></script>
    <style>
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #121212; color: #fff; padding: 20px; text-align: center; margin: 0; }
        
        .charts-wrapper { display: flex; flex-direction: column; align-items: center; gap: 30px; margin-top: 30px; padding: 0 20px; }
        .chart-container-doughnut { width: 100%; max-width: 450px; background: #1e1e1e; padding: 25px; border-radius: 10px; box-shadow: 0 8px 20px rgba(0,0,0,0.6); }
        .chart-container-bar { width: 100%; max-width: 800px; background: #1e1e1e; padding: 25px; border-radius: 10px; box-shadow: 0 8px 20px rgba(0,0,0,0.6); }
        
        .btn { background-color: #0078D7; color: white; border: none; padding: 12px 24px; font-size: 16px; cursor: pointer; border-radius: 5px; font-weight: bold; margin: 5px; text-decoration: none; display: inline-block; transition: background-color 0.2s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.3); }
        .btn:hover { background-color: #005a9e; }
        .error { color: #ff5c5c; font-weight: bold; font-size: 18px; margin-top: 20px; }
        h2 { margin-bottom: 25px; font-weight: 300; letter-spacing: 1px; color: #ffffff; }
    </style>
    <script runat="server">
        public int WithAgent = 0;
        public int NoAgent = 0;
        public int Total = 0;
        public string ErrorMessage = "";
        
        public string OsLabels = "";
        public string OsData = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            // Inventory must not be retained in browser or shared HTTP caches.
            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            Response.Cache.SetRevalidation(System.Web.HttpCacheRevalidation.AllCaches);
            Response.Cache.SetExpires(DateTime.UtcNow.AddDays(-1));
            if (!IsPostBack)
            {
                LoadChartData();
            }
        }

        protected void btnRefresh_Click(object sender, EventArgs e)
        {
            LoadChartData();
        }

        private void LoadChartData()
        {
            string connString = "Server=localhost;Database=MECM;Integrated Security=True;";
            
            string queryAgents = @"
                DECLARE @Total INT = ISNULL((SELECT COUNT(ResourceID) FROM v_FullCollectionMembership fcm JOIN v_Collection c ON fcm.CollectionID = c.CollectionID WHERE c.Name = 'CORP_OFFICE'), 0);
                DECLARE @No INT = ISNULL((SELECT COUNT(ResourceID) FROM v_FullCollectionMembership fcm JOIN v_Collection c ON fcm.CollectionID = c.CollectionID WHERE c.Name = 'NoAgent'), 0);
                SELECT @Total AS Total, @No AS NoAgent, (@Total - @No) AS WithAgent;";

            // Жестко отсекаем неизвестные ОС через INNER JOIN, ё Man
            string queryOS = @"
                SELECT
                    os.Caption0 AS OSName,
                    COUNT(fcm.ResourceID) AS OSCount
                FROM v_FullCollectionMembership fcm
                INNER JOIN v_Collection c ON fcm.CollectionID = c.CollectionID
                INNER JOIN v_GS_OPERATING_SYSTEM os ON fcm.ResourceID = os.ResourceID
                WHERE c.Name = 'CORP_OFFICE' AND os.Caption0 IS NOT NULL
                GROUP BY os.Caption0
                ORDER BY OSCount DESC";

            try
            {
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    conn.Open();
                    
                    using (SqlCommand cmd = new SqlCommand(queryAgents, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                Total = Convert.ToInt32(reader["Total"]);
                                NoAgent = Convert.ToInt32(reader["NoAgent"]);
                                WithAgent = Convert.ToInt32(reader["WithAgent"]);
                                if (WithAgent < 0) WithAgent = 0; 
                            }
                        }
                    }

                    List<string> labelsList = new List<string>();
                    List<string> dataList = new List<string>();
                    
                    using (SqlCommand cmd = new SqlCommand(queryOS, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                string osName = reader["OSName"].ToString()
                                    .Replace("Microsoft ", "")
                                    .Replace("Windows ", "Win ")
                                    .Replace("Корпоративная", "Corp")
                                    .Replace("для образовательных учреждений", "Edu")
                                    .Replace("Professional", "Pro")
                                    .Replace("Enterprise", "Ent");
                                
                                // HTML encoding alone is not suitable inside a script element.
                                // JavaScriptStringEncode escapes quotes, backslashes, control
                                // characters and '<', preventing a script-element breakout.
                                labelsList.Add(System.Web.HttpUtility.JavaScriptStringEncode(osName, true));
                                dataList.Add(Convert.ToInt32(reader["OSCount"]).ToString(
                                    System.Globalization.CultureInfo.InvariantCulture));
                            }
                        }
                    }
                    
                    OsLabels = string.Join(",", labelsList);
                    OsData = string.Join(",", dataList);
                }
                ErrorMessage = "";
            }
            catch (Exception ex)
            {
                MecmDiagnostics.LogDataError("MECM dashboard data load failed", ex);
                ErrorMessage = "Не удалось загрузить данные. Обратитесь к администратору.";
            }
        }
    </script>
</head>
<body>
    <h2>Статус инфраструктуры CORP_OFFICE</h2>
    
    <form id="form1" runat="server">
        <div>
            <asp:Button ID="btnRefresh" runat="server" Text="Обновить дашборд" CssClass="btn" OnClick="btnRefresh_Click" />
            <a href="hardware.aspx" class="btn">Железо компьютеров</a>
        </div>

        <% if (!string.IsNullOrEmpty(ErrorMessage)) { %>
            <div class="error"><%= System.Web.HttpUtility.HtmlEncode(ErrorMessage) %></div>
        <% } else { %>
            
            <div class="charts-wrapper">
                <div class="chart-container-doughnut">
                    <canvas id="agentChart"></canvas>
                </div>
                
                <div class="chart-container-bar">
                    <canvas id="osChart"></canvas>
                </div>
            </div>
            
            <script>
                var ctxAgent = document.getElementById('agentChart').getContext('2d');
                new Chart(ctxAgent, {
                    type: 'doughnut',
                    data: {
                        labels: ['С агентом (' + <%= WithAgent %> + ')', 'Без агента (' + <%= NoAgent %> + ')'],
                        datasets: [{
                            data: [<%= WithAgent %>, <%= NoAgent %>],
                            backgroundColor: ['#28a745', '#dc3545'],
                            borderWidth: 2,
                            borderColor: '#1e1e1e'
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: { position: 'bottom', labels: { color: '#fff', font: { size: 14 } } },
                            title: { display: true, text: 'Агенты MECM (Всего: ' + <%= Total %> + ')', color: '#aaaaaa', font: { size: 16 } }
                        }
                    }
                });

                var ctxOs = document.getElementById('osChart').getContext('2d');
                new Chart(ctxOs, {
                    type: 'bar',
                    data: {
                        labels: [<%= OsLabels %>],
                        datasets: [{
                            label: 'Устройств',
                            data: [<%= OsData %>],
                            backgroundColor: '#0078D7',
                            borderRadius: 4,
                            barPercentage: 0.7
                        }]
                    },
                    options: {
                        indexAxis: 'y',
                        responsive: true,
                        plugins: {
                            legend: { display: false },
                            title: { display: true, text: 'Версии операционных систем', color: '#aaaaaa', font: { size: 16 } }
                        },
                        scales: {
                            x: { 
                                beginAtZero: true,
                                ticks: { color: '#ccc' }, 
                                grid: { color: '#333' } 
                            },
                            y: { 
                                ticks: { color: '#ccc', font: { size: 13 } }, 
                                grid: { display: false } 
                            }
                        }
                    }
                });
            </script>
        <% } %>
    </form>
</body>
</html>