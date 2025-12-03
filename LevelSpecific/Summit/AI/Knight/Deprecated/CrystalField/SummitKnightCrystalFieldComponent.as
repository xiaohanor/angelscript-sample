class USummitKnightCrystalFieldComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<ASummitKnightCrystalField> CrystalFieldClass;

	ASummitKnightCrystalField CrystalField;

	UMaterialInstanceDynamic Material;
	float ScaleSpeed = 2.5;
	float Scale = 0;
	bool bShow;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		CrystalField = SpawnActor(CrystalFieldClass);
		CrystalField.AttachToActor(HazeOwner);
		Material = CrystalField.Mesh.CreateDynamicMaterialInstance(0);
		Material.SetScalarParameterValue(n"Scale", 0);
	}

	void Show()
	{
		bShow = true;

		if(Scale <= 0)
			USummitKnightCrystalFieldEffectHandler::Trigger_OnFieldSpawned(CrystalField);
	}

	void Hide()
	{
		bShow = false;
	}

	void Break()
	{
		USummitKnightCrystalFieldEffectHandler::Trigger_OnFieldBreak(CrystalField);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShow && Scale > 1)
			return;
		if(!bShow && Scale < 0)
			return;

		float Dir = bShow ? 1 : -1;
		Scale += DeltaSeconds * ScaleSpeed * Dir;
		Material.SetScalarParameterValue(n"Scale", Math::Clamp(Scale, 0, 1));

		if(bShow && Scale > 1)
			USummitKnightCrystalFieldEffectHandler::Trigger_OnFieldCompleted(CrystalField);
		if(!bShow && Scale < 0)
			USummitKnightCrystalFieldEffectHandler::Trigger_OnFieldUnspawned(CrystalField);
	}
}