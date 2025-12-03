class ATrainPlayerCrashIntoWaterLaunchToPointManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"TrainPlayerCrashIntoWaterLaunchCapability");

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActor PointToLaunchTo;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	APlayerTrigger ActivationTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Collision")
	bool bBlockCollision = true;

	UPROPERTY(EditInstanceOnly, Category = "Collision", Meta = (EditCondition = bBlockCollision, EditconditionHides))
	float CollisionBlockDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivationTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterActivationTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnterActivationTrigger(AHazePlayerCharacter Player)
	{
		auto LaunchComp = UTrainPlayerCrashIntoWaterLaunchComponent::GetOrCreate(Player);		
		LaunchComp.ActorToLaunchTo = PointToLaunchTo;
		LaunchComp.bBlockCollisionWhenLaunched = bBlockCollision;
		LaunchComp.CollisionBlockDuration = CollisionBlockDuration;
	}
};