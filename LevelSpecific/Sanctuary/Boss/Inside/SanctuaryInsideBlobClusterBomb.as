UCLASS(Abstract)
class USanctuaryInsideBlobClusterBombEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand()
	{
	}

};	
class ASanctuaryInsideBlobClusterBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent LandingDecal;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;	

	float ArcHeight = 700.0;
	float FlightTime = 0.0;
	float FlightDuration;
	float GrowingScale = 1.0;
	float DamageRadius = 100.0;
	FVector StartLocation;
	FVector TargetLocation;

	FVector TargetOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		FlightDuration = Math::RandRange(1.7, 2.3);
		USanctuaryInsideBlobClusterBombEventHandler::Trigger_OnActivated(this);

		LandingDecal.SetWorldLocation(TargetLocation + FVector(0.0, 0.0, 0.0));
		LandingDecal.DetachFromParent(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		FlightTime += DeltaSeconds;
		float Alpha = Math::Min(1.0, FlightTime / FlightDuration);

		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		FVector Direction = (Location - ActorLocation).GetSafeNormal(); 

		ActorLocation = Location;
		ActorScale3D = FVector::OneVector; 

		float DecalScale = Alpha * 0.3;
		LandingDecal.SetWorldScale3D(FVector(1.0, DecalScale, DecalScale));

		// ActorScale3D = FVector::OneVector + FVector::OneVector * (1.0 - Alpha) * 0.0; 
		if (Alpha >= 1.0)
			Explode(Direction);
	}

	void Explode(FVector Direction)
	{
			for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < DamageRadius)
				Player.DamagePlayerHealth(0.5);
		}

		LandingDecal.SetHiddenInGame(true);
		BP_Explode();
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		USanctuaryInsideBlobClusterBombEventHandler::Trigger_OnLand(this);
		DestroyActor();


	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode()
	{
	}
};