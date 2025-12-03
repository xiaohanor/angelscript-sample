class USkylineGeckoMoveToLocationBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USkylineGeckoMoveToLocationComponent MoveToLocationComp;
	float MoveSpeed = 2000.0;
	float TestMoveTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveToLocationComp = USkylineGeckoMoveToLocationComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!MoveToLocationComp.bMoveToLocation)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!MoveToLocationComp.bMoveToLocation)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowards(MoveToLocationComp.Location, MoveSpeed);

#if EDITOR
		if ((Time::GetGameTimeSince(TestMoveTime) > 2.0) && Game::Mio.IsAnyCapabilityActive(PlayerMovementTags::GroundJump))
			ForceMoveToViewTraceLocation(); // Jump will switch destination for simple testing
#endif
	}

	UFUNCTION(DevFunction)
	void GeckoForceWalk()
	{
		MoveSpeed = 250.0;
		ForceMoveToViewTraceLocation();
	}

	UFUNCTION(DevFunction)
	void GeckoForceTrot()
	{
		MoveSpeed = 500.0;
		ForceMoveToViewTraceLocation();
	}

	UFUNCTION(DevFunction)
	void GeckoForceRun()
	{
		MoveSpeed = 1000.0;
		ForceMoveToViewTraceLocation();
	}

	UFUNCTION(DevFunction)
	void GeckoAbortForceMovement()
	{
		MoveToLocationComp.bMoveToLocation = false;
	}

	void ForceMoveToViewTraceLocation()
	{
#if EDITOR	
		TestMoveTime = Time::GameTimeSeconds;	
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseLine();
		FHitResult Obstruction = Trace.QueryTraceSingle(Game::Mio.ViewLocation, Game::Mio.ViewLocation + Game::Mio.ViewRotation.ForwardVector * 20000.0);
		if (!Obstruction.bBlockingHit)
		{
			Debug::DrawDebugSphere(Game::Mio.ViewLocation + Game::Mio.ViewRotation.ForwardVector * 100, 20.0, 4, FLinearColor::Red, 5.0, 1.0);	
			return;
		}
		MoveToLocationComp.bMoveToLocation = true;
		MoveToLocationComp.Location = Obstruction.ImpactPoint;
		Debug::DrawDebugLine(MoveToLocationComp.Location, MoveToLocationComp.Location + Obstruction.ImpactNormal * 200.0, FLinearColor::Green, 10.0, 10.0);	
#endif		
	}

}
