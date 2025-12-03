enum EHoverPerchConnectionGrindMaterialType
{
	None,
	RightArrow,
	LeftArrow
}

enum EHoverPerchConnectionGrindMeshSide
{
	Left,
	Right
}

struct FHoverPerchConnectionGrindMaterialOverride
{
	FHoverPerchConnectionGrindMaterialOverride(AHazePlayerCharacter In_Player)
	{
		Player = In_Player;
	}

	AHazePlayerCharacter Player;
	EHoverPerchConnectionGrindMaterialType MaterialType;

	bool opEquals(FHoverPerchConnectionGrindMaterialOverride Other) const
	{
		return Player == Other.Player;
	}
}

UCLASS(Abstract)
class AHoverPerchConnectionGrindSpline : AHoverPerchGrindSpline
{
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface MioRightActiveMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface MioLeftActiveMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ZoeRightActiveMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ZoeLeftActiveMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInterface RightInactiveMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInterface LeftInactiveMaterial;

	TArray<FHoverPerchConnectionGrindMaterialOverride> LeftSideMaterialOverrides;
	TArray<FHoverPerchConnectionGrindMaterialOverride> RightSideMaterialOverrides;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ResetBothMaterials();
	}

	void SetMaterial(EHoverPerchConnectionGrindMaterialType MaterialType, EHoverPerchConnectionGrindMeshSide Side, AHazePlayerCharacter Player)
	{
		FHoverPerchConnectionGrindMaterialOverride Override;
		Override.Player = Player;
		Override.MaterialType = MaterialType;

		if(Side == EHoverPerchConnectionGrindMeshSide::Left)
		{
			LeftSideMaterialOverrides.AddUnique(Override);
			RightSideMaterialOverrides.Remove(FHoverPerchConnectionGrindMaterialOverride(Player));
		}
		else
		{
			RightSideMaterialOverrides.AddUnique(Override);
			LeftSideMaterialOverrides.Remove(FHoverPerchConnectionGrindMaterialOverride(Player));
		}

		UpdateGrindMaterials();
	}

	void ResetMaterials(AHazePlayerCharacter Player)
	{
		LeftSideMaterialOverrides.Remove(FHoverPerchConnectionGrindMaterialOverride(Player));
		RightSideMaterialOverrides.Remove(FHoverPerchConnectionGrindMaterialOverride(Player));
		UpdateGrindMaterials();
	}

	private void ResetBothMaterials()
	{
		for(UStaticMeshComponent Mesh : Meshes)
		{
			Mesh.SetMaterial(1, RightInactiveMaterial);
			Mesh.SetMaterial(2, LeftInactiveMaterial);
		}
	}

	private void UpdateGrindMaterials()
	{
		for(UStaticMeshComponent Mesh : Meshes)
		{
			if(Mesh.Materials.Num() == 2)
			{
				FHoverPerchConnectionGrindMaterialOverride MaterialOverride = GetCurrentRightSideMaterialOverride();
				if(MaterialOverride.MaterialType == EHoverPerchConnectionGrindMaterialType::None)
					MaterialOverride = GetCurrentLeftSideMaterialOverride();

				Mesh.SetMaterial(1, GetMaterial(MaterialOverride, EHoverPerchConnectionGrindMeshSide::Right));
			}
			else
			{
				FHoverPerchConnectionGrindMaterialOverride MaterialOverride = GetCurrentRightSideMaterialOverride();
				Mesh.SetMaterial(1, GetMaterial(MaterialOverride, EHoverPerchConnectionGrindMeshSide::Right));

				MaterialOverride = GetCurrentLeftSideMaterialOverride();
				Mesh.SetMaterial(2, GetMaterial(MaterialOverride, EHoverPerchConnectionGrindMeshSide::Left));
			}
		}
	}

	FHoverPerchConnectionGrindMaterialOverride GetCurrentRightSideMaterialOverride() const
	{
		FHoverPerchConnectionGrindMaterialOverride Value;
		if(RightSideMaterialOverrides.Num() > 0)
			Value = RightSideMaterialOverrides[0];

		return Value;
	}

	FHoverPerchConnectionGrindMaterialOverride GetCurrentLeftSideMaterialOverride() const
	{
		FHoverPerchConnectionGrindMaterialOverride Value;
		if(LeftSideMaterialOverrides.Num() > 0)
			Value = LeftSideMaterialOverrides[0];

		return Value;
	}

	UMaterialInterface GetMaterial(FHoverPerchConnectionGrindMaterialOverride Override, EHoverPerchConnectionGrindMeshSide MeshSide) const
	{
		if(Override.MaterialType != EHoverPerchConnectionGrindMaterialType::None)
			return GetMaterial(Override);

		if(MeshSide == EHoverPerchConnectionGrindMeshSide::Right)
			return RightInactiveMaterial;

		return LeftInactiveMaterial;
	}

	UMaterialInterface GetMaterial(FHoverPerchConnectionGrindMaterialOverride Override) const
	{
		switch(Override.MaterialType)
		{
			case EHoverPerchConnectionGrindMaterialType::None:
				devError("Tried to get material from material type none");
				return nullptr;
			case EHoverPerchConnectionGrindMaterialType::RightArrow:
				if(Override.Player.IsMio())
					return MioRightActiveMaterial;
				else
					return ZoeRightActiveMaterial;
			case EHoverPerchConnectionGrindMaterialType::LeftArrow:
				if(Override.Player.IsMio())
					return MioLeftActiveMaterial;
				else
					return ZoeLeftActiveMaterial;
		}
	}
}