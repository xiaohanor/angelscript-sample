class USummitStoneBeastScenepointShuffleScenepointBehaviour : UBasicBehaviour
{	
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	bool bSearchForShuffleScenePoints = true;
	ASummitStoneBeastZapperShuffleScenepointActor ShufflePoint;
	USummitStoneBeastZapperSettings Settings;
	FVector Destination;
	float NewDestinationTime = 0.0;
	float AllowSwitchingTargetTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitStoneBeastZapperSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnPostRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bSearchForShuffleScenePoints = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!bSearchForShuffleScenePoints)
			return;
		if (!Requirements.CanClaim(BehaviourComp, this))
			return; // Still doing entrance behaviours etc

		// Only search for ShufflePoints once, after any higher prio behaviour has run it's course
		// We ignore ShufflePoints if we enter them later
		bSearchForShuffleScenePoints = false;	
		TListedActors<ASummitStoneBeastZapperShuffleScenepointActor> ShufflePoints;
		for (ASummitStoneBeastZapperShuffleScenepointActor Point : ShufflePoints)
		{
			if (Point.IsAt(Owner))
			{
				ShufflePoint = Point;
				Destination = Owner.ActorLocation;
				return;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (ShufflePoint == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		NewDestinationTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ShufflePoint.Hold(Owner);

		if (ActiveDuration > NewDestinationTime)
		{
			NewDestinationTime = ActiveDuration + Math::RandRange(1.0, 1.5) * 3.0; // TODO: make setting
			
			// Tries to find a not too nearby destination point
			for (int Tries = 10; Tries >= 0; Tries--)
			{
				Destination = ShufflePoint.GetScenepoint().WorldLocation + Math::GetRandomPointOnCircle_XY() * ShufflePoint.GetScenepoint().Radius * 1.0;
				
				// Break loop if we found a suitable destination
				if (!Owner.ActorLocation.IsWithinDist(Destination, 200)) // TODO: setting
					break;
			}
		}

		Destination.Z = Owner.ActorLocation.Z;
		if (!Owner.ActorLocation.IsWithinDist(Destination, 100.0))
			DestinationComp.MoveTowards(Destination, 200); // TODO: make setting: Settings.SidestepStrafeSpeed

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)			
			Debug::DrawDebugCircle(Destination, 50, 12, FLinearColor::Blue, 10);
#endif
	}
}


