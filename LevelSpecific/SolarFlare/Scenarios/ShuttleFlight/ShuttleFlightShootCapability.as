class UShuttleFlightShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ShuttleFlightShootCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASolarFlareShuttle Shuttle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{	
		Shuttle = TListedActors<ASolarFlareShuttle>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
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
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnoreActor(Shuttle);
		TraceSettings.UseLine();

		FVector Start = Shuttle.ShootOrigin.WorldLocation;
		FVector End = Shuttle.ShootOrigin.WorldLocation + Shuttle.ShootOrigin.WorldRotation.Vector() * 15000.0;
		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);

		if (Hit.bBlockingHit)
		{
			UShuttleShootResponseComponent Response = UShuttleShootResponseComponent::Get(Hit.Actor);
		}
	}
}