using System.Collections.Generic;

namespace CharacterDemo.UI.InfoFiles;

/// <summary>
/// Configuration for mesh pickers in the creator UI.
/// ColorPickers list indicates which materials have color pickers.
/// Index in list = material index (e.g., [true, true, true] = materials 0, 1, 2 all have pickers)
/// </summary>
public record MeshPickerInfo(
    string MeshName,
    bool HasFilePicker = false,
    IReadOnlyList<bool>? ColorPickers = null,
    bool HasShapePicker = false
);

