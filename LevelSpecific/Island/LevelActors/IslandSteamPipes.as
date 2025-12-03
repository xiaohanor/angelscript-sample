enum EIslandSteamPipeStates
{
	Idle,
	Preparing,
	Active
};

class AIslandSteamPipes : AHazeActor
{
	//Components
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent PipeMesh;

	UPROPERTY(DefaultComponent, Attach = "PipeMesh")
	UNiagaraComponent Steam;

	UPROPERTY(DefaultComponent, Attach = "PipeMesh")
	UPointLightComponent Light;
	default Light.Mobility = EComponentMobility::Stationary;

	UPROPERTY(DefaultComponent, Attach = "Steam")
	UCapsuleComponent DeathVolume;
	default DeathVolume.SetCollisionProfileName(n"TriggerOnlyPlayer", false);

	//Internal variables
	default PrimaryActorTick.bStartWithTickEnabled = false;
	TArray<AHazePlayerCharacter> OverlappingPlayers;
	EIslandSteamPipeStates State = EIslandSteamPipeStates::Idle;
	float CurrentWaitTime = 0.0;
	float TargetLightIntensity = 0.0;


	//Instance editable variables
	UPROPERTY(EditAnywhere)
	float IdleTime = 4.0;

	UPROPERTY(EditAnywhere)
	float PreparingTime = 2.0;

	UPROPERTY(EditAnywhere)
	float ActiveTime = 5.0;

	UPROPERTY(EditAnywhere)
	UMaterialInterface WarningMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInterface IdleMaterial;

	UPROPERTY(EditAnywhere)
	float WarningMaxIntensity = 500;

	UPROPERTY(EditAnywhere)
	float IdleIntensity = 100;

	UPROPERTY(EditAnywhere)
	FLinearColor WarningColor = FLinearColor::Red;

	UPROPERTY(EditAnywhere)
	FLinearColor IdleColor = FLinearColor::Blue;


	//References
	UPROPERTY(EditInstanceOnly)
	APlayerTrigger ActivationVolume;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Light.SetIntensity(WarningMaxIntensity);
		Light.SetLightColor(WarningColor, true);
	}


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(ActivationVolume != nullptr)
		{
			ActivationVolume.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
			ActivationVolume.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
			DeathVolume.OnComponentBeginOverlap.AddUFunction(this, n"OnEnterDeathVolume");
		}
		
		CurrentWaitTime = IdleTime;
	}

	UFUNCTION()
	void OnEnterDeathVolume(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			Player.KillPlayer();
		}
	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		
		OverlappingPlayers.AddUnique(Player);

		if(OverlappingPlayers.Num() > 0)
		{
			EnablePipes();
		}
	}

	UFUNCTION()
	void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Remove(Player);

		if(OverlappingPlayers.Num() <= 0)
		{
			DisablePipes();
		}
	}

	UFUNCTION()
	void EnablePipes()
	{
		SetActorTickEnabled(true);
		UpdateAssets(State);
		Print("Start", 2.0, FLinearColor::White);
	}

	UFUNCTION()
	void DisablePipes()
	{
		SetActorTickEnabled(false);
		UpdateAssets(EIslandSteamPipeStates::Idle);
		
		Print("Stop", 2.0, FLinearColor::White);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentWaitTime -= DeltaSeconds;

		if(CurrentWaitTime <= 0)
		{
			switch(State)
			{
				case EIslandSteamPipeStates::Idle:
					State = EIslandSteamPipeStates::Preparing;
					CurrentWaitTime = PreparingTime;
					UpdateAssets(State);
					break;

				case EIslandSteamPipeStates::Preparing:
					State = EIslandSteamPipeStates::Active;
					CurrentWaitTime = ActiveTime;
					UpdateAssets(State);
					break;

				case EIslandSteamPipeStates::Active:
					State = EIslandSteamPipeStates::Idle;
					CurrentWaitTime = IdleTime;
					UpdateAssets(State);
					break;
			}
		}

		if(State == EIslandSteamPipeStates::Preparing)
		{
			TargetLightIntensity = ((Math::Sin(GameTimeSinceCreation*4)+1)/2)*WarningMaxIntensity;
		}

		Light.SetIntensity(Math::FInterpTo(Light.Intensity, TargetLightIntensity, DeltaSeconds, 3));
	}

	UFUNCTION()
	void UpdateAssets(EIslandSteamPipeStates NewState)
	{
		switch(NewState)
		{
			case EIslandSteamPipeStates::Idle:
				Steam.Deactivate();
				PipeMesh.SetMaterial(1,IdleMaterial);
				Light.SetLightColor(IdleColor);
				TargetLightIntensity = IdleIntensity;
				DeathVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				break;

			case EIslandSteamPipeStates::Preparing:
				Steam.Deactivate();
				PipeMesh.SetMaterial(1, WarningMaterial);
				Light.SetLightColor(WarningColor);
				DeathVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				break;

			case EIslandSteamPipeStates::Active:
				Steam.Activate(true);
				PipeMesh.SetMaterial(1, WarningMaterial);
				Light.SetLightColor(WarningColor);
				TargetLightIntensity = WarningMaxIntensity;
				DeathVolume.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
				break;
		}
	}
}