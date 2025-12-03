class USummitTeenDragonRollingLiftRollingDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 95; // after jump, before move

	UPlayerTeenDragonComponent DragonComp;
	USummitTeenDragonRollingLiftComponent LiftComp;
	UPlayerMovementComponent MoveComp;
	UAdultDragonTailSmashModeSettings SmashSettings;
	USummitRollingLiftSettings RollingLiftSettings;
	UTeenDragonMovementSettings MovementSettings;

	ASummitRollingLift CurrentRollingLift;
	float BonusSpeed = 0;
	float LockedInDash = 0;
	float LastDeactivatedTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SmashSettings = UAdultDragonTailSmashModeSettings::GetSettings(Player);
		RollingLiftSettings = USummitRollingLiftSettings::GetSettings(Player);

		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if(Time::GetGameTimeSince(LastDeactivatedTime) < RollingLiftSettings.DashCooldown)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsOnAnyGround() && !RollingLiftSettings.bDashWhileGrounded)
			return false;

		if(!MoveComp.IsOnAnyGround() && !RollingLiftSettings.bDashWhileAirBourne)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Player.ActorVelocity.SizeSquared() < Math::Square(BonusSpeed * 0.5))
			return true;

		else if(LockedInDash <= 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		CurrentRollingLift = LiftComp.CurrentRollingLift;	
		LockedInDash = 1;

		BonusSpeed = MovementSettings.DashSpeed * MoveComp.MovementSpeedMultiplier * 2.0;

		FVector MovementInput = MoveComp.MovementInput;
		if(MovementInput.IsNearlyZero())
			MovementInput = CurrentRollingLift.LastSplineForward;
		else
			MovementInput.Normalize();
			
		FVector HorizontalVelocity = Player.ActorVelocity.VectorPlaneProject(Player.MovementWorldUp);
		FVector VerticalVelocity = Player.ActorVelocity.ProjectOnToNormal(Player.MovementWorldUp);
		VerticalVelocity = VerticalVelocity.GetClampedToMaxSize(500);
		Player.SetActorVelocity(HorizontalVelocity + VerticalVelocity + (MovementInput * BonusSpeed));

		DragonComp.bIsDashing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bIsDashing = false;
		MoveComp.RemoveMovementIgnoresActor(this);
		LastDeactivatedTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LockedInDash -= DeltaTime;

		FVector Forward = Player.GetActorVelocity() * DeltaTime;
		Forward += MoveComp.GetPendingImpulse();
		if(Forward.IsNearlyZero())
			Forward = Player.ActorForwardVector;
		
		// Trace ahead to see if we are going to impact anything
		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
		auto HitResults = TraceSettings.QueryOverlaps(Player.ActorLocation + Forward);

		FRollParams ImpactParams;
		ImpactParams.RollDirection = Forward.GetSafeNormal();
		ImpactParams.PlayerInstigator = Player;
		ImpactParams.HitLocation = Player.ActorLocation;

		bool bStopMovement = false;

		for(auto Hit : HitResults)
		{
			auto ResponseComp = UTeenDragonTailAttackResponseComponent::Get(Hit.Actor);
			if(ResponseComp == nullptr)
				continue;

			if(!ResponseComp.bShouldStopPlayer)
			{
				MoveComp.AddMovementIgnoresActor(this, ResponseComp.Owner);
			}
			else
			{
				bStopMovement = true;
			}
		}

		if(bStopMovement)
		{
			// Bounce in the opposite direction
			FVector Velocity = Player.ActorVelocity;
			Velocity = -(Velocity.VectorPlaneProject(FVector::UpVector));
			Velocity = Velocity.GetSafeNormal() * 800;
			
			// Also a bit of up force
			Velocity += FVector::UpVector * 900;

			Player.SetActorVelocity(Velocity);
		}
	}

	FVector GetForwardVector() const
	{
		FVector Forward = Player.ActorVelocity.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		if (Forward.IsNearlyZero())
			Forward = Player.ActorForwardVector;
		return Forward;
	}
};