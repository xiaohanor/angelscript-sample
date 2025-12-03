class USummitBallistaGoBackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitBallista Ballista;
	FVector End;
	float MaxDistanceToEnd;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ballista = Cast<ASummitBallista>(Owner);
		End = Ballista.BasketRoot.WorldLocation + Ballista.BasketRoot.ForwardVector * Ballista.StatueHandsUpMaxMove;
		MaxDistanceToEnd = (Ballista.BasketMeshBaseComp.WorldLocation - End).Size();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Ballista.bIsLaunching)
			return false;
		
		float TimeSinceLastHitByRoll = Time::GetGameTimeSince(Ballista.TimeLastGotHitByRoll);
		if(TimeSinceLastHitByRoll < Ballista.DelayBeforeBasketGoingBackAfterRollHit)
			return false;

		float TimeSinceHitStart = Time::GetGameTimeSince(Ballista.TimeLastHitStart);
		if(TimeSinceHitStart < Ballista.DelayBeforeBasketGoingBackAfterHittingStart + Network::PingOneWaySeconds)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Ballista.bIsLaunching)
			return true;

		float TimeSinceLastHitByRoll = Time::GetGameTimeSince(Ballista.TimeLastGotHitByRoll);
		if(TimeSinceLastHitByRoll < Ballista.DelayBeforeBasketGoingBackAfterRollHit)
			return true;

		float TimeSinceHitStart = Time::GetGameTimeSince(Ballista.TimeLastHitStart);
		if(TimeSinceHitStart < Ballista.DelayBeforeBasketGoingBackAfterHittingStart)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float XAlpha = Ballista.BasketRoot.GetCurrentAlphaBetweenConstraints().X;
		if(Math::IsNearlyZero(XAlpha))
			return;
		
		// PrintToScreen(f"{GetForceAlpha()}");

		float GoingBackDurationAlpha = (ActiveDuration * GetForceAlpha()) / Ballista.TimeBeforeMaxGoingBackForce;
		GoingBackDurationAlpha = Math::Clamp(GoingBackDurationAlpha, 0.0, 1.0);
		float Force = Ballista.BasketGoingBackForce.Lerp(GoingBackDurationAlpha);
		FauxPhysics::ApplyFauxForceToActor(Ballista, -Ballista.BasketRoot.ForwardVector * Force);
	}

	float GetForceAlpha() const
	{
		float DistanceFromEnd = (Ballista.BasketMeshBaseComp.WorldLocation - End).Size();
		return Ballista.BackForceCurve.GetFloatValue(DistanceFromEnd / MaxDistanceToEnd);
	}
};