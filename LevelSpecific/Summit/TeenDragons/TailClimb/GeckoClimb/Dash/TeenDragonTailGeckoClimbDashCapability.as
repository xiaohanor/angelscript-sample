class UTeenDragonTailGeckoClimbDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UTeenDragonTailGeckoClimbSettings ClimbSettings;
	
	UTeenDragonTailClimbableComponent CurrentClimbComp;

	// A list of actors that we have already hit
	TArray<AActor> DashIgnoreImpactResponseActors;

	float JumpStartVerticalSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(DeactiveDuration > ClimbSettings.DashCooldown)
			GeckoClimbComp.bGeckoDashIsCoolingDown = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!TailDragonComp.IsClimbing())
			return false;

		if(!TailDragonComp.bWantToJump)
			return false;

		if(DeactiveDuration < ClimbSettings.DashCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > (ClimbSettings.DashDuration + GeckoClimbComp.WallDashAnticipation))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TailDragonComp.ClimbingInstigators.Add(this);

		Owner.BlockCapabilities(BlockedWhileIn::Jump, this);
		Player.PlayForceFeedback(TailDragonComp.DashRumble, false, false, this);

		TailDragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailClimbDash, this);

		TailDragonComp.ConsumeJumpInput();
		GeckoClimbComp.bIsGeckoDashing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TailDragonComp.ClimbingInstigators.RemoveSingleSwap(this);

		Owner.UnblockCapabilities(BlockedWhileIn::Jump, this);	

		TailDragonComp.AnimationState.Clear(this);
		Player.PlayForceFeedback(TailDragonComp.DashRumble, false, false, this);

		if(!IsOnClimbableWall())
			GeckoClimbComp.bMissedGeckoJumping = true;
		else if(!GeckoClimbComp.bIsLedgeGrabbing)
			GeckoClimbComp.bHasLandedOnWall = true;

		GeckoClimbComp.bIsGeckoDashing = false;
		GeckoClimbComp.bGeckoDashIsCoolingDown = true;
		DashIgnoreImpactResponseActors.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float DashSpeed = 0.0;
				
				if(ActiveDuration >= GeckoClimbComp.WallDashAnticipation)
				{
					float DashAlpha = ActiveDuration - GeckoClimbComp.WallDashAnticipation / ClimbSettings.DashDuration;
					DashSpeed = ClimbSettings.DashMaxSpeed * ClimbSettings.DashSpeedCurve.GetFloatValue(DashAlpha);
				}

				FVector Velocity = Player.ActorForwardVector * DashSpeed;

				Movement.AddVelocity(Velocity);
				Movement.InterpRotationToTargetFacingRotation(ClimbSettings.JumpTurnSpeed * MoveComp.MovementInput.Size());
				Movement.RequestFallingForThisFrame();

				const FVector PreLoc = Player.ActorLocation;

				MoveComp.ApplyMove(Movement);
				TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TailTeenClimb);

				ControlSideQueryDashImpacts(PreLoc, Player.ActorLocation);

			} 
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
				MoveComp.ApplyMove(Movement);
				TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TailTeenClimb);
			}
		}
	}

	void ControlSideQueryDashImpacts(FVector From, FVector To)
	{
		if(From.Equals(To))
			return;

		auto Trace = Trace::InitFromPlayer(Player);
		Trace.IgnoreActors(DashIgnoreImpactResponseActors);

		auto Impacts = Trace.QueryTraceMulti(From, To);
		for(auto It : Impacts)
		{
			if(It.Actor == nullptr)
				continue;

			DashIgnoreImpactResponseActors.Add(It.Actor);
			auto ResponseComp = UTeenDragonTailGeckoClimbDashImpactResponseComponent::Get(It.Actor);
			if(ResponseComp == nullptr)
				continue;
			
			FTeenDragonGeckoClimbDashImpactParams Impact;
			Impact.ImpactLocation = It.ImpactPoint;
			Impact.ImpactedActor = It.Actor;
			ResponseComp.CrumbApplyImpact(Impact);
		}
	}

	bool IsOnClimbableWall()
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithMovementComponent(MoveComp);

		auto HitResults = Trace.QueryTraceMulti(Player.ActorLocation,
		Player.ActorLocation -Player.ActorUpVector * ClimbSettings.WallCheckDistance);

		for(auto HitResult : HitResults)
		{
			if(!HitResult.bBlockingHit)
				continue;

			UTeenDragonTailClimbableComponent ClimbableComp = UTeenDragonTailClimbableComponent::Get(HitResult.Actor);
			if(ClimbableComp == nullptr)
				continue;
			

			FTeenDragonTailClimbParams NewParams;
			NewParams.Location = HitResult.ImpactPoint + HitResult.ImpactNormal;
			NewParams.WallNormal = HitResult.ImpactNormal;
			NewParams.ClimbUpVector = HitResult.Normal;
			NewParams.ClimbComp = ClimbableComp;


			GeckoClimbComp.UpdateClimbParams(NewParams);
			
			return true;
		}
		return false;
	}
};