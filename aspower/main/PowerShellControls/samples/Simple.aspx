<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Simple.aspx.cs" Inherits="System.Web.PowerShell.Samples.Simple" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>PowerShellRunspace Sample: Simple</title>
</head>
<body>
    <PowerShell:Runspace ID="runspace" runat="server">
        <OnInit>
            $Response.Write("OnInit<br />")
        </OnInit>
        <OnLoad>
            $Response.Write("OnLoad<br />")
        </OnLoad>
        <OnLoad Source="~/SimpleExternalScript.ps1" />
        <OnRender>
            "OnRender<br />"
        </OnRender>
        <OnUnload>
            $Response.Write("OnUnload<br />")
        </OnUnload>
    </PowerShell:Runspace>
</body>
</html>
