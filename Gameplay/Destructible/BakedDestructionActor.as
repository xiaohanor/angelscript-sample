class ABakedDestructionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazePropComponent OriginalComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazePropComponent BrokenComp;
	default BrokenComp.SetHiddenInGame(true);

	//Runs time based logic internally
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BakedDestructionTimeIterateCapability");

	UPROPERTY()
	TArray<UMaterialInstanceDynamic> DynamicMaterials;

	int MaxDisplayFrame;

	bool bRunTimeBased;
	float SpeedMultiplier;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0; i < BrokenComp.Materials.Num(); i++)
		{
			UMaterialInstanceDynamic DynamicMat =  Material::CreateDynamicMaterialInstance(this, BrokenComp.Materials[i]);
			DynamicMaterials.Add(DynamicMat);
			BrokenComp.SetMaterial(i, DynamicMat);
			DynamicMaterials[i].SetScalarParameterValue(n"Auto Playback", 0);
			DynamicMaterials[i].SetScalarParameterValue(n"Display Frame", 1.0);
			
			UTexture2D Texture = Cast<UTexture2D>(DynamicMaterials[i].GetTextureParameterValue(n"Position Texture"));
	
			// if (!devEnsure(Texture != nullptr, "Position Texture on baked destruction actor not found. Make sure to get the correct dynamic material"))
			// {
			// 	return;
			// }
			// else
			// {
			// 	MaxDisplayFrame = Texture.Blueprint_GetSizeY();
			// }

			if (Texture != nullptr)
				MaxDisplayFrame = Texture.Blueprint_GetSizeY();
		}
	}

	//Runs custom destruction for BP specific setups - timelines etc.
	UFUNCTION()
	void StartCustomDestructible()
	{
		BrokenComp.SetHiddenInGame(false);
		OriginalComp.SetHiddenInGame(true);
		BP_ActivateDestruction();
		FOnBakedDestructionTriggeredParams Params;
		
		//Mainly for Audio
		//TODO - would be nice to have a way for the correct EBP asset already loaded in on BP created?
		Params.WorldLocation = ActorLocation;
		UBakedDestructionEffectHandler::Trigger_OnDestroyObjectTriggered(this, Params);
	}	

	//TODO - change to speed multiplier, and calculate frames correctly based on 24FPS
	UFUNCTION()
	void StartDestructible(float NewSpeedMultiplier = 1.0)
	{
		BrokenComp.SetHiddenInGame(false);
		OriginalComp.SetHiddenInGame(true);
		bRunTimeBased = true;
		SpeedMultiplier = NewSpeedMultiplier;
	}

	//Event for VFX to hook into
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BP_ActivateDestruction() {}

	//Run individual frames diferrently
	UFUNCTION()
	void SetDynamicMaterialDisplayFrame(int Index, float DisplayFrame)
	{
		DynamicMaterials[Index].SetScalarParameterValue(n"Display Frame", DisplayFrame);
	}

	//Run all materials the same
	UFUNCTION()
	void SetDynamicMaterialDisplayFrameAll(float DisplayFrame)
	{
				for (UMaterialInstanceDynamic Mat : DynamicMaterials)
		{
			Mat.SetScalarParameterValue(n"Display Frame", DisplayFrame);
		}
	}

	//Internal time based - run through capability
	void SetDynamicMaterialDisplayFrameTimeBased(int DisplayFrame)
	{
		for (UMaterialInstanceDynamic Mat : DynamicMaterials)
		{
			Mat.SetScalarParameterValue(n"Display Frame", DisplayFrame);
		}
	}
}