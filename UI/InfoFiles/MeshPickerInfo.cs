namespace CharacterDemo.UI.InfoFiles;

public record MeshPickerInfo(
    string MeshName,
    bool HasFilePicker = false,
    bool HasColorPicker = false,
    bool HasShapePicker = false
);

