class USolarFlareFireBallCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SolarFlareFireBallCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ASolarFlareFireBall FireBall;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FireBall = Cast<ASolarFlareFireBall>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!FireBall.IsWithinRange())
			return false;

		return true;
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
		FVector Direction = (FireBall.Shuttle.ActorLocation - FireBall.ActorLocation).GetSafeNormal();
		FireBall.ActorLocation += Direction * FireBall.MoveSpeed * DeltaTime;

		FHazeTraceDebugSettings DebugSettings;
		DebugSettings.TraceColor = FLinearColor::Red;
		DebugSettings.Thickness = 15.0;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		TraceSettings.IgnoreActor(FireBall);
		TraceSettings.UseSphereShape(500.0);
		TraceSettings.DebugDraw(DebugSettings);

		FHitResult Hit =  TraceSettings.QueryTraceSingle(FireBall.ActorLocation, FireBall.ActorLocation + FireBall.ActorForwardVector);

		if (Hit.bBlockingHit)
		{
			FireBall.DestroyActor();
		}
	}
}