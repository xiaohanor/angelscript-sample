// This is an exact copy of the normal trace for airborne mantle capability but it traces using my ledge mantle component and the code in that.
class UIslandStormdrainToxicShiftTraceForAirborneMantleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleEvaluate);
	
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::Skydive);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 0;

	UPlayerMovementComponent MoveComp;
	UPlayerLedgeMantleComponent MantleComp;
	// OLIVERL BEGIN EDIT
	UIslandStormdrainToxicShiftLedgeMantleComponent ToxicShiftLedgeMantleComp;
	// OLIVERL END EDIT

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
		// OLIVERL BEGIN EDIT
		ToxicShiftLedgeMantleComp = UIslandStormdrainToxicShiftLedgeMantleComponent::GetOrCreate(Player);
		// OLIVERL END EDIT
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerLedgeMantle::CVar_EnableLedgeMantle.GetInt() == 0)
			return false;

		if (!MoveComp.IsInAir())
			return false;

		if (MoveComp.MovementInput.IsNearlyZero())
			return false;

		if (MantleComp.GetState() != EPlayerLedgeMantleState::Inactive)
			return false;

		if (MantleComp.Data.HasValidData())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.IsInAir())
			return true;

		if(MoveComp.MovementInput.IsNearlyZero())
			return true;

		if(MantleComp.GetState() != EPlayerLedgeMantleState::Inactive)
			return true;

		if(MantleComp.Data.HasValidData())
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


#if !RELEASE
		if(IsDebugActive() || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
		{
			if(MoveComp.VerticalVelocity.Size() > (MoveComp.HorizontalVelocity.Size() * 0.8) && MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) > 0)
			{
				Debug::DrawDebugString(Player.ActorCenterLocation, "Trace For Climb", FLinearColor::Green);
			}
			else if(MoveComp.HorizontalVelocity.Size() > MoveComp.VerticalVelocity.Size())
			{
				Debug::DrawDebugString(Player.ActorCenterLocation, "Trace For Roll", FLinearColor::Yellow);
			}
			else if(MoveComp.VerticalVelocity.Size() > MoveComp.HorizontalVelocity.Size() && MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < 0)
			{
				Debug::DrawDebugString(Player.ActorCenterLocation, "Trace For Fall", FLinearColor::Red);
			}
		}
#endif

		if(HasControl())
		{
			
		}
		MantleComp.Data.Reset();	

		FHitResult PredictionHit;
		if(PredictLedgeHit(PredictionHit))
		{
			FPlayerLedgeMantleData MantleData = FPlayerLedgeMantleData();
			MantleComp.TracedForState = EPlayerLedgeMantleState::Inactive;

			if(MoveComp.VerticalVelocity.Size() > (MoveComp.HorizontalVelocity.Size() * 0.8) && MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) > 0)
			{
				if(ShouldAirborneClimbUpMantle(MantleData, PredictionHit))
				{
					MantleComp.Data = MantleData;
					return;
				} 
			}
			else if(MoveComp.HorizontalVelocity.Size() > MoveComp.VerticalVelocity.Size())
			{
				if(ShouldAirborneRollMantle(MantleData, PredictionHit))
				{
					MantleComp.Data = MantleData;
					return;
				}
			}
			else if(MoveComp.VerticalVelocity.Size() > MoveComp.HorizontalVelocity.Size() && MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < 0)
			{
				if(ShouldFallingLowMantle(MantleData, PredictionHit))
				{
					MantleComp.Data = MantleData;
					return;
				}
			}
		}
	}

	bool ShouldAirborneRollMantle(FPlayerLedgeMantleData& MantleData, FHitResult PredictionHit) const
	{
		//Only allow mantle if we are moving with a reasonable speed towards the ledge
		if (MoveComp.HorizontalVelocity.Size() < UPlayerAirMotionSettings::GetSettings(Player).HorizontalMoveSpeed * 0.25)
			return false;
		
		//TODO[AL] - Kind of magic numbering the exit distance here right now, need to look into the math for consistent enter/Exit velocity here later
		// OLIVERL BEGIN EDIT
		if (!ToxicShiftLedgeMantleComp.TraceForAirborneMantle(Player, MantleData, PredictionHit, ToxicShiftLedgeMantleComp.Settings.AirborneTopTraceHeight,
			 ToxicShiftLedgeMantleComp.Settings.AirborneMantleMaxTopDistance, 500 * ToxicShiftLedgeMantleComp.Settings.AirborneRollMantleExitDuration, false, EPlayerLedgeMantleState::AirborneMantle, IsDebugActive()))
		// OLIVERL END EDIT
			return false;

		//We have a valid Impact and a valid ledge to climb up on, Verify input towards the wall within a range
		float InputWallDot = MoveComp.MovementInput.DotProduct(-MantleData.WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp));
		float InputAngleDiff = Math::RadiansToDegrees(Math::Acos(InputWallDot));

		if(InputAngleDiff > MantleComp.Settings.InputToWallAngleCutoff)
			return false;

		return true;
	}

	bool ShouldFallingLowMantle(FPlayerLedgeMantleData& MantleData, FHitResult PredictionHit) const
	{
		// OLIVERL BEGIN EDIT
		if (!ToxicShiftLedgeMantleComp.TraceForAirborneMantle(Player, MantleData, PredictionHit, ToxicShiftLedgeMantleComp.Settings.FallingLowMantleTopTraceHeight,
			 ToxicShiftLedgeMantleComp.Settings.FallingLowMantleMaxTopDistance, ToxicShiftLedgeMantleComp.Settings.FallingLowExitDistance, true,EPlayerLedgeMantleState::FallingLowEnter, IsDebugActive()))
		// OLIVERL END EDIT
			return false;

		//We have a valid Impact and a valid ledge to climb up on, Verify input towards the wall within a range
		float InputWallDot = MoveComp.MovementInput.DotProduct(-MantleData.WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp));
		float InputAngleDiff = Math::RadiansToDegrees(Math::Acos(InputWallDot));

		if (InputAngleDiff > MantleComp.Settings.InputToWallAngleCutoff)
			return false;

		return true;
	}

	bool ShouldAirborneClimbUpMantle(FPlayerLedgeMantleData& MantleData, FHitResult PredictionHit) const
	{
		// OLIVERL BEGIN EDIT
		if(!ToxicShiftLedgeMantleComp.TraceForAirborneMantle(Player, MantleData, PredictionHit, ToxicShiftLedgeMantleComp.Settings.JumpClimbMantleTopTraceHeight,
			 ToxicShiftLedgeMantleComp.Settings.JumpClimbMantleMaxTopDistance, ToxicShiftLedgeMantleComp.Settings.JumpClimbMantleExitDistance, true, EPlayerLedgeMantleState::JumpClimbEnter, IsDebugActive()))
		// OLIVERL END EDIT
			 	return false;

		//We have a valid Impact and a valid ledge to climb up on, Verify input towards the wall within a range
		float InputWallDot = MoveComp.MovementInput.DotProduct(-MantleData.WallHit.Normal.ConstrainToPlane(MoveComp.WorldUp));
		float InputAngleDiff = Math::RadiansToDegrees(Math::Acos(InputWallDot));

		if(InputAngleDiff > MantleComp.Settings.InputToWallAngleCutoff)
			return false;

		return true;
	}

	bool PredictLedgeHit(FHitResult& PredictionHit, float MinimumForwardOffset = 50) const
	{
		if(MoveComp.Velocity.IsNearlyZero())
			return false;

		FHazeTraceSettings ForwardTrace = Trace::InitFromMovementComponent(MoveComp);
		
		FVector StartLocation = Player.ActorLocation;
		FVector EndLocation;
		if(MinimumForwardOffset > 0)
		{
			float HorizontalPredictionOffset = (MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp) * MantleComp.Settings.AirborneMantleAnticipationTime).Size();

			if(HorizontalPredictionOffset > MinimumForwardOffset)
				EndLocation = StartLocation + (MoveComp.Velocity * MantleComp.Settings.AirborneMantleAnticipationTime);
			else
			{
				FVector HorizontalDirection = MoveComp.HorizontalVelocity.Size() < 250 ? MoveComp.MovementInput.GetSafeNormal() : MoveComp.HorizontalVelocity.GetSafeNormal();
				EndLocation = StartLocation + (MoveComp.VerticalVelocity * MantleComp.Settings.AirborneMantleAnticipationTime) + HorizontalDirection * MinimumForwardOffset;
			}
		}
		else
			EndLocation = StartLocation + (MoveComp.Velocity * MantleComp.Settings.AirborneMantleAnticipationTime);
		
		if (IsDebugActive() || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
			ForwardTrace.DebugDrawOneFrame();

		FHitResult ForwardHitResult = ForwardTrace.QueryTraceSingle(StartLocation, EndLocation);
		PredictionHit = ForwardHitResult;
		
#if !RELEASE
		TEMPORAL_LOG(this).HitResults("PredictionHit", PredictionHit, ForwardTrace.Shape, ForwardTrace.ShapeWorldOffset);
#endif
		return ForwardHitResult.bBlockingHit;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
	}
};