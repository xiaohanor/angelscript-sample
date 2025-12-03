class USummitBallistaLaunchBasketCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitBallista Ballista;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ballista = Cast<ASummitBallista>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Ballista.bIsLaunching)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		const float XAlpha = Ballista.BasketRoot.GetCurrentAlphaBetweenConstraints().X;
		if(Math::IsNearlyZero(XAlpha, 0.1))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if ((Player.ActorLocation - Ballista.ActorLocation).Size() < 6000.0)
				Player.PlayForceFeedback(Ballista.LaunchRumble, false, true, this);
			
			Player.PlayWorldCameraShake(Ballista.LaunchCameraShake, this, Ballista.ActorLocation, 3000.0, 6000.0);
		}

		USummitBallistaEventHandler::Trigger_OnCartStartedLaunching(Ballista);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaunchPlayerInVolume();
		Ballista.bIsLaunching = false;

		USummitBallistaEventHandler::Trigger_OnCartStoppedLaunching(Ballista);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ConstraintAlpha = Ballista.BasketRoot.GetCurrentAlphaBetweenConstraints().X;
		float LaunchSpeed = Ballista.LaunchSpeed.Lerp(1 - ConstraintAlpha);
		FauxPhysics::ApplyFauxMovementToActor(Ballista, -Ballista.BasketRoot.ForwardVector * LaunchSpeed * DeltaTime);
		KillPlayerInFrontOfBasket();
	}

	void LaunchPlayerInVolume()
	{
		if(!Ballista.ZoeInVolume.IsSet())
			return;

		auto Player = Ballista.ZoeInVolume.Value;

		FVector Impulse = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(
				Player.ActorLocation, Ballista.GetTargetLocation() + FVector::DownVector * Player.CapsuleComponent.CapsuleRadius
				, Ballista.LaunchGravity, Ballista.DragonLaunchSpeed);

		auto CatapultComp = UTeenDragonBallistaComponent::GetOrCreate(Player);
		CatapultComp.LaunchImpulse.Set(Impulse);
		CatapultComp.LaunchingBallista = Ballista;

		TEMPORAL_LOG(Ballista)
			.DirectionalArrow("Launch Impulse", Player.ActorLocation, Impulse, 10, 40, FLinearColor::Purple)
		;
	}

	void KillPlayerInFrontOfBasket()
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithObjectType(EObjectTypeQuery::PlayerCharacter);
		FHazeTraceShape TraceShape = FHazeTraceShape::MakeBox(32, 300, 100, Ballista.BasketRoot.ComponentQuat);
		Trace.UseShape(TraceShape);
		
		FVector Forward = Ballista.BasketRoot.ForwardVector;
		FVector Start = Ballista.BasketRoot.WorldLocation - Forward * 1010; 
		FVector End = Start - Forward * 500.0;
		auto Hits = Trace.QueryTraceMulti(Start, End);
		TEMPORAL_LOG(Ballista).HitResults("Launch Kill Players Trace", Hits, Start, End, TraceShape);
		for(auto Hit : Hits)
		{
			auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if(Player == nullptr)
				continue;

			Player.KillPlayer();
		}	
	}
};