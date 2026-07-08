using System.Collections.Generic;
using System.Linq;
using CharacterDemo.Mobs.DataFiles;
using CharacterDemo.Mobs.InfoFiles;

namespace CharacterDemo.Mobs.Services.MobGeneration;

///  ADJUST (keep valid, re-randomize invalid) 
public static class MobDataAdjuster
{
    public static BodyData AdjustBodyData(List<NormInfo> norms, BodyData bodyData)
    {
        foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
        {
            var meshNorms = norms.Where(norm => !norm.MeshNames.Any() || norm.MeshNames.Contains(meshName) || norm.MeshNames.Contains("BodyBulk")).ToList();
            var current = MobDataGetter.GetBodyDataFieldValue(bodyData, meshInfo.FieldName);
            var adjusted = AdjustMeshData(meshName, meshInfo, meshNorms, current);
            MobDataSetter.SetDataToBodyDataField(bodyData, meshInfo.FieldName, adjusted);
        }
        MobUtils.PropagateHairColor(bodyData);
        return bodyData;
    }
    public static EquipmentData AdjustEquipmentData(List<NormInfo> norms, EquipmentData eqData)
    {
        foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
        {
            var meshNorms = norms.Where(norm => !norm.MeshNames.Any() || norm.MeshNames.Contains(meshName) || norm.MeshNames.Contains("EquipmentBulk")).ToList();
            var current = MobDataGetter.GetEqDataFieldValue(eqData, meshInfo.FieldName);
            var adjusted = AdjustMeshData(meshName, meshInfo, meshNorms, current);
            MobDataSetter.SetDataToEqDataField(eqData, meshInfo.FieldName, adjusted);
        }
        return eqData;
    }
    private static MeshData AdjustMeshData(string meshName, MobMeshInfo meshInfo, List<NormInfo> norms, MeshData meshData)
    {
        meshData.MeshFile = MobDataGetter.GetRandomMeshFile(meshName, norms, meshInfo.FileFolder, meshData.MeshFile);
        meshData.MeshColors = MobDataGetter.GetRandomMeshColor(norms, meshInfo, meshData.MeshColors);
        meshData.MeshShapes = MobDataGetter.GetRandomMeshShapes(norms, meshInfo.Shapes, meshData.MeshShapes);
        return meshData;
    }

}

