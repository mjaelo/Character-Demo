using System.Collections.Generic;
using System.IO;
using Godot;

namespace CharacterDemo.General.Services;

/// Wraps file I/O operations used across the project.
public static class FileService
{
    // Load a mesh resource from a .tres file path, with caching
    public static ArrayMesh? LoadMesh(string filePath)
        => GeneralConstants.MeshCache.Load(filePath);

    // Load a Texture2D from a resource path, with caching
    public static Texture2D? LoadImage(string filePath) => GeneralConstants.TextureCache.Load(filePath);

    // Load JSON data from a file path (res:// or absolute). Returns deserialized C# type or default.
    public static T? LoadJson<T>(string filePath)
    {
        // Support both res:// and absolute paths
        string path = filePath;
        if (filePath.StartsWith("res://"))
        {
            // Convert res:// to absolute path using Godot's project path resolution
            path = ProjectSettings.GlobalizePath(filePath);
        }
        if (!File.Exists(path))
            return default;
        string json = File.ReadAllText(path);
        return SerializationService.Deserialize<T>(json);
    }

    // Serialize obj as JSON and write to filePath (res:// or absolute path).
    public static void SaveJson<T>(T obj, string filePath)
    {
        string path = filePath.StartsWith("res://") ? ProjectSettings.GlobalizePath(filePath) : filePath;
        string? dir = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
        File.WriteAllText(path, SerializationService.Serialize(obj));
    }

    // Get file names (without extension) for all .tres files in a folder.
    public static List<string> GetFileNames(string folderPath)
    {
        if (string.IsNullOrEmpty(folderPath)) return [];
        using var dir = DirAccess.Open(folderPath);
        if (dir == null) return [];
        var names = new List<string>();
        dir.ListDirBegin();
        var fileName = dir.GetNext();
        while (fileName != "")
        {
            if (!dir.CurrentIsDir() && fileName.EndsWith(".tres"))
                names.Add(Path.GetFileNameWithoutExtension(fileName));
            fileName = dir.GetNext();
        }
        dir.ListDirEnd();
        names.Sort();
        return names;
    }

}
