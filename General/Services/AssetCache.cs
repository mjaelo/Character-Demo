using System;
using Microsoft.Extensions.Caching.Memory;
using Godot;

namespace CharacterDemo.General.Services;

public class AssetCache<T> where T : class
{
    private readonly MemoryCache _cache;
    private readonly long? _sizeLimit;

    public AssetCache(long? sizeLimit = null)
    {
        var options = new MemoryCacheOptions();
        if (sizeLimit.HasValue) options.SizeLimit = sizeLimit.Value;
        _cache = new MemoryCache(options);
        _sizeLimit = sizeLimit;
    }

    public T? Load(string path)
    {
        if (_cache.TryGetValue(path, out var cachedObj))
            if (cachedObj is T cached) return cached;

        T? asset = ResourceLoader.Load<T>(path);
        if (asset == null) return null;

        var entryOptions = new MemoryCacheEntryOptions();
        if (_sizeLimit.HasValue) entryOptions.SetSize(1);
        entryOptions.RegisterPostEvictionCallback((_, value, _, _) =>
        {
            if (value is IDisposable d) d.Dispose();
        });

        _cache.Set(path, asset, entryOptions);
        return asset;
    }

    public void Clear() => _cache.Compact(1.0);
}

