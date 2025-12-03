class ASkylineWhipObjectDispenser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpawnLocation;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent TargetableOutlineComp;

	UPROPERTY(EditAnywhere)
	int NumOfObjects = 5;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AHazeActor> ObjectClass;

	TArray<AActor> SpawnedActors;
	UPROPERTY(EditAnywhere)
	TArray<ASkylineWhipObjectDispenser> OtherDispensers; 

	bool bDisableTargetOnActors;
	
	private int SpawnActorIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0; i < NumOfObjects; i++)
			SpawnObject();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(OtherDispensers.Num() == 0)
			return;

		float DistanceToPlayer = (Game::Zoe.ActorLocation - ActorLocation).Size();

		for(ASkylineWhipObjectDispenser OtherDispenser : OtherDispensers)
		{
			if(DistanceToPlayer > (Game::Zoe.ActorLocation - OtherDispenser.ActorLocation).Size())
			{
				for(AActor SpawnedActor : SpawnedActors)
				{
					auto TargetComponent = UGravityWhipTargetComponent::Get(SpawnedActor);

					TargetComponent.Disable(this);
				}
				bDisableTargetOnActors = true;
			}
			else if(bDisableTargetOnActors)
			{
				for(AActor SpawnedActor : SpawnedActors)
				{
					auto TargetComponent = UGravityWhipTargetComponent::Get(SpawnedActor);

					TargetComponent.Enable(this);
				}
				bDisableTargetOnActors = false;
			}
		}

	}

	UFUNCTION()
	private void OnObjectGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		auto WhipResponse = UGravityWhipResponseComponent::Get(UserComponent.Owner);
		if (WhipResponse != nullptr)
		{
			WhipResponse.OnGrabbed.Unbind(this, n"OnObjectGrabbed");
		}

		SpawnedActors.Remove(TargetComponent.Owner);

		SpawnObject();
	}
	
	void SpawnObject()
	{
		auto Actor = SpawnActor(ObjectClass, SpawnLocation.WorldLocation, SpawnLocation.WorldRotation, bDeferredSpawn = true);
		Actor.MakeNetworked(this, SpawnActorIndex);
		SpawnActorIndex++;
		FinishSpawningActor(Actor);
		SpawnedActors.Add(Actor);

		auto GravityWhipResponseComponent = UGravityWhipResponseComponent::Get(Actor);
		if (GravityWhipResponseComponent != nullptr)
		{
			GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnObjectGrabbed");
		}

//		PrintToScreen("ObjectSpawned: " + Actor, 2.0, FLinearColor::Green);
	}
}