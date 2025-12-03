UCLASS(Abstract)
class UTundraBeaverSpearEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrow() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}
	
};

class ATundraBeaverSpear : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;
	
	UPROPERTY(DefaultComponent, Attach = "RotationRoot")
	UStaticMeshComponent SpearMesh;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HazeActorSpawnerCapability");

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeActorSpawnerComponent PassengerSpawnerComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UTundraBeaverSpearPassengerSpawnPattern PassengerSpawnPattern;

	UPROPERTY(DefaultComponent, Attach = "SpearMesh")
	UScenepointComponent PassengerAttach0;
	UPROPERTY(DefaultComponent, Attach = "SpearMesh")
	UScenepointComponent PassengerAttach1;
	UPROPERTY(DefaultComponent, Attach = "SpearMesh")
	UScenepointComponent PassengerAttach2;

	UPROPERTY(EditAnywhere)
	ATundraWalkingStick WalkingStickRef;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UNiagaraSystem SpearHitVFX;

	bool bThrowSpear = false;
	
	float SplineDistance = 0;

	UFUNCTION(BlueprintPure)
	float GetCurrentSplineDistance() property
	{
		return SplineDistance;
	}

	UFUNCTION(BlueprintPure)
	float GetNormalizedSplineDistance() property
	{
		return SplineDistance / Spline.SplineLength;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//AttachToComponent(WalkingStickRef.SpearAttachPoint, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void ThrowSpear()
	{
		bThrowSpear = true;
		RemoveActorDisable(this);
		UTundraBeaverSpearEventHandler::Trigger_OnThrow(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bThrowSpear)
		{
			SplineDistance += 10000 * DeltaSeconds;
			FVector Loc = Spline.GetWorldLocationAtSplineDistance(SplineDistance);
			PrintToScreen("" + Loc);
			RotationRoot.SetWorldLocation(Spline.GetWorldLocationAtSplineDistance(SplineDistance));
			RotationRoot.SetWorldRotation(Spline.GetWorldRotationAtSplineDistance(SplineDistance));

			// Activate spawner after location has been set, so gnats spawn in correct locations
			if (!PassengerSpawnerComp.IsSpawnerActive())
				PassengerSpawnerComp.ActivateSpawner(this);

			if(SplineDistance >= Spline.SplineLength)
			{
				OnHitWalkingStick();
			}
		}
	}

	void OnHitWalkingStick()
	{
		bThrowSpear = false;
		Game::GetZoe().PlayCameraShake(CamShake, this, 1.25);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(SpearHitVFX, RotationRoot.GetWorldLocation());
		WalkingStickRef.TriggerHitReaction(this, RotationRoot.ForwardVector);
		UTundraBeaverSpearEventHandler::Trigger_OnHit(this);
	}
};

class UTundraBeaverSpearPassengerSpawnPattern : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;
	default bCanEverSpawn = true;
	default bLevelSpecificPattern = true;

	UPROPERTY()
	int NumberOfPassengers = 3;

	// Class to spawn
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = SpawnPattern)
	TSubclassOf<AHazeActor> SpawnClass;

	bool bHasSpawned = false;

	void GetSpawnClasses(TArray<TSubclassOf<AHazeActor>>& OutSpawnClasses) const override
	{
		if (!SpawnClass.IsValid())
			return;
		OutSpawnClasses.AddUnique(SpawnClass);
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		TArray<UScenepointComponent> AttachPoints;
		Owner.GetComponentsByClass(AttachPoints);

		Super::UpdateControlSide(DeltaTime, SpawnBatch);
		SpawnBatch.Spawn(this, SpawnClass, NumberOfPassengers);
		int i = 0;
		for (FHazeActorSpawnParameters& Params : SpawnBatch.Batch[SpawnClass].SpawnParameters)
		{
			Params.Location = AttachPoints[i].WorldLocation;
			Params.Rotation = AttachPoints[i].WorldRotation;
			Params.Scenepoint = AttachPoints[i];
			i = (i + 1) % NumberOfPassengers;
		} 
		bHasSpawned = true;
	}

	bool IsCompleted() const override
	{
		// Once only
		if (bHasSpawned)
			return true;
		return false;
	}

	void OnSpawn(AHazeActor SpawnedActor) override
	{
		Super::OnSpawn(SpawnedActor);
		UTundraGnatComponent::GetOrCreate(SpawnedActor).PassengerOnBeaverSpear = Owner;
	}

	void OnUnspawn(AHazeActor UnspawnedActor) override
	{
		Super::OnUnspawn(UnspawnedActor);
		UTundraGnatComponent::GetOrCreate(UnspawnedActor).PassengerOnBeaverSpear = nullptr;
	}
}
