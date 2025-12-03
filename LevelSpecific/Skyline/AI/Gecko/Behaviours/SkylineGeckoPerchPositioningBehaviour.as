class USkylineGeckoPerchPositioningBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly; // Movement only
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UWallclimbingComponent WallclimbingComp;
	USkylineGeckoComponent GeckoComp;
	USkylineGeckoSettings Settings;

	float UpdatePerchTime = 0.0;
	TArray<FScenepointPerchPosition> PerchCandidates;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WallclimbingComp = UWallclimbingComponent::Get(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner); 
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);

		UGentlemanComponent::GetOrCreate(Game::Zoe).SetMaxAllowedClaimants(GeckoToken::Perching, Settings.PerchingMaxGeckos);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Release any perch when we go chasing Mio 
		if (GeckoComp.PerchPos.IsValid() && TargetComp.HasValidTarget() && (TargetComp.Target == Game::Mio))
			GeckoComp.PerchPos.Release();

		if (IsActive() || IsBlocked() || !HasControl())
			return;
		float CurTime = Time::GameTimeSeconds;
		if ((CurTime < UpdatePerchTime) || (TargetComp.Target != Game::Zoe))
			return;
		if (!ShouldReposition())
			return;

		// Might as well spread out these checks if we have multiple Geckos
		// TODO: ...or even better have a component on Zoe keep track of suitable perches.
		UpdatePerchTime = CurTime + Math::RandRange(0.5, 0.8); 

		// If we already have perch candidates, we only validate them
		for (int i = PerchCandidates.Num() - 1; i >= 0; i--)
		{
			if (!PerchCandidates[i].IsValid() || !PerchCandidates[i].Perch.IsValidTarget(TargetComp.Target, PerchCandidates[i].DistAlongPerch))
				PerchCandidates.RemoveAtSwap(i);
		}
		if (PerchCandidates.Num() > 0)
			return;

		// Find new perch candidates
		TListedActors<APerchScenepointActor> PerchPoints;
		for (APerchScenepointActor PerchPoint : PerchPoints)
		{
			// Early out cheap check (we may get false negatives so we might need to add some slop or be more accurate) 
			if (!PerchPoint.PerchComp.IsValidTarget(TargetComp.Target, PerchPoint.PerchSpline.SplineLength * 0.5))
				continue;

			// Expensive check to see where we would want to perch
			FScenepointPerchPosition Pos = PerchPoint.PerchComp.GetClosestAvailablePerch(Owner.ActorLocation, Settings.PerchPositioningSpacing);
			if (Pos.IsValid() && PerchPoint.PerchComp.IsValidTarget(TargetComp.Target, Pos.DistAlongPerch))
				PerchCandidates.Add(Pos);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FScenepointPerchPosition& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!ShouldReposition())
			return false;
		if (PerchCandidates.Num() == 0)
			return false;
		if (!TargetComp.GentlemanComponent.CanClaimToken(GeckoToken::Perching, Owner))
			return false;

		// Use random perch for now
		int iPerch = Math::RandRange(0, PerchCandidates.Num() - 1);
		OutParams = PerchCandidates[iPerch];
		return true;
	}

	bool ShouldReposition() const
	{
		// Never reposition when we have a bad target
		if (!TargetComp.HasValidTarget())
			return false;
		// Zoe only!
		if (TargetComp.Target != Game::Zoe)
			return false;

		// Only reposition if we want to perch
		if (!GeckoComp.ShouldPerch(TargetComp.GentlemanComponent))
			return false;		

		// Reposition if current position is bad vs target
		if (!GeckoComp.PerchPos.IsValid())
			return true;
		if (!GeckoComp.PerchPos.Perch.IsValidTarget(TargetComp.Target, GeckoComp.PerchPos.DistAlongPerch))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FScenepointPerchPosition Params)
	{
		Super::OnActivated();
		GeckoComp.PerchPos = Params;

		// There might be others who have snatched our favorite position, so try again to be safe
		GeckoComp.PerchPos = GeckoComp.PerchPos.Perch.GetClosestAvailablePerch(GeckoComp.PerchPos.DistAlongPerch, Settings.PerchPositioningSpacing);
		if (!GeckoComp.PerchPos.IsValid())
			Cooldown.Set(1.0);

		GeckoComp.PerchPos.Perch.ClaimPerch(GeckoComp.PerchPos.DistAlongPerch);
		GeckoComp.PerchPos.ClaimedTime = Time::GameTimeSeconds;
		WallclimbingComp.DestinationUpVector.Apply(GeckoComp.PerchPos.UpVector, this, EInstigatePriority::High);

		TargetComp.GentlemanComponent.ClaimToken(GeckoToken::Perching, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		WallclimbingComp.DestinationUpVector.Clear(this);
		GeckoComp.bAllowBladeHits.Clear(this);
		if (TargetComp.GentlemanComponent != nullptr) // If null, token will have already been released
			TargetComp.GentlemanComponent.ReleaseToken(GeckoToken::Perching, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowards(GeckoComp.PerchPos.Location, Settings.PerchPositioningMoveSpeed);

		// Are we there yet?
		if (GeckoComp.IsAtPerch(Settings.PerchPositioningDoneRange))
			Cooldown.Set(Settings.PerchPositioningCooldown);

		// Can we be damaged by blade?
		if (Settings.bAllowBladeHitsWhenPerching && Owner.ActorLocation.IsWithinDist(GeckoComp.PerchPos.Location, 120.0))
			GeckoComp.bAllowBladeHits.Apply(true, this);
		else 
			GeckoComp.bAllowBladeHits.Apply(false, this);
	}
}
