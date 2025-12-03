class UIslandOverseerTowardsChaseBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerDoorComponent DoorComp;
	UIslandOverseerTowardsChaseComponent TowardsChaseComp;
	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerPhaseComponent PhaseComp;

	UHazeSplineComponent Spline;
	UIslandOverseerSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	AAIIslandOverseer Overseer;
	
	bool bCompleted;
	bool bStopping;
	float EndDistance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);
		DoorComp = UIslandOverseerDoorComponent::Get(Owner);
		TowardsChaseComp = UIslandOverseerTowardsChaseComponent::Get(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::GetOrCreate(Owner);

		AIslandOverseerTowardsChaseMoveSplineContainer Container = TListedActors<AIslandOverseerTowardsChaseMoveSplineContainer>()[0];
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		Spline = Cast<ASplineActor>(Actors[0]).Spline;

		EndDistance = Spline.GetClosestSplineDistanceToWorldLocation(TListedActors<AIslandOverseerDoorPoint>().GetSingle().ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bCompleted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(TowardsChaseComp.SplineDistance >= EndDistance)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TowardsChaseComp.SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
		AnimComp.RequestFeature(FeatureTagIslandOverseer::Move, EBasicBehaviourPriority::Medium, this);
		VisorComp.Open();
		bStopping = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
		PhaseComp.SetPhase(EIslandOverseerPhase::Door);
		UIslandOverseerEventHandler::Trigger_OnMoveStopped(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter Target = Game::Mio;
		if(Target.IsPlayerDead())
			Target = Target.OtherPlayer;

		if(!Target.OtherPlayer.IsPlayerDead() && Owner.ActorLocation.Distance(Target.ActorLocation) > Owner.ActorLocation.Distance(Target.OtherPlayer.ActorLocation))
			Target = Target.OtherPlayer;
 
		TowardsChaseComp.Speed = Settings.TowardsChaseBaseSpeed * Math::Clamp(Owner.ActorLocation.Distance(Target.ActorLocation) / Settings.TowardsChaseCatchUpDistance, 1, 2);

		float Delta = DeltaTime * TowardsChaseComp.Speed;
		TowardsChaseComp.SplineDistance += Delta;
		Owner.ActorLocation = Spline.GetWorldLocationAtSplineDistance(TowardsChaseComp.SplineDistance);

		if(!bStopping && TowardsChaseComp.SplineDistance >= EndDistance - 100)
		{
			bStopping = true;
			UIslandOverseerEventHandler::Trigger_OnMoveStopping(Owner);
		}
		
		float NextDistance = TowardsChaseComp.SplineDistance + Delta;
		if(NextDistance >= EndDistance)
			return;
		FVector NextLocation = Spline.GetWorldLocationAtSplineDistance(NextDistance);
		Owner.ActorRotation = (NextLocation - Owner.ActorLocation).Rotation();
	}
}