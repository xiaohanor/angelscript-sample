class ASkylineHighwaySlingableScrapDispenser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpawnLocation;

	UPROPERTY(EditAnywhere)
	TArray<TSubclassOf<AHazeActor>> ObjectClasses;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	private int SpawnCounter = 0;
	private bool bHasSpawnedScrap = false;

	FHazeAcceleratedFloat AcceleratedFloat;

	FVector SpawnLocationInitialLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedFloat.SnapTo(1.0);
		SpawnLocationInitialLocation = SpawnLocation.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloat.AccelerateTo(1.0, 1.0, DeltaSeconds);
		SpawnLocation.RelativeLocation = Math::Lerp(SpawnLocationInitialLocation - SpawnLocation.UpVector * 500.0, SpawnLocationInitialLocation, AcceleratedFloat.Value);

		if (!bHasSpawnedScrap)
		{
			bHasSpawnedScrap = true;
			SpawnScrap();
		}
	}

	void SpawnScrap()
	{
		if (!HasControl())
			return;

		TSubclassOf<AHazeActor> ObjectClass;

		if (SpawnCounter > 3 && Math::RandRange(0, 20) == 0)
			ObjectClass = ObjectClasses[ObjectClasses.Num() - 1];
		else
			ObjectClass = ObjectClasses[Math::RandRange(0, ObjectClasses.Num() - 2)];

		CrumbSpawnScrap(ObjectClass);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnScrap(TSubclassOf<AHazeActor> ObjectClass)
	{
		auto Actor = SpawnActor(ObjectClass, SpawnLocation.WorldLocation, SpawnLocation.WorldRotation, bDeferredSpawn = true);
		Actor.MakeNetworked(this, SpawnCounter);
		Actor.AttachToComponent(SpawnLocation);

		auto WhipResponseComp = UGravityWhipResponseComponent::Get(Actor);
		if (WhipResponseComp != nullptr)
		{
			WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
			WhipResponseComp.bAllowMultiGrab = false;
		}

		SpawnCounter++;
		FinishSpawningActor(Actor);		
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnScrap() { }

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		auto WhipResponseComp = UGravityWhipResponseComponent::Get(TargetComponent.Owner);
		if (WhipResponseComp != nullptr)
			WhipResponseComp.OnGrabbed.Unbind(this, n"HandleGrabbed");

		SpawnScrap();
		BP_SpawnScrap();

		AcceleratedFloat.SnapTo(0.0);
	}
}