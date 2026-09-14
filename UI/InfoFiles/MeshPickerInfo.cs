using System.Collections.Generic;

namespace CharacterDemo.UI.InfoFiles;

/// <summary>
/// Configuration for mesh pickers in the creator UI.
/// </summary>
public record MeshPickerInfo(
    string MeshName,
    bool HasFilePicker = false,
    IReadOnlyList<bool>? ColorPickers = null,
    bool HasShapePicker = false
);

