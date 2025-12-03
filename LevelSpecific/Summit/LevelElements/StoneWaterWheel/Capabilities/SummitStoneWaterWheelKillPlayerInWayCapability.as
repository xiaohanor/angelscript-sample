class USummitStoneWaterWheelKillPlayerInWayCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	ASummitStoneWaterWheel Wheel;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Wheel = Cast<ASummitStoneWaterWheel>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Wheel.bIsActive)
			return false;

		if(Wheel.bHasRemovedCollisionWithPlayers)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Wheel.bIsActive)
			return true;

		if(Wheel.bHasRemovedCollisionWithPlayers)
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
		if(MoveComp.Velocity.IsNearlyZero(10))
			return;

		const float CapusleRadius = (Wheel.CapsuleComp.CapsuleRadius * Wheel.CapsuleComp.ShapeScale) - 150; 
		const float WheelWidth = 300.0;
		const float InsideWheelDist = 1330.0;
		const FVector VelocityDir = MoveComp.Velocity.GetSafeNormal();
	
		for(auto Player : Game::Players)
		{
			float Multiplier = Math::Saturate(MoveComp.Velocity.Size() / 500.0);
			if (Multiplier < 0.15)
				Multiplier = 0.0;

			float FFFrequency = 15.0;
			float FFIntensity = 0.3 * Multiplier;
			PrintToScreen(f"{Multiplier=}");
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
			FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
			Player.SetFrameForceFeedback(FF);

			const FVector DeltaToPlayer = Player.ActorLocation - Wheel.ActorLocation;

			const float PlayerDistanceToSide = Wheel.ActorRightVector.DotProduct(DeltaToPlayer);
			const float DistToPlayerSqrd = DeltaToPlayer.SizeSquared2D(Wheel.ActorRightVector);
			const float VelocityDotPlayer = VelocityDir.DotProduct(DeltaToPlayer);

			TEMPORAL_LOG(Wheel, "Player Kill Trace")
				.Page(f"{Player}")
				.DirectionalArrow("Dist to Side", Wheel.ActorLocation + FVector::UpVector * 300, Wheel.ActorRightVector * PlayerDistanceToSide, 20, 400, FLinearColor::Green)
				.DirectionalArrow("Delta to Player", Wheel.ActorLocation, DeltaToPlayer.ConstrainToPlane(Wheel.ActorRightVector), 20, 400, FLinearColor::Purple)
				.Value("Velocity Dot Player", VelocityDotPlayer)
			;

			// On the side of wheel
			if(Math::Abs(PlayerDistanceToSide) > WheelWidth)
				continue;

			// Inside the wheel
			if(DistToPlayerSqrd < Math::Square(InsideWheelDist))
				continue;
			
			// Going away from player
			if(VelocityDotPlayer < 0)
				continue;

			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Player.CapsuleComponent);
			FHazeTraceShape TraceShape = FHazeTraceShape::MakeCapsule(CapusleRadius, CapusleRadius + WheelWidth, FQuat::MakeFromZX(Wheel.ActorRightVector, Wheel.ActorForwardVector));
			Trace.UseShape(TraceShape);
			FVector Start = Wheel.ActorLocation;
			FVector End = Start + MoveComp.Velocity * DeltaTime;

			auto Hit = Trace.QueryTraceComponent(Start, End);
			TEMPORAL_LOG(Wheel, "Player Kill Trace")
				.Page(f"{Player}")
				.HitResults("Player Trace Hits", Hit, TraceShape)
			;

			if(Hit.bBlockingHit
			|| Hit.bStartPenetrating)
			{
				Player.KillPlayer(FPlayerDeathDamageParams(FVector(0.0), 5.0), Wheel.DeathEffect);
			}

		}
	}
};