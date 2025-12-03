class UIslandWalkerSuspendedFindTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Perception);
	
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	UIslandWalkerSettings Settings;
	UIslandWalkerNeckRoot NeckRoot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		NeckRoot = UIslandWalkerNeckRoot::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner); 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
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
		// Choose the target nearest to neck forward direction
		AHazePlayerCharacter BestTarget = nullptr;
		float BestDot = -1.1; 
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!TargetComp.IsValidTarget(Player))
				continue;
			float Dot = NeckRoot.ForwardVector.DotProduct((Player.ActorLocation - Owner.ActorLocation).GetSafeNormal2D());
			if (Dot < BestDot) 
				continue;
			BestDot = Dot;
			BestTarget = Player;
		}

		if (BestTarget != nullptr)
			TargetComp.SetTarget(BestTarget);
	}
}