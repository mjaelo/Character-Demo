using CharacterDemo.General.Services;
using Godot;
using System.Collections.Generic;

namespace CharacterDemo.General;

public static class GeneralConstants
{
    public static readonly AssetCache<ArrayMesh> MeshCache = new();
    public static readonly AssetCache<Texture2D> TextureCache = new();
    public static readonly Dictionary<string, List<string>> CachedMeshShapeNames = new();

    // Physics
    public const float DefaultGravity = 30.0f;
    public const float DefaultSpeed = 10.0f;
    public const float DefaultJumpImpulse = 21.0f;
    public const float DefaultSpeedLimit = 100.0f;
    
    // general
    public const float FloatPrecision = 0.01f;
}

