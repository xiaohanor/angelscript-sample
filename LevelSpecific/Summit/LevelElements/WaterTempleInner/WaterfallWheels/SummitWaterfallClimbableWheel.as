class ASummitWaterfallClimbableWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot; 

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent WheelMesh;

	UPROPERTY(DefaultComponent)
	UBabyDragonTailClimbFreeFormResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WaterAcceleration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxRotationSpeed = 50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect AttachedRumble;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> AttachedCameraShake;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitWaterfallButton LeftRotationButton;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitWaterfallButton RightRotationButton;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent CrumbRotatorComp;
	default CrumbRotatorComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	float CurrentRotationSpeed = 0.0;

	bool bAnyButtonIsActive = false;
	bool bDragonIsAttached = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		ResponseComp.OnTailAttached.AddUFunction(this, n"OnTailAttachedToClimbWheel");
		ResponseComp.OnTailReleased.AddUFunction(this, n"OnTailReleasedFromClimbWheel");
		if(LeftRotationButton != nullptr)
		{
			LeftRotationButton.OnPressed.AddUFunction(this, n"OnButtonPressed");
			LeftRotationButton.OnUnPressed.AddUFunction(this, n"OnButtonUnPressed");
		}
		if(RightRotationButton != nullptr)
		{
			RightRotationButton.OnPressed.AddUFunction(this, n"OnButtonPressed");
			RightRotationButton.OnUnPressed.AddUFunction(this, n"OnButtonUnPressed");
		}
	}

	UFUNCTION()
	private void OnButtonPressed()
	{
		bAnyButtonIsActive = true;
		if(bDragonIsAttached)
			ToggleShakesAndRumbles(true);
	}

	UFUNCTION()
	private void OnButtonUnPressed()
	{
		if(LeftRotationButton != nullptr
		&& RightRotationButton != nullptr)
		{
			if(!LeftRotationButton.bIsPressed
			&& !RightRotationButton.bIsPressed)
			{
				bAnyButtonIsActive = false;
				if(bDragonIsAttached)
					ToggleShakesAndRumbles(false);
			}
		}
		else
		{
			bAnyButtonIsActive = false;
			if(bDragonIsAttached)
				ToggleShakesAndRumbles(false);
		}
	}

	UFUNCTION()
	private void OnTailAttachedToClimbWheel(FBabyDragonTailClimbFreeFormAttachParams Params)
	{
		bDragonIsAttached = true;

		if(bAnyButtonIsActive)
			ToggleShakesAndRumbles(true);
	}

	UFUNCTION()
	private void OnTailReleasedFromClimbWheel(FBabyDragonTailClimbFreeFormReleasedParams Params)
	{
		bDragonIsAttached = false;

		ToggleShakesAndRumbles(false);
	}

	private void ToggleShakesAndRumbles(bool bToggleOn)
	{
		if(bToggleOn)
		{
			auto Player = Game::Zoe;
			Player.PlayCameraShake(AttachedCameraShake, this);
			Player.PlayForceFeedback(AttachedRumble, true, false, this);
		}
		else
		{
			auto Player = Game::Zoe;
			Player.StopCameraShakeByInstigator(this);
			Player.StopForceFeedback(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			if(LeftRotationButton != nullptr
				&& LeftRotationButton.bIsActive)
				CurrentRotationSpeed = Math::FInterpTo(CurrentRotationSpeed, MaxRotationSpeed, DeltaSeconds, WaterAcceleration);
			else if(RightRotationButton != nullptr
				&& RightRotationButton.bIsActive)
				CurrentRotationSpeed = Math::FInterpTo(CurrentRotationSpeed, -MaxRotationSpeed, DeltaSeconds, WaterAcceleration);
			else
				CurrentRotationSpeed = Math::FInterpTo(CurrentRotationSpeed, 0, DeltaSeconds, WaterAcceleration);

			FRotator AdditionalRotation = FRotator(0, 0, CurrentRotationSpeed * DeltaSeconds);
			RotationRoot.AddLocalRotation(AdditionalRotation);
			CrumbRotatorComp.SetValue(RotationRoot.RelativeRotation);
		}
		else
		{
			RotationRoot.RelativeRotation = CrumbRotatorComp.Value;
		}
	}
}