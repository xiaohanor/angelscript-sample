class UCoastJetskiTargetingBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	float SwitchTargetTime = 0.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GameTimeSeconds > SwitchTargetTime)
			return true;
		if (TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazeActor Target = FindBestTarget();
		if (TargetComp.IsValidTarget(Target))
			TargetComp.SetTarget(Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		SwitchTargetTime = Time::GameTimeSeconds + Math::RandRange(2.0, 3.0);
	}

	AHazeActor FindBestTarget()
	{
		// Go valid target if there's only one
		for (AHazePlayerCharacter Target : Game::Players)
		{
			if (!TargetComp.IsValidTarget(Target))
				return Target.OtherPlayer;
		}	

		// Go for target with least number of attackers
		int MioNumOpponents = UGentlemanComponent::GetOrCreate(Game::Mio).GetNumOtherOpponents(Owner);
		int ZoeNumOpponents = UGentlemanComponent::GetOrCreate(Game::Zoe).GetNumOtherOpponents(Owner);
		if (MioNumOpponents < ZoeNumOpponents)
			return Game::Mio;
		if (MioNumOpponents > ZoeNumOpponents)
			return Game::Zoe;

		// Same number of attackers, go for target that has us in view if there's only one
		for (AHazePlayerCharacter Target : Game::Players)
		{
			if (!SceneView::IsInView(Target, Owner.ActorLocation))
				return Target.OtherPlayer;
		}	

		// Otherwise, go for closest target
		if (Game::Mio.ActorLocation.DistSquared2D(Owner.ActorLocation) < Game::Zoe.ActorLocation.DistSquared2D(Owner.ActorLocation))
			return Game::Mio;
		return Game::Zoe;
	}
}
