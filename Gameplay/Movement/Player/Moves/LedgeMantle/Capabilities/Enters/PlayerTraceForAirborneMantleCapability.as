class UPlayerTraceForAirborneMantleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleEvaluate);
	
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
	UPlayerWallScrambleComponent WallScrambleComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
		WallScrambleComp = UPlayerWallScrambleComponent::Get(Player);

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerLedgeMantle::CVar_EnableLedgeMantle.GetInt() == 0)
			return false;

		if (!MoveComp.IsInAir())
			return false;

		if (WallScrambleComp.State == EPlayerWallScrambleState::Scramble)
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

		if (WallScrambleComp.State == EPlayerWallScrambleState::Scramble)
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

		if(MantleComp.State == EPlayerLedgeMantleState::Inactive)
			MantleComp.Data.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

#if !RELEASE
		if(IsDebugActive() || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
		{
			if(MoveComp.VerticalVelocity.Size() > (MoveComp.HorizontalVelocity.Size() * 0.5))
			{
				if(MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) > 0)
					Debug::DrawDebugString(Player.ActorCenterLocation, "Trace For Climb", FLinearColor::Green);
				else
					Debug::DrawDebugString(Player.ActorCenterLocation, "Trace For Fall", FLinearColor::Red);
			}
			else
			{
				Debug::DrawDebugString(Player.ActorCenterLocation, "Trace For Roll", FLinearColor::Yellow);
			}
		}
#endif

		MantleComp.Data.Reset();	

		if(HasControl())
		{
			FHitResult PredictionHit;
			if(PredictLedgeHit(PredictionHit))
			{
				FPlayerLedgeMantleData MantleData = FPlayerLedgeMantleData();
				MantleComp.TracedForState = EPlayerLedgeMantleState::Inactive;

				if(MoveComp.VerticalVelocity.Size() > (MoveComp.HorizontalVelocity.Size() * 0.5))
				{
					if(MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) > 0)
					{
						if(ShouldAirborneClimbUpMantle(MantleData, PredictionHit))
						{
							MantleComp.Data = MantleData;
							return;
						} 
					}
					else
					{
						if(ShouldFallingLowMantle(MantleData, PredictionHit))
						{
							MantleComp.Data = MantleData;
							return;
						}
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
			}
		}
	}

	bool ShouldAirborneRollMantle(FPlayerLedgeMantleData& MantleData, FHitResult PredictionHit) const
	{
		//Only allow mantle if we are moving with a reasonable speed towards the ledge
		if (MoveComp.HorizontalVelocity.Size() < UPlayerAirMotionSettings::GetSettings(Player).HorizontalMoveSpeed * 0.25)
			return false;
		
		//TODO[AL] - Kind of magic numbering the exit distance here right now, need to look into the math for consistent enter/Exit velocity here later
		if (!MantleComp.TraceForAirborneMantle(Player, MantleData, PredictionHit, MantleComp.Settings.AirborneTopTraceHeight,
			 MantleComp.Settings.AirborneMantleMaxTopDistance, 500 * MantleComp.Settings.AirborneRollMantleExitDuration, false, EPlayerLedgeMantleState::AirborneMantle, IsDebugActive()))
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
		if (!MantleComp.TraceForAirborneMantle(Player, MantleData, PredictionHit, MantleComp.Settings.FallingLowMantleTopTraceHeight,
			 MantleComp.Settings.FallingLowMantleMaxTopDistance, MantleComp.Settings.FallingLowExitDistance, true,EPlayerLedgeMantleState::FallingLowEnter, IsDebugActive()))
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
		if(!MantleComp.TraceForAirborneMantle(Player, MantleData, PredictionHit, MantleComp.Settings.JumpClimbMantleTopTraceHeight,
			 MantleComp.Settings.JumpClimbMantleMaxTopDistance, MantleComp.Settings.JumpClimbMantleExitDistance, true, EPlayerLedgeMantleState::JumpClimbEnter, IsDebugActive()))
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
		
		return ForwardHitResult.bBlockingHit;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{

	}
};