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
            "Client.CommunicationLibrary";
            "Client.ReplicationLibrary";
            "Client.InputLibrary";
            "Client.SequenceLibrary";
            "Client.GUILibrary";
            "Client.GraphicsLibrary";
            "Client.PlayerLibrary";
        };
        Classes = {
            "Animation.*";
            "DataType.*";
            "Geometry.*";
            "Graphics.*";
            "Process.*";
            "Storage.*";
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
            "Server.CommunicationLibrary";
            "Server.ReplicationLibrary";
            "Server.GraphicsLibrary";
            "Server.PlayerLibrary";
        };
        Classes = {
            "DataType.*";
            "Geometry.*";
            "Process.*";
            "Storage.*";
        };
    };
};