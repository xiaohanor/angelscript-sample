event void FSanctuaryBowMegaCompanionLightSignature();

class ASanctuaryBowLightMegaCompanion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase BirdMesh;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditInstanceOnly)
	AActor EnterSplineActor;
	UHazeSplineComponent EnterSplineComp;

	UPROPERTY(EditInstanceOnly)
	AActor StatueRootActor;

	UPROPERTY()
	FSanctuaryBowMegaCompanionLightSignature OnSpawnArrow();

	UPROPERTY()
	FSanctuaryBowMegaCompanionLightSignature OnDeSpawnArrow();

	UPROPERTY()
	FSanctuaryBowMegaCompanionLightSignature OnEnteredSocket();

	UPROPERTY()
	FSanctuaryBowMegaCompanionLightSignature OnMegaExplosion();

	UPROPERTY(EditInstanceOnly)
	AHazeSphere HazeSphereActor;

	bool bEnteredSocket = false;

	bool bSyncedLightBirdIsIlluminating = false;
	TArray<AActor> AttachedActors;

	UPROPERTY()
	FRuntimeFloatCurve SpeedCurve;

	UPROPERTY()
	float EnterDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnterSplineComp = UHazeSplineComponent::Get(EnterSplineActor);

		FVector Location = EnterSplineComp.GetWorldLocationAtSplineFraction(0.0);
		FRotator Rotation = EnterSplineComp.GetWorldRotationAtSplineFraction(0.0).Rotator();
		SetActorLocationAndRotation(Location, Rotation);

		SetActorHiddenInGame(true);

		SetActorControlSide(Game::Mio);

		StatueRootActor.GetAttachedActors(AttachedActors, false, true);

		for (auto AttachedActor : AttachedActors)
		{
			AttachedActor.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION()
	void Activate()
	{	
		SetActorHiddenInGame(false);
		BirdMesh.SetBlendSpaceValues(0.0, 0.0, true);
	}

	UFUNCTION()
	void HideHazeSphere()
	{
		HazeSphereActor.HazeSphereComponent.SetOpacityOverTime(3.0, 0.0);
	}

	UFUNCTION()
	void UnhideStatue()
	{
		for (auto AttachedActor : AttachedActors)
		{
			AttachedActor.SetActorHiddenInGame(false);
		}
	}

	UFUNCTION()
	void Fly()
	{
		QueueComp.Duration(EnterDuration, this, n"EnterUpdate");
		QueueComp.Event(this, n"EnteredSocket");
	}

	UFUNCTION()
	private void EnterUpdate(float Alpha)
	{
		float CurrentValue = SpeedCurve.GetFloatValue(Alpha);
		FVector Location = EnterSplineComp.GetWorldLocationAtSplineFraction(CurrentValue);
		FRotator Rotation = EnterSplineComp.GetWorldRotationAtSplineFraction(CurrentValue).Rotator();
		SetActorLocationAndRotation(Location, Rotation);

		BirdMesh.SetBlendSpaceValues(1.0, Alpha, true);
	}

	UFUNCTION()
	private void EnteredSocket()
	{
		OnEnteredSocket.Broadcast();
		bEnteredSocket = true;
		SetActorHiddenInGame(true);
	}

	void StartChargeArrow()
	{
		if (!bEnteredSocket)
			return;
		
		OnSpawnArrow.Broadcast();
	}

	void StopChargeArrow()
	{
		if (!bEnteredSocket)
			return;

		OnDeSpawnArrow.Broadcast();
	}
};