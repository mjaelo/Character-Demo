using System;
using System.Collections.Generic;
using System.Linq;

namespace CharacterDemo.General;

public static class GeneralUtils
{
    private static readonly Random Rng = new();

    public static bool HasAll<T>(IEnumerable<T> mainArray, IEnumerable<T> elementsArray)
        => elementsArray.All(mainArray.Contains);

    public static bool HasAny<T>(IEnumerable<T> mainArray, IEnumerable<T> elementsArray)
        => elementsArray.Any(mainArray.Contains);

    public static T PickRandom<T>(List<T> array)
        => array[Rng.Next(array.Count)];
    public static T PickRandom<T>(T[] array)
        => array[Rng.Next(array.Length)];
    
    public static bool CheckRng(float probability)
        => Rng.NextDouble() <= probability;
    
    public static IReadOnlyList<float> GetFloatRange(float min = -1, float max = 1)
    {
        var result = new List<float>();
        for (int v = (int)(min * 10); v <= (int)(max * 10); v++)
            result.Add(v / 10.0f);
        return result;
    }
    
    public static bool FloatEquals(float a, float b)
        => Math.Abs(a - b) < GeneralConstants.FloatPrecision;
}

