<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Data" %>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Hardware, ё Man</title>
    
    <script src="assets/jquery.min.js" integrity="sha384-1H217gwSVyLSIfaLxHbE7dRb3v4mYCKbpQvzx0cegeju1MVsGrX5xXxAvs/HgeFs"></script>
    <link rel="stylesheet" href="assets/jquery.dataTables.min.css" integrity="sha384-1QCPE0Isvkd7i/DO1KTZ5GqTLhlGv8kAWBNQDo2jFBkImeSuFxZcEPU0SANETyv5">
    <script src="assets/jquery.dataTables.min.js" integrity="sha384-xbKh5PcHqYD2znaTJ+mPamIq8ERw8yRfp72NI8CGRg51FffJAXidmePtdkmCjEh9"></script>
    
    <style>
        /* Базовые стили */
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #121212; color: #e0e0e0; padding: 20px; text-align: center; margin: 0; }
        .btn { background-color: #0078D7; color: white; border: none; padding: 10px 20px; font-size: 14px; cursor: pointer; border-radius: 5px; font-weight: bold; margin: 5px; text-decoration: none; display: inline-block; transition: background-color 0.2s ease; box-shadow: 0 2px 5px rgba(0,0,0,0.3); }
        .btn:hover { background-color: #005a9e; }
        .error { color: #ff5c5c; font-weight: bold; font-size: 16px; margin-top: 20px; }
        h2 { margin-bottom: 25px; color: #ffffff; font-weight: 300; letter-spacing: 1px; }
        
        /* Контейнер таблицы с тенями */
        .table-container { margin-top: 20px; background: #1e1e1e; padding: 25px; border-radius: 10px; box-shadow: 0 8px 20px rgba(0,0,0,0.6); overflow-x: auto; text-align: left; }
        
        /* Жесткие премиум-стили для DataTables */
        table.dataTable { border-collapse: collapse !important; width: 100% !important; color: #cccccc; font-size: 14px; }
        
        /* Заголовок без синего фона, только нижняя акцентная линия */
        table.dataTable thead th { background-color: #1e1e1e; color: #ffffff; border-bottom: 2px solid #0078D7 !important; padding: 15px 10px; text-transform: uppercase; font-size: 12px; letter-spacing: 1px; border-top: none; }
        
        /* Убираем вертикальные рамки, оставляем тонкие горизонтальные */
        table.dataTable tbody td { padding: 12px 10px; border-bottom: 1px solid #2a2a2d !important; border-top: none; vertical-align: middle; }
        
        /* Плавный ховер строк */
        table.dataTable tbody tr { background-color: transparent !important; transition: background-color 0.15s ease; }
        table.dataTable tbody tr:hover { background-color: #2a2a2d !important; }
        
        /* Верхняя и нижняя панели Flexbox, ё Man */
        .top-panel { display: flex; align-items: center; flex-wrap: wrap; margin-bottom: 15px; width: 100%; }
        .top-panel .dataTables_length { margin-right: auto; margin-bottom: 0 !important; color: #999999 !important; font-size: 13px; }
        .top-panel .dataTables_filter { margin-bottom: 0 !important; margin-right: 20px; color: #999999 !important; font-size: 13px; }
        .top-panel .dataTables_paginate { margin-top: 0 !important; }
        
        .bottom-panel { display: flex; justify-content: space-between; align-items: center; margin-top: 15px; width: 100%; }
        .bottom-panel .dataTables_info { margin-bottom: 0 !important; color: #999999 !important; font-size: 13px; }
        .bottom-panel .dataTables_paginate { margin-top: 0 !important; }
        
        /* Поля ввода */
        .dataTables_wrapper .dataTables_filter input { background-color: #2d2d30; border: 1px solid #444; color: #fff; padding: 6px 12px; border-radius: 5px; margin-left: 10px; outline: none; transition: border-color 0.2s; }
        .dataTables_wrapper .dataTables_filter input:focus { border-color: #0078D7; }
        .dataTables_wrapper .dataTables_length select { background-color: #2d2d30; border: 1px solid #444; color: #fff; padding: 5px; border-radius: 5px; outline: none; }
        
        /* Кнопки страниц */
        .dataTables_wrapper .dataTables_paginate .paginate_button { color: #aaaaaa !important; border: 1px solid transparent !important; background: transparent !important; padding: 6px 12px; border-radius: 5px; margin: 0 3px; font-size: 13px; transition: all 0.2s; }
        .dataTables_wrapper .dataTables_paginate .paginate_button:hover { background: #333337 !important; color: #ffffff !important; border: 1px solid #555555 !important; }
        .dataTables_wrapper .dataTables_paginate .paginate_button.current, .dataTables_wrapper .dataTables_paginate .paginate_button.current:hover { background: #0078D7 !important; color: #ffffff !important; border: 1px solid #0078D7 !important; font-weight: bold; box-shadow: 0 2px 5px rgba(0,120,215,0.4); }
    </style>
    
    <script runat="server">
        public string TableErrorMessage = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            // Inventory must not be retained in browser or shared HTTP caches.
            Response.Cache.SetCacheability(System.Web.HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            Response.Cache.SetRevalidation(System.Web.HttpCacheRevalidation.AllCaches);
            Response.Cache.SetExpires(DateTime.UtcNow.AddDays(-1));
            if (!IsPostBack)
            {
                LoadTableData();
            }
        }

        protected void btnRefresh_Click(object sender, EventArgs e)
        {
            LoadTableData();
        }

        protected void HardwareTable_PreRender(object sender, EventArgs e)
        {
            if (HardwareTable.Rows.Count > 0)
            {
                HardwareTable.UseAccessibleHeader = true;
                HardwareTable.HeaderRow.TableSection = TableRowSection.TableHeader;
            }
        }

        private void LoadTableData()
        {
            string connString = "Server=localhost;Database=MECM;Integrated Security=True;";
            string query = @"
                WITH CTE_RAM AS (
                    SELECT
                        ResourceID,
                        COUNT(ResourceID) AS [RAM_Sticks_Count],
                        STRING_AGG(Capacity0, ' + ') WITHIN GROUP (ORDER BY BankLabel0 ASC) AS [Sticks_Layout_MB],
                        SUM(Capacity0) AS [Total_RAM_MB]
                    FROM v_GS_PHYSICAL_MEMORY
                    GROUP BY ResourceID),
                CTE_DISK AS (
                    SELECT
                        ResourceID,
                        STRING_AGG(CAST(Model0 AS VARCHAR(100)), ' | ') AS [Disks_Info]
                    FROM v_GS_DISK
                    GROUP BY ResourceID)
                SELECT
                    fcm.Name AS [Computer_Name],
                    sys.User_Name0 AS [Login_User],
                    cs.Manufacturer0 AS [Manufacturer],
                    cs.Model0 AS [Model],
                    bios.SerialNumber0 AS [Serial_Number],
                    cpu.Name0 AS [CPU],
                    ram.[RAM_Sticks_Count],
                    ram.[Sticks_Layout_MB],
                    ram.[Total_RAM_MB],
                    disk.[Disks_Info]
                FROM v_FullCollectionMembership fcm
                INNER JOIN v_Collection col ON fcm.CollectionID = col.CollectionID
                LEFT JOIN v_R_System sys ON fcm.ResourceID = sys.ResourceID
                LEFT JOIN v_GS_COMPUTER_SYSTEM cs ON fcm.ResourceID = cs.ResourceID
                LEFT JOIN v_GS_PC_BIOS bios ON fcm.ResourceID = bios.ResourceID
                LEFT JOIN v_GS_PROCESSOR cpu ON fcm.ResourceID = cpu.ResourceID
                LEFT JOIN CTE_RAM ram ON fcm.ResourceID = ram.ResourceID
                LEFT JOIN CTE_DISK disk ON fcm.ResourceID = disk.ResourceID
                WHERE col.Name = 'CORP_OFFICE'";

            try
            {
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        using (SqlDataAdapter sda = new SqlDataAdapter(cmd))
                        {
                            DataTable dt = new DataTable();
                            sda.Fill(dt);
                            HardwareTable.DataSource = dt;
                            HardwareTable.DataBind();
                        }
                    }
                }
                TableErrorMessage = "";
            }
            catch (Exception ex)
            {
                MecmDiagnostics.LogDataError("MECM hardware data load failed", ex);
                TableErrorMessage = "Не удалось загрузить данные. Обратитесь к администратору.";
            }
        }
    </script>
</head>
<body>
    <h2>Сводка по железу CORP_OFFICE</h2>
    <form id="form1" runat="server">
        <div>
            <a href="default.aspx" class="btn">Назад к графику</a>
            <asp:Button ID="btnRefresh" runat="server" Text="Обновить данные БД" CssClass="btn" OnClick="btnRefresh_Click" />
        </div>
        
        <% if (!string.IsNullOrEmpty(TableErrorMessage)) { %>
            <div class="error"><%= System.Web.HttpUtility.HtmlEncode(TableErrorMessage) %></div>
        <% } %>
        
        <div class="table-container">
            <asp:GridView ID="HardwareTable" runat="server" CssClass="display" OnPreRender="HardwareTable_PreRender" AutoGenerateColumns="false" BorderWidth="0">
                <Columns>
                    <asp:BoundField DataField="Computer_Name" HeaderText="Computer_Name" HtmlEncode="true" />
                    <asp:BoundField DataField="Login_User" HeaderText="Login_User" HtmlEncode="true" />
                    <asp:BoundField DataField="Manufacturer" HeaderText="Manufacturer" HtmlEncode="true" />
                    <asp:BoundField DataField="Model" HeaderText="Model" HtmlEncode="true" />
                    <asp:BoundField DataField="Serial_Number" HeaderText="Serial_Number" HtmlEncode="true" />
                    <asp:BoundField DataField="CPU" HeaderText="CPU" HtmlEncode="true" />
                    <asp:BoundField DataField="RAM_Sticks_Count" HeaderText="RAM_Sticks_Count" HtmlEncode="true" />
                    <asp:BoundField DataField="Sticks_Layout_MB" HeaderText="Sticks_Layout_MB" HtmlEncode="true" />
                    <asp:BoundField DataField="Total_RAM_MB" HeaderText="Total_RAM_MB" HtmlEncode="true" />
                    <asp:BoundField DataField="Disks_Info" HeaderText="Disks_Info" HtmlEncode="true" />
                </Columns>
            </asp:GridView>
        </div>
    </form>

    <script>
        $(document).ready(function () {
            var table = $('#<%= HardwareTable.ClientID %>').DataTable({
                "language": {
                    "emptyTable": "Нет данных",
                    "info": "Записи с _START_ по _END_ из _TOTAL_",
                    "infoEmpty": "Записей нет",
                    "infoFiltered": "(из _MAX_ записей)",
                    "lengthMenu": "Показать _MENU_ записей",
                    "loadingRecords": "Загрузка…",
                    "processing": "Обработка…",
                    "search": "Поиск:",
                    "zeroRecords": "Совпадений не найдено",
                    "paginate": { "first": "Первая", "last": "Последняя", "next": "Следующая", "previous": "Предыдущая" },
                    "aria": { "sortAscending": ": сортировать по возрастанию", "sortDescending": ": сортировать по убыванию" }
                },
                "pageLength": 25,
                "lengthMenu": [[10, 25, 50, 100, -1], [10, 25, 50, 100, "Все"]],
                "stateSave": false,
                /* Меняем структуру DOM, клонируя пагинацию (p) наверх рядом с фильтром (f), ё Man */
                "dom": '<"top-panel"l f p>rt<"bottom-panel"i p>',
                "columnDefs": [{
                    "targets": "_all",
                    "defaultContent": "<span style='color:#555555; font-weight:bold;'>—</span>"
                }]
            });

            /* Дерзкий скролл наверх при клике на любую кнопку пагинации, ё Man */
            table.on('page.dt', function () {
                $('html, body').animate({
                    scrollTop: $(".table-container").offset().top - 20
                }, 300);
            });
        });
    </script>
</body>
</html>