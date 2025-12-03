enum EIslandStormdrainBoilStates
{
	Idle,
	Boiling,
	Overloaded
}

class AIslandStormdrainBoilingFloor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = "MovingRoot")
	UStaticMeshComponent MovingPlatform;

	UPROPERTY(DefaultComponent, Attach = "MovingPlatform")
	UStaticMeshComponent ShootMesh;

	UPROPERTY(DefaultComponent, Attach = "ShootMesh")
	UIslandRedBlueImpactCounterResponseComponent ImpactComp;

	//default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	EIslandStormdrainBoilStates State = EIslandStormdrainBoilStates::Idle;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UIslandRedBlueImpactCounterResponseComponentSettings MioSettings;

	UPROPERTY()
	UIslandRedBlueImpactCounterResponseComponentSettings ZoeSettings;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditInstanceOnly)
	float MaxCooldown = 20;
	float Cooldown;

	UPROPERTY(EditInstanceOnly)
	float NormalBoilHeight = 200;

	UPROPERTY(EditInstanceOnly)
	float OverloadHeight = 500;
	float TargetHeight = 0;
	float CurrentHeight = 0;
	
	UPROPERTY(EditInstanceOnly)
	float OverloadDuration = 5;
	float OverloadActiveTimer = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ShootMesh.SetMaterial(0, MioMaterial);
			ImpactComp.Settings = MioSettings;
		}

		else
		{
			ShootMesh.SetMaterial(0, ZoeMaterial);
			ImpactComp.Settings = ZoeSettings;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveAnimation.BindUpdate(this, n"TL_Update");
		MoveAnimation.BindFinished(this, n"TL_Finished");
		ImpactComp.OnFullAlpha.AddUFunction(this, n"OnFullAlpha");
		Activate();
	}

	UFUNCTION()
	void Activate()
	{
		GoToState(EIslandStormdrainBoilStates::Idle);
		SetActorTickEnabled(true);
		Cooldown = Math::RandRange(0, MaxCooldown);
	}

	UFUNCTION()
	void Deactivate()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		switch(State)
		{
			case EIslandStormdrainBoilStates::Idle:
				Cooldown -= DeltaSeconds;
				if(Cooldown <= 0)
				{
					MoveAnimation.Play();
					GoToState(EIslandStormdrainBoilStates::Boiling);
				}
				break;
			
			case EIslandStormdrainBoilStates::Boiling:
				break;

			case EIslandStormdrainBoilStates::Overloaded:
				OverloadActiveTimer -= DeltaSeconds;
				if(OverloadActiveTimer < 0)
				{
					GoToState(EIslandStormdrainBoilStates::Idle);
				}
		}

		CurrentHeight = Math::FInterpTo(CurrentHeight, TargetHeight, DeltaSeconds, 2);
		MovingRoot.SetRelativeLocation(FVector(0,0,CurrentHeight));
	}

	UFUNCTION()
	void TL_Update(float CurveValue)
	{
		TargetHeight = CurveValue * NormalBoilHeight;
	}

	UFUNCTION()
	void TL_Finished()
	{
		if(State == EIslandStormdrainBoilStates::Boiling)
		{
			GoToState(EIslandStormdrainBoilStates::Idle);
		}
	}

	UFUNCTION()
	void OnFullAlpha(AHazePlayerCharacter Player)
	{
		GoToState(EIslandStormdrainBoilStates::Overloaded);
	}

	void GoToState(EIslandStormdrainBoilStates NewState)
	{
		switch(NewState)
		{
			case EIslandStormdrainBoilStates::Idle:
				State = EIslandStormdrainBoilStates::Idle;
				Cooldown = MaxCooldown;
				TargetHeight = 0;
				break;
			
			case EIslandStormdrainBoilStates::Boiling:
				State = EIslandStormdrainBoilStates::Boiling;
				MoveAnimation.PlayFromStart();
				break;

			case EIslandStormdrainBoilStates::Overloaded:
				State = EIslandStormdrainBoilStates::Overloaded;
				MoveAnimation.Stop();
				TargetHeight = OverloadHeight;
				OverloadActiveTimer = OverloadDuration;
				break;
		}
	}
}