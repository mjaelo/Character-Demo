using System.Collections.Generic;
using CharacterDemo.General;

namespace CharacterDemo.Mob.InfoFiles;

/// Describes valid shape ranges for one mesh slot.
public class MobShapeInfo(string shapeName, IReadOnlyList<float>? values = null)
{
    public readonly string ShapeName = shapeName;
    public readonly IReadOnlyList<float> Values = values ?? GeneralUtils.GetFloatRange();
}

