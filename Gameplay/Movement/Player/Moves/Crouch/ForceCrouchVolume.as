UCLASS(HideCategories = "Navigation Collision Rendering Debug Actor Cooking", Meta = (HighlightPlacement))
class AForceCrouchVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default BrushColor = FLinearColor(1.0, 0.3, 0.7);
	default BrushComponent.LineThickness = 4.0;

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(EditAnywhere)
	private bool bEnabled = true;

	UPROPERTY(EditAnywhere, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSetting;
	UPROPERTY(EditAnywhere, Category = "Camera")
	float BlendTime = 2.0;

	UPROPERTY(EditAnywhere)
	UPlayerCrouchSettings CrouchSettings;

	UPROPERTY(EditAnywhere)
	bool bTriggerForMio = true;

	UPROPERTY(EditAnywhere)
	bool bTriggerForZoe = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");
	}

	UFUNCTION()
	void OnPlayerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		if (!bEnabled)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player.IsMio() && !bTriggerForMio)
			return;
		if (Player.IsZoe() && !bTriggerForZoe)
			return;
		
		SetCrouching(Player);
	}

	UFUNCTION()
	void OnPlayerEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		if (Player.IsMio() && !bTriggerForMio)
			return;
		if (Player.IsZoe() && !bTriggerForZoe)
			return;

		ClearCrouching(Player);
	}

	UFUNCTION()
	void SetEnabled(bool bEnable)
	{
		bEnabled = bEnable;

		VerifyOverlappingActors();
	}

	void VerifyOverlappingActors()
	{
		TArray<AActor> OverlappingActors;
		GetOverlappingActors(OverlappingActors, AHazePlayerCharacter);

		for(auto Actor : OverlappingActors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

			if(Player != nullptr)
			{
				if(bEnabled)
					SetCrouching(Player);
				else
					ClearCrouching(Player);
			}
		}
	}

	void SetCrouching(AHazePlayerCharacter Player)
	{
		Player.ApplyCrouch(this);

		auto PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);
		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			if(CameraSetting != nullptr)
				Player.ApplyCameraSettings(CameraSetting, BlendTime, this, EHazeCameraPriority::Low);
		}

		if(CrouchSettings != nullptr)
			Player.ApplySettings(CrouchSettings, this, EHazeSettingsPriority::Gameplay);
	}

	void ClearCrouching(AHazePlayerCharacter Player)
	{
		Player.ClearCrouch(this);

		Player.ClearCameraSettingsByInstigator(this, 2);
		Player.ClearSettingsByInstigator(this);
	}
}