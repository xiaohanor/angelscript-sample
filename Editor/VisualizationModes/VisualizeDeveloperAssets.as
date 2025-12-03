const FLinearColor DeveloperClassColor(1.f, 0.f, 0.f);
const FLinearColor DeveloperAssetColor(1.f, 0.f, 0.f);

class UVisualizeDeveloperAssets
{
    UFUNCTION()
    bool GetVisualizeColor(UObject Object, FLinearColor& OutColor) const
    {
        // Highlight specially if the class itself is developer content
        if (IsDeveloperAsset(Object.Class) || (Object.Outer != nullptr && IsDeveloperAsset(Object.Outer.Class)))
        {
            OutColor = DeveloperClassColor;
            return true;
        }

        bool bIsDeveloperAsset = false;

        // Highlight if any static meshes are developer content
        UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Object);
        if (StaticMeshComponent != nullptr)
        {
            if (IsDeveloperMesh(StaticMeshComponent.StaticMesh))
                bIsDeveloperAsset = true;

            int MaterialCount = StaticMeshComponent.GetNumMaterials();
            for (int MaterialIndex = 0; MaterialIndex < MaterialCount; ++MaterialIndex)
            {
                if(IsDeveloperAsset(StaticMeshComponent.GetMaterial(MaterialIndex)))
                    bIsDeveloperAsset = true;
            }
        }

        if (bIsDeveloperAsset)
        {
            OutColor = DeveloperAssetColor;
            return true;
        }
        else
        {
            return false;
        }
    }

    bool IsDeveloperMesh(UStaticMesh Mesh) const
    {
        if (Mesh == nullptr)
            return false;
        if (IsDeveloperAsset(Mesh))
            return true;
        return false;
    }

    bool IsDeveloperAsset(UObject Object) const
    {
        if (Object == nullptr)
            return false;
        FString PackageName = Object.GetOutermost().GetPathName();
        return PackageName.StartsWith("/Game/Developers/")
			|| PackageName.StartsWith("/Game/Dev/")
			|| PackageName.StartsWith("/Game/Maps/TestMaps/")
			|| PackageName.StartsWith("/Game/Editor/");
    }
}