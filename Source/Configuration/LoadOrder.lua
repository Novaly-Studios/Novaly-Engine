-- Prioritise loads here so libraries can access others...

--[[
return
{
    "CoreLibrary";
    "AsyncLibrary";
    "LoggingLibrary";
    "TableLibrary";
    "ClassLibrary";
    "ImportClasses";
    "MathematicsLibrary";
    "GeometryLibrary";
    "StringLibrary";
    "EnumLibrary";
    "DataStructureLibrary";
    "CommunicationLibrary";
    "SequenceLibrary";
    "MiscLibrary";
    "GraphicsLibrary";
    "GUILibrary";
    "ReplicationLibrary";
    "PlayerLibrary";
    "WeldLibrary";
    "CollectionHelperLibrary";
    "InputLibrary";
};]]

return
{
    Client = {
        Utility = {
            "Shared.CoreLibrary";
            "Shared.AsyncLibrary";
            "Shared.LoggingLibrary";
            "Shared.TableLibrary";
            "Shared.MathematicsLibrary";
            "Shared.GeometryLibrary";
            "Shared.StringLibrary";
            "Shared.EnumLibrary";
            "Shared.DataStructureLibrary";
            "Shared.MiscLibrary";
            "Shared.WeldLibrary";
            "Shared.CollectionHelperLibrary";
            "Shared.TaskManager";
            "Client.InternalEvents";
            "Client.CommunicationLibrary";
            "Client.ReplicationLibrary";
            "Client.InputLibrary";
            "Client.SequenceLibrary";
            "Client.GUILibrary";
            "Client.GraphicsLibrary";
            "Client.PlayerLibrary";
        };
    };
    Server = {
        Utility = {
            "Shared.CoreLibrary";
            "Shared.AsyncLibrary";
            "Shared.LoggingLibrary";
            "Shared.TableLibrary";
            "Shared.MathematicsLibrary";
            "Shared.GeometryLibrary";
            "Shared.StringLibrary";
            "Shared.EnumLibrary";
            "Shared.DataStructureLibrary";
            "Shared.MiscLibrary";
            "Shared.WeldLibrary";
            "Shared.CollectionHelperLibrary";
            "Shared.TaskManager";
            "Server.CommunicationLibrary";
            "Server.ReplicationLibrary";
            "Server.GraphicsLibrary";
            "Server.PlayerLibrary";
        };
    };
};