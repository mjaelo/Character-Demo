using System.Collections.Generic;
using System.Linq;

namespace CharacterDemo.General;

public static class GeneralUtils
{
    public static bool HasAll<T>(IEnumerable<T> mainArray, IEnumerable<T> elementsArray)
        => elementsArray.All(e => mainArray.Contains(e));

    public static bool HasAny<T>(IEnumerable<T> mainArray, IEnumerable<T> elementsArray)
        => elementsArray.Any(e => mainArray.Contains(e));
}

