using System.Linq;
using CharacterDemo.General;
using Godot;

namespace CharacterDemo.UI;

public static class UiUtils
{
    public static void DisableEdit(Control node, bool disabled)
    {
        switch (node)
        {
            case BaseButton btn:
                btn.Disabled = disabled;
                ChangeLabelVisibility(btn, disabled);
                break;
            case LineEdit le: le.Editable = !disabled; break;
            case TextEdit te: te.Editable = !disabled; break;
            case Label label: ChangeLabelVisibility(label, disabled); break;
        }
        foreach (var child in node.GetChildren().OfType<Control>())
            DisableEdit(child, disabled);
    }

    private static void ChangeLabelVisibility(CanvasItem control, bool isDimmed)
    {
        var mod = control.Modulate;
        mod.A = isDimmed ? 0.2f : 1.0f;
        control.Modulate = mod;
    }

    public static void ButtonShowWarning(Button button, string tooltipText = "Warning")
    {
        button.Icon = GeneralConstants.TextureCache.Load(UiConstants.WarningIconPath);
        button.TooltipText = tooltipText;
    }

    public static void ButtonHideWarning(Button button)
    {
        button.Icon = null;
        button.TooltipText = "";
    }
}

