using System;
using System.Collections.Generic;
using System.Linq;

namespace CharacterDemo.General;

public static class GeneralUtils
{
    private static readonly Random Rng = new();

    public static bool HasAll<T>(IEnumerable<T> mainArray, IEnumerable<T> elementsArray)
        => elementsArray.All(e => mainArray.Contains(e));

    public static bool HasAny<T>(IEnumerable<T> mainArray, IEnumerable<T> elementsArray)
        => elementsArray.Any(e => mainArray.Contains(e));

    public static T PickRandom<T>(List<T> array)
        => array[Rng.Next(array.Count)];
    public static T PickRandom<T>(T[] array)
        => array[Rng.Next(array.Length)];
    
    public static bool CheckRng(float probability)
        => Rng.NextDouble() <= probability;
}

