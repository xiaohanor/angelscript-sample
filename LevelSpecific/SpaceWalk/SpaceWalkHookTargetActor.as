class ASpaceWalkTargetHookActor : AHazeActor

{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent HookMesh;
	default HookMesh.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent)
	USpaceWalkHookPointComponent HookPoint;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 70000;

	FVector StartLocation;

	float ShakeAmountX;
	float ShakeAmountY;
	float ShakeAmountZ;

	UPROPERTY(EditAnywhere)
	float ShakeSpeed = 1;

	UPROPERTY(EditAnywhere)
	float Amplitude = 1.0;

	FVector LerpBackLocation;
	float LerpBackTimer = -1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorRelativeLocation;

		FRandomStream Stream(GetName().Hash);
		ShakeAmountX = Stream.RandRange(10,15);
		ShakeAmountY = Stream.RandRange(10,15);
		ShakeAmountZ = Stream.RandRange(10,15);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		LerpBackTimer = 0.0;
		LerpBackLocation = ActorRelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float SineMove = Math::Sin(Time::PredictedGlobalCrumbTrailTime * ShakeSpeed) * Amplitude;
		FVector WantedLocation = StartLocation + FVector(ShakeAmountX, ShakeAmountY , ShakeAmountZ) * SineMove;

		if (LerpBackTimer >= 0.0)
		{
			LerpBackTimer += DeltaSeconds;
			ActorRelativeLocation = Math::Lerp(LerpBackLocation, WantedLocation, Math::EaseInOut(0, 1, Math::Saturate(LerpBackTimer), 2));
			if (LerpBackTimer >= 1.0)
				LerpBackTimer = -1.0;
		}
		else
		{
			ActorRelativeLocation = WantedLocation;
		}
	}
};