class ASkylineWhipObjectMultiDispenser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpawnLocation;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;
	default GravityWhipResponseComponent.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(EditAnywhere)
	int NumOfObjects = 5;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AHazeActor> ObjectClass;

	private int SpawnCounter = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		UserComponent.Release(TargetComponent);

		TArray<UGravityWhipTargetComponent> GravityWhipTargetComponents;
		for (int i = 0; i < NumOfObjects; i++)
		{
			auto Actor = SpawnActor(ObjectClass, SpawnLocation.WorldLocation, SpawnLocation.WorldRotation, bDeferredSpawn = true);
			Actor.MakeNetworked(this, SpawnCounter);
			SpawnCounter++;
			FinishSpawningActor(Actor);

			auto GravityWhipTargetComponent = UGravityWhipTargetComponent::Get(Actor);
			if (GravityWhipTargetComponent != nullptr)
				GravityWhipTargetComponents.Add(GravityWhipTargetComponent);
		}
		
		UserComponent.Grab(GravityWhipTargetComponents);
	}
}