struct FGameShowArenaDisplayDecalParams
{
	FGameShowArenaDisplayDecalParams(FVector Location, FRotator Rotation, FVector Scale, UTexture InTexture, float DecalOpacity = -1, FLinearColor DecalColor = FLinearColor(1, 1, 1, 1))
	{
		Texture = InTexture;
		DecalWorldTransform = FTransform(Rotation, Location, Scale);
		Tint = DecalColor;
		Opacity = DecalOpacity;
	}

	FGameShowArenaDisplayDecalParams(FTransform Transform, UTexture InTexture, float DecalOpacity = -1, FLinearColor DecalColor = FLinearColor(1, 1, 1, 1))
	{
		Texture = InTexture;
		DecalWorldTransform = Transform;
		Tint = DecalColor;
		Opacity = DecalOpacity;
	}

	FTransform DecalWorldTransform;
	float Opacity = -1;
	UTexture Texture;
	FLinearColor Tint = FLinearColor(1, 1, 1, 1);
}

struct FGameShowArenaSimpleDisplayDecalParams
{
	UPROPERTY()
	float Opacity = 80;
	UPROPERTY()
	UTexture Texture;
	UPROPERTY()
	FLinearColor Tint = FLinearColor(1, 1, 1, 1);
}

UCLASS(NotBlueprintable)
class UGameShowArenaDisplayDecalPlatformComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bTargetAttachedMeshComp;

	private TSoftObjectPtr<UStaticMeshComponent> TargetMeshComp;

	private UMaterialInterface SourceMaterial;

	UMaterialInstanceDynamic TargetMeshDynamicMaterial;

	float MaxOpacity = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bTargetAttachedMeshComp)
		{
			TargetMeshComp = UStaticMeshComponent::Get(Owner);
		}
	}

	void AssignTarget(UStaticMeshComponent MeshComp, UMaterialInterface TargetMaterial)
	{
		SourceMaterial = TargetMaterial;
		TargetMeshComp = MeshComp;
	}

	bool CanUpdateParams()
	{
		if (TargetMeshComp.IsNull() || TargetMeshComp.IsPending())
			return false;

		return true;
	}

	UStaticMeshComponent GetMeshComponent()
	{
		if (!CanUpdateParams())
			return nullptr;

		return TargetMeshComp.Get();
	}

	void UpdateMaterialParameters(FGameShowArenaDisplayDecalParams Params, bool bIsAlternateDecal, FName MaterialSlotName = n"GameShowPanel_01")
	{
		if (TargetMeshDynamicMaterial == nullptr)
		{
			if (TargetMeshComp.IsNull() || TargetMeshComp.IsPending())
				return;

			int Index = TargetMeshComp.Get().GetMaterialIndex(MaterialSlotName);
			TargetMeshDynamicMaterial = TargetMeshComp.Get().CreateDynamicMaterialInstance(Index, SourceMaterial);
			MaxOpacity = TargetMeshDynamicMaterial.GetScalarParameterValue(n"DecalOpacity");
		}
		float Opacity = Params.Opacity;
		if (Params.Opacity < 0)
			Opacity = MaxOpacity;

		if(bIsAlternateDecal)
		{
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Center", FLinearColor(Params.DecalWorldTransform.Location));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Forward", FLinearColor(Params.DecalWorldTransform.Rotation.ForwardVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Up", FLinearColor(Params.DecalWorldTransform.Rotation.UpVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Right", FLinearColor(Params.DecalWorldTransform.Rotation.RightVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Scale", FLinearColor(Params.DecalWorldTransform.Scale3D));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Tint", Params.Tint);
			TargetMeshDynamicMaterial.SetScalarParameterValue(n"Decal1Opacity", Opacity);
			TargetMeshDynamicMaterial.SetTextureParameterValue(n"Decal1Texture", Params.Texture);
		}
		else
		{
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalCenter", FLinearColor(Params.DecalWorldTransform.Location));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalForward", FLinearColor(Params.DecalWorldTransform.Rotation.ForwardVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalUp", FLinearColor(Params.DecalWorldTransform.Rotation.UpVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalRight", FLinearColor(Params.DecalWorldTransform.Rotation.RightVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalScale", FLinearColor(Params.DecalWorldTransform.Scale3D));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalTint", Params.Tint);
			TargetMeshDynamicMaterial.SetScalarParameterValue(n"DecalOpacity", Opacity);
			TargetMeshDynamicMaterial.SetTextureParameterValue(n"DecalTexture", Params.Texture);
		}
	}

	void UpdateMaterialParameters(FGameShowArenaSimpleDisplayDecalParams SimpleParams, bool bIsAlternateDecal, FName MaterialSlotName = n"GameShowPanel_01")
	{
		if (TargetMeshDynamicMaterial == nullptr)
		{
			if (TargetMeshComp.IsNull() || TargetMeshComp.IsPending())
				return;

			int Index = TargetMeshComp.Get().GetMaterialIndex(MaterialSlotName);
			TargetMeshDynamicMaterial = TargetMeshComp.Get().CreateDynamicMaterialInstance(Index, SourceMaterial);
			MaxOpacity = TargetMeshDynamicMaterial.GetScalarParameterValue(n"DecalOpacity");
		}
		FTransform TargetTransform = TargetMeshComp.Get().WorldTransform;
		FVector ForwardOffset = -TargetTransform.Rotation.ForwardVector * 15;
		FVector RightOffset = -TargetTransform.Rotation.RightVector * 15;
		
		if(bIsAlternateDecal)
		{
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Center", FLinearColor(TargetTransform.Location + ForwardOffset + RightOffset));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Forward", FLinearColor(TargetTransform.Rotation.ForwardVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Up", FLinearColor(TargetTransform.Rotation.UpVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Right", FLinearColor(TargetTransform.Rotation.RightVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Scale", FLinearColor(FVector::OneVector * 175));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"Decal1Tint", SimpleParams.Tint);
			TargetMeshDynamicMaterial.SetScalarParameterValue(n"Decal1Opacity", SimpleParams.Opacity);
			TargetMeshDynamicMaterial.SetTextureParameterValue(n"Decal1Texture", SimpleParams.Texture);
		}
		else
		{
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalCenter", FLinearColor(TargetTransform.Location + ForwardOffset + RightOffset));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalForward", FLinearColor(TargetTransform.Rotation.ForwardVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalUp", FLinearColor(TargetTransform.Rotation.UpVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalRight", FLinearColor(TargetTransform.Rotation.RightVector));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalScale", FLinearColor(FVector::OneVector * 175));
			TargetMeshDynamicMaterial.SetVectorParameterValue(n"DecalTint", SimpleParams.Tint);
			TargetMeshDynamicMaterial.SetScalarParameterValue(n"DecalOpacity", SimpleParams.Opacity);
			TargetMeshDynamicMaterial.SetTextureParameterValue(n"DecalTexture", SimpleParams.Texture);
		}
	}

	void ClearMaterialParameters(bool bIsAlternateDecal)
	{
		if (TargetMeshDynamicMaterial == nullptr)
			return;
		if (bIsAlternateDecal)
		{
			TargetMeshDynamicMaterial.SetScalarParameterValue(n"Decal1Opacity", 0);
			TargetMeshDynamicMaterial.SetTextureParameterValue(n"Decal1Texture", nullptr);
		}
		else
		{
			TargetMeshDynamicMaterial.SetScalarParameterValue(n"DecalOpacity", 0);
			TargetMeshDynamicMaterial.SetTextureParameterValue(n"DecalTexture", nullptr);
		}
	}
};