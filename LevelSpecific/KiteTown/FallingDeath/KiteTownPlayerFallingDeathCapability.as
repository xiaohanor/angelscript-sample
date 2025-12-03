class UKiteTownPlayerFallingDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"FallingDeath");

	default TickGroup = EHazeTickGroup::Gameplay;

	UKiteFlightPlayerComponent KiteFlightComp;
	UHazeMovementComponent MoveComp;

	float AirborneDuration = 0.0;
	float DeathThreshold = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.IsOnAnyGround())
			return false;

		UKiteFlightPlayerComponent FlightComp = UKiteFlightPlayerComponent::Get(Player);
		if (FlightComp == nullptr)
			return false;

		if (FlightComp.bFlightActive)
			return false;

		if (GetNearbyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;

		if (Player.IsAnyCapabilityActive(n"GrappleEnter"))
			return true;

		if (MoveComp.IsOnAnyGround())
			return true;

		if (KiteFlightComp.bFlightActive)
			return true;

		if (GetNearbyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		KiteFlightComp = UKiteFlightPlayerComponent::Get(Player);
		AirborneDuration = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AirborneDuration += DeltaTime;
		if (AirborneDuration >= DeathThreshold)
			Player.KillPlayer();
	}

	bool GetNearbyGround() const
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.UseCapsuleShape(Player.ScaledCapsuleRadius * 10.0, Player.ScaledCapsuleHalfHeight);

		FHitResult Hit = Trace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - (FVector::UpVector * 5000.0));
		return Hit.bBlockingHit;
	}
}