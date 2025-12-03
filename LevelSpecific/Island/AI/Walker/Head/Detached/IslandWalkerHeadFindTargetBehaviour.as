class UIslandWalkerHeadFindTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	AIslandWalkerHeadStumpTarget Stump;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget Target)
	{
		Stump = Target;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Stump == nullptr)
			return false;

		// Note that we do not switch out current target even if it is dead.
		if (TargetComp.Target != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (Stump.ShieldBreaker == TargetComp.Target)
			Stump.SwapShieldBreaker();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Use specific aggro target if any
		AHazeActor Target = GetBestTarget(); 
		if (Target != nullptr)
		{
			TargetComp.SetTarget(Target);
			DeactivateBehaviour();
			return;
		}
	}

	AHazeActor GetBestTarget()
	{
		if (TargetComp.AggroTarget != nullptr)
			return TargetComp.AggroTarget;

		TArray<AHazePlayerCharacter> KnownTargets = Game::GetPlayers();
		AHazeActor ClosestTarget = nullptr;
		FVector SenseLoc = 	Owner.FocusLocation;	
		float BestDistSqr = BIG_NUMBER;
		for (AHazePlayerCharacter Target : KnownTargets)
		{
			float DistSqr = SenseLoc.DistSquared(Target.FocusLocation);
			if (DistSqr < BestDistSqr)
			{
				BestDistSqr = DistSqr;
				ClosestTarget = Target;
			}
		}
		return ClosestTarget;
	}	
}
