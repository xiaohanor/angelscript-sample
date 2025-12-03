class UIslandWalkerHeadHatchShootablePanel : UStaticMeshComponent
{
	default CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);

	UPROPERTY(EditDefaultsOnly)
	TArray<int> RedBlueMaterialIndices;
	default RedBlueMaterialIndices.Add(0);

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface MioMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ZoeMaterial;

	UMaterialInstanceDynamic MaterialInstance;

	bool bHidden = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Start hidden
		Hide();
	}

	void SetColor(AHazePlayerCharacter Player)
	{
		UMaterialInterface Template = Player.IsMio() ? MioMaterial : ZoeMaterial;
		MaterialInstance = Material::CreateDynamicMaterialInstance(this, Template);
		for (int iMat : RedBlueMaterialIndices)
		{
			SetMaterial(iMat, MaterialInstance);
		}
	}

	void Hide()
	{
		if (bHidden)
			return;

		bHidden = true;
		AddComponentVisualsBlocker(this);
		for (int i = 0; i < NumChildrenComponents; i++)
		{
			if (GetChildComponent(i) != nullptr)
				GetChildComponent(i).AddComponentVisualsBlocker(this);
		}
	}

	void Show()
	{
		if (!bHidden)
			return;

		bHidden = false;
		RemoveComponentVisualsBlocker(this);
		for (int i = 0; i < NumChildrenComponents; i++)
		{
			if (GetChildComponent(i) != nullptr)
				GetChildComponent(i).RemoveComponentVisualsBlocker(this);
		}
	}
}
