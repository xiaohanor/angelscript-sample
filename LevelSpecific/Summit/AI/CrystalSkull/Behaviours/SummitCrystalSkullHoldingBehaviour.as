class USummitCrystalSkullHoldingBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeActorRespawnableComponent RespawnComp;
	USummitCrystalSkullSettings FlyerSettings;
	FVector InitialLoc;
	float ChangeDestinationTime;
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);

		InitialLoc = Owner.ActorLocation;
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		InitialLoc = RespawnComp.SpawnParameters.Location;
		if (RespawnComp.SpawnParameters.Scenepoint != nullptr)
			InitialLoc = RespawnComp.SpawnParameters.Scenepoint.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ChangeDestinationTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// When tail dragon is nearby and flying towards us we remain still to be easier to hit
		FVector OwnLoc = Owner.ActorLocation;
		FVector TailDragonLoc = Game::Zoe.ActorLocation;
		if (OwnLoc.IsWithinDist(TailDragonLoc, 10000.0))
		{
			FVector DragonForward = Game::Zoe.ActorForwardVector;
			FVector ToDragon = (TailDragonLoc - (OwnLoc + DragonForward * 3000.0));
			if (DragonForward.DotProduct(ToDragon) < 0.0)
				return; // Tail dragon is close and has not passed us yet
		}

		// Drift around near initial position
		if ((Time::GameTimeSeconds > ChangeDestinationTime) || 
			Owner.ActorLocation.IsWithinDist(Destination, FlyerSettings.HoldingSpeed * 0.5))
		{
			Destination = InitialLoc + Math::GetRandomPointOnSphere() * FlyerSettings.HoldingRadius;
			ChangeDestinationTime = Time::GameTimeSeconds + 3.0;
		}
		DestinationComp.MoveTowards(Destination, FlyerSettings.HoldingSpeed);	
	}
}
