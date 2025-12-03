class USkylinePlayerVisibilityComponent : UActorComponent
{
	UPROPERTY()
	bool bRenderedForOwner = false;

	UPROPERTY()
	FName AttachSocket = n"Hips";

	UPROPERTY()
	FName WeaponAttachSocket = n"RightHand";

	UPROPERTY()
	UClass HazeSphereClass;

	UPROPERTY()
	float HazeSphereRadius = 500.0;

	UPROPERTY()
	float HazeSphereOpacity = 1.0;

	UPROPERTY()
	FLinearColor HazeSphereColor = FLinearColor::Red;

	UPROPERTY()
	float LightIntensity = 1.0;

	UPROPERTY()
	float LightRadius = 500.0;

	UPROPERTY()
	FLinearColor LightColor = FLinearColor::Red;

	UPROPERTY()
	FLinearColor OutfitTint = FLinearColor::White;

	UPROPERTY()
	FLinearColor OutfitEmissiveTint = FLinearColor::White;

	UPROPERTY()
	FLinearColor BodyTint = FLinearColor::White;

	UPROPERTY()
	FLinearColor EyesTint = FLinearColor::White;

	UPROPERTY()
	UTexture EmissiveTexture;

	UPROPERTY()
	UMaterialInterface FootDecal;
	TArray<UDecalComponent> Decals;

	TMap<int, UMaterialInstanceDynamic> OutfitMats;
	TMap<int, UMaterialInstanceDynamic> BodyMats;
	TMap<int, UMaterialInstanceDynamic> EyesMats;

	TArray<UMaterialInterface> OriginalMats;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void ApplyMaterialOverrides()
	{
		PrintToScreen("MATERIAL OVERRIDE", 5.0, FLinearColor::Red);

		auto Player = Cast<AHazePlayerCharacter>(Owner);
		auto Mesh = Player.Mesh;

		OriginalMats = Mesh.GetMaterials();

		if (Player.IsMio())
		{
			OutfitMats.Add(0, Mesh.CreateDynamicMaterialInstance(0));
			OutfitMats.Add(1, Mesh.CreateDynamicMaterialInstance(1));
			OutfitMats.Add(5, Mesh.CreateDynamicMaterialInstance(5));

			BodyMats.Add(3, Mesh.CreateDynamicMaterialInstance(3));
			BodyMats.Add(4, Mesh.CreateDynamicMaterialInstance(4));
			BodyMats.Add(6, Mesh.CreateDynamicMaterialInstance(6));
			BodyMats.Add(7, Mesh.CreateDynamicMaterialInstance(7));

			EyesMats.Add(2, Mesh.CreateDynamicMaterialInstance(2));
		}
		else
		{
			OutfitMats.Add(5, Mesh.CreateDynamicMaterialInstance(5));
			OutfitMats.Add(6, Mesh.CreateDynamicMaterialInstance(6));

			BodyMats.Add(0, Mesh.CreateDynamicMaterialInstance(0));
			BodyMats.Add(1, Mesh.CreateDynamicMaterialInstance(1));
			BodyMats.Add(3, Mesh.CreateDynamicMaterialInstance(3));
			BodyMats.Add(4, Mesh.CreateDynamicMaterialInstance(4));

			EyesMats.Add(2, Mesh.CreateDynamicMaterialInstance(2));
		}

		for (auto OutfitMat : OutfitMats)
		{
			OutfitMat.Value.SetVectorParameterValue(n"Tint", OutfitTint);
			OutfitMat.Value.SetVectorParameterValue(n"EmissiveTint", OutfitEmissiveTint);
			OutfitMat.Value.SetScalarParameterValue(n"HazeToggleCategory_SeparateEmissiveTexture", 1.0);
			OutfitMat.Value.SetTextureParameterValue(n"TexM4", EmissiveTexture);
			Mesh.SetMaterial(OutfitMat.Key, OutfitMat.Value);
		}

		for (auto BodyMat : BodyMats)
		{
			BodyMat.Value.SetVectorParameterValue(n"Tint", BodyTint);
			Mesh.SetMaterial(BodyMat.Key, BodyMat.Value);
		}

		for (auto EyesMat : EyesMats)
		{
			EyesMat.Value.SetVectorParameterValue(n"ScleraTint", BodyTint);
			EyesMat.Value.SetVectorParameterValue(n"IrisTint", BodyTint);
			Mesh.SetMaterial(EyesMat.Key, EyesMat.Value);
		}
	}

	void ClearMaterialOverrides()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		auto Mesh = Player.Mesh;

		for (int i = 0; i < OriginalMats.Num(); i++)
		{
			Mesh.SetMaterial(i, OriginalMats[i]);
		}
	}

	void CreateFootDecals()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		auto Mesh = Player.Mesh;

		auto LeftFootDecal = UDecalComponent::Create(Owner);
		LeftFootDecal.SetDecalMaterial(FootDecal);
		LeftFootDecal.RelativeScale3D = FVector(0.025, 0.05, 0.1);
		LeftFootDecal.AttachToComponent(Mesh, n"LeftFootAudioTrace");
		FTransform LeftFootTransform =	Mesh.GetSocketTransform(n"LeftFootAudioTrace", ERelativeTransformSpace::RTS_Component);
		LeftFootDecal.RelativeLocation = LeftFootTransform.TransformVectorNoScale(FVector(-0.5, 0.0, 0.0));

		auto RightFootDecal = UDecalComponent::Create(Owner);
		RightFootDecal.SetDecalMaterial(FootDecal);
		RightFootDecal.RelativeScale3D = FVector(0.025, 0.05, 0.1);
		RightFootDecal.AttachToComponent(Mesh, n"RightFootAudioTrace");
		FTransform RightFootTransform =	Mesh.GetSocketTransform(n"RightFootAudioTrace", ERelativeTransformSpace::RTS_Component);
		RightFootDecal.RelativeLocation = RightFootTransform.TransformVectorNoScale(FVector(-0.5, 0.0, 0.0));
	}

	void RemoveFootDecals()
	{
	}
};