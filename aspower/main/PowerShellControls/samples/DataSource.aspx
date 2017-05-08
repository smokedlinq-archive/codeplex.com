<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DataSource.aspx.cs" Inherits="System.Web.PowerShell.Samples.DataSource" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>PowerShellRunspace Sample: PowerShellDataSource Control</title>
</head>
<body>
    <PowerShell:DataSource ID="EmployeesDataSource" runat="server">
        <Script>
            [PSObject]"" | Add-Member NoteProperty "Title" "Software Engineer" -passThru | Add-Member NoteProperty "Name" "Mike Wolford" -passThru
            [PSObject]"" | Add-Member NoteProperty "Title" "Software Evangelist" -passThru | Add-Member NoteProperty "Name" "Scott Root" -passThru
            [PSObject]"" | Add-Member NoteProperty "Title" "Glaser Beam" -passThru | Add-Member NoteProperty "Name" "Justin Glaser" -passThru
            [PSObject]"" | Add-Member NoteProperty "Title" "T.I.E. Guru" -passThru | Add-Member NoteProperty "Name" "Casey Sanford" -passThru
        </Script>
    </PowerShell:DataSource>
    
    <h1>Employees</h1>
    
    <asp:Repeater runat="server" DataSourceID="EmployeesDataSource">
        <ItemTemplate>
            <h4><%# DataBinder.Eval(Container.DataItem, "Title") %>: <%# DataBinder.Eval(Container.DataItem, "Name") %></h4>
        </ItemTemplate>
    </asp:Repeater>
</body>
</html>
