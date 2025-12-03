class UIslandWalkerTargetingBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandWalkerSettings Settings;
	AHazePlayerCharacter PreviousTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
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
		return true; // Single tick activation
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		FVector OwnLoc = Owner.ActorLocation;
		FVector Forward = Owner.ActorForwardVector;

		// Do we have a single or no valid targets?
		if (!TargetComp.IsValidTarget(Game::Mio))
		{
			if (TargetComp.IsValidTarget(Game::Zoe))
				TargetComp.SetTarget(Game::Zoe);
			return;
		}
		if (!TargetComp.IsValidTarget(Game::Zoe))
		{
			if (TargetComp.IsValidTarget(Game::Mio))
				TargetComp.SetTarget(Game::Mio);
			return;
		}

		// Should we switch target?
		if (PreviousTarget != nullptr)
		{
			TargetComp.SetTarget(PreviousTarget.OtherPlayer);
			return;
		}

		// Choose whoever is most in front of us
		float MioDot = Forward.DotProduct((Game::Mio.ActorLocation - OwnLoc).GetSafeNormal());
		float ZoeDot = Forward.DotProduct((Game::Zoe.ActorLocation - OwnLoc).GetSafeNormal());
		TargetComp.SetTarget((MioDot > ZoeDot) ? Game::Mio : Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (TargetComp.HasValidTarget())
		{
			PreviousTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
			Cooldown.Set(Settings.SwitchTargetMinInterval);
		}
		else
		{
			// Try again in a while
			Cooldown.Set(0.5);
		}
	}
}
