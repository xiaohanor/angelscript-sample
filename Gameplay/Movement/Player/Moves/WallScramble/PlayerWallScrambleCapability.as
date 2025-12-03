
struct FPlayerWallScrambleActivationParams
{
	FPlayerWallScrambleData WallScrambleData;
	float HeightGain = 0.0;
}

class UPlayerWallScrambleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallScramble);
	default CapabilityTags.Add(PlayerWallScrambleTags::WallScrambleMovement);

	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 35;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	private USteppingMovementData Movement;

	UPlayerWallScrambleComponent WallScrambleComp;
	UPlayerWallRunComponent WallRunComp;
	UPlayerAirDashComponent AirDashComp;
	UPlayerLedgeMantleComponent MantleComp;
	UPrimitiveComponent CurrentlyFollowedComponent;

	UMovementImpactCallbackComponent ImpactCallbackComp;

	FVector StartLocation;
	bool bWallRunHeightWasLimited = false;

	float HeightGain = 0.0;
	bool bInvalidScrambleDetected = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		WallScrambleComp = UPlayerWallScrambleComponent::GetOrCreate(Player);
		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Player);
		AirDashComp = UPlayerAirDashComponent::GetOrCreate(Player);
		MantleComp = UPlayerLedgeMantleComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsOnWalkableGround())
			WallScrambleComp.bCanScramble = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerWallScrambleActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WallScrambleComp.bCanScramble)
			return false;

		if (!MoveComp.IsInAir())
			return false;

		FPlayerWallScrambleData WallScrambleData;
		if (!TraceForValidScramble(WallScrambleData))
			return false;

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(MoveComp);
		TraceSettings.UseLine();
		TraceSettings.UseShapeWorldOffset(FVector::ZeroVector);
		FHitResult Hit = TraceSettings.QueryTraceSingle(
			Player.ActorLocation, 
			Player.ActorLocation - MoveComp.WorldUp * WallScrambleComp.Settings.FloorHeightGain);

		float ScrambleHeightGain = WallScrambleComp.Settings.NoFloorHeightGain;

		if (!WallScrambleComp.bForceScramble)
		{
			if (Hit.bBlockingHit)
			{
				if (Math::IsNearlyZero(Math::RadiansToDegrees(MoveComp.WorldUp.AngularDistance(Hit.ImpactNormal)), 30.0))
				{
					FVector PlayerToHit = Hit.Location - Player.ActorLocation;
					float DistanceToFloor = PlayerToHit.Size();

					ScrambleHeightGain = WallScrambleComp.Settings.FloorHeightGain - DistanceToFloor;

					if (Math::IsNearlyZero(ScrambleHeightGain))
						return false;
				}
			}
		}
		
		ActivationParams.WallScrambleData = WallScrambleData;
		ActivationParams.HeightGain = ScrambleHeightGain;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FWallScrambleDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
		{
			Params.DeactivationState = EWallScrambleDeactivationStates::Interrupted;
			return true;
		}

		if(bInvalidScrambleDetected)
		{
			Params.DeactivationState = EWallScrambleDeactivationStates::Exit;
			return true;
		}

		// If the player's input is mostly backwards, cancel the scramble
		const float InputNormalAngleDifference = Math::DotToDegrees(MoveComp.MovementInput.DotProduct(WallScrambleComp.Data.WallHit.ImpactNormal));
		if (InputNormalAngleDifference <= 45.0)
		{
			Params.DeactivationState = EWallScrambleDeactivationStates::Cancel;
        	return true;
		}
		
		// If the player has gained enough height
		FVector StartToPlayer = Player.ActorLocation - StartLocation;
		if (StartToPlayer.DotProduct(MoveComp.WorldUp) >= HeightGain)
		{

#if !RELEASE
			if(IsDebugActive() || PlayerWallScramble::CVar_DebugWallScramble.GetInt() == 1)
				PrintToScreen("Scramble height" + HeightGain, 5);
#endif

			Params.DeactivationState = EWallScrambleDeactivationStates::Exit;
        	return true;
		}

		if (MoveComp.HasCeilingContact())
		{
			Params.DeactivationState = EWallScrambleDeactivationStates::Cancel;
        	return true;
		}

		if ((!WallScrambleComp.Data.PredictedScrambleHit.bBlockingHit || WallScrambleComp.Data.PredictedScrambleHit.bStartPenetrating))
		{
			Params.DeactivationState = EWallScrambleDeactivationStates::Cancel;
        	return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerWallScrambleActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::WallScramble, this);

		WallScrambleComp.Data = ActivationParams.WallScrambleData;
		HeightGain = ActivationParams.HeightGain;
		bInvalidScrambleDetected = false;

		WallScrambleComp.SetState(EPlayerWallScrambleState::Scramble);

		MoveComp.FollowComponentMovement(WallScrambleComp.Data.WallHit.Component, this);
		CurrentlyFollowedComponent = WallScrambleComp.Data.WallHit.Component;
		
		WallScrambleComp.bCanScramble = false;

		StartLocation = Player.ActorLocation;

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		WallRunComp.bHasWallRunnedSinceLastGrounded = true;
		if (WallRunComp.bHasWallRunnedSinceLastGrounded)
		{
			bWallRunHeightWasLimited = true;
			WallRunComp.LastWallRunNormal = ActivationParams.WallScrambleData.WallHit.Normal;
		}
		else
		{
			bWallRunHeightWasLimited = false;
			WallRunComp.LastWallRunNormal = ActivationParams.WallScrambleData.WallHit.Normal;
			WallRunComp.InitialWallRunHeightLimitLocation = Player.ActorLocation;
		}

		ImpactCallbackComp = UMovementImpactCallbackComponent::Get(WallScrambleComp.Data.WallHit.Actor);
		if (ImpactCallbackComp != nullptr)
			ImpactCallbackComp.AddWallAttachInstigator(Player, this);

		UPlayerCoreMovementEffectHandler::Trigger_WallScramble_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FWallScrambleDeactivationParams Params)
	{
		WallScrambleComp.bForceScramble = false;
		MoveComp.UnFollowComponentMovement(this);

		Player.UnblockCapabilities(BlockedWhileIn::WallScramble, this);		

		switch(Params.DeactivationState)
		{
			case(EWallScrambleDeactivationStates::Inactive):
				break;
			
			case(EWallScrambleDeactivationStates::Cancel):
				WallScrambleComp.State = EPlayerWallScrambleState::Exit;
				WallScrambleComp.Data.bWallScrambleComplete = true;
				break;

			case(EWallScrambleDeactivationStates::Exit):
				WallScrambleComp.State = EPlayerWallScrambleState::Exit;
				WallScrambleComp.Data.bWallScrambleComplete = true;
				break;

			case(EWallScrambleDeactivationStates::Jump):
				WallScrambleComp.Data.bWallScrambleComplete = true;
				break;

			case(EWallScrambleDeactivationStates::LedgeGrab):
				break;

			case(EWallScrambleDeactivationStates::Interrupted):
				break;

			default:
				break;
		}

		WallScrambleComp.StateCompleted(EPlayerWallScrambleState::Scramble);

		if (ImpactCallbackComp != nullptr)
		{
			ImpactCallbackComp.RemoveWallAttachInstigator(Player, this);
			ImpactCallbackComp = nullptr;
		}

		UPlayerCoreMovementEffectHandler::Trigger_WallScramble_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!TraceForValidScramble(WallScrambleComp.Data))
			bInvalidScrambleDetected = true;

		if (!bWallRunHeightWasLimited)
			WallRunComp.InitialWallRunHeightLimitLocation = Player.ActorLocation;

		if(MoveComp.PrepareMove(Movement))
		{			
			if (HasControl())
			{
				//Check we if swapped mesh while scrambling and if so follow the new one
				if(WallScrambleComp.Data.WallHit.Component != CurrentlyFollowedComponent)
				{
					MoveComp.UnFollowComponentMovement(this);
					MoveComp.FollowComponentMovement(WallScrambleComp.Data.WallHit.Component, this);
					CurrentlyFollowedComponent = WallScrambleComp.Data.WallHit.Component;
				}

				FVector WallToPlayer = (Owner.ActorLocation - WallScrambleComp.Data.WallHit.ImpactPoint).ConstrainToPlane(MoveComp.WorldUp);
				FVector ToWallDelta = Math::VInterpTo(WallToPlayer, WallToPlayer.GetSafeNormal() * WallScrambleComp.WallSettings.TargetDistanceToWall, DeltaTime, 20.0) - WallToPlayer;

				// Hug Wall
				Movement.AddDeltaWithCustomVelocity(ToWallDelta, FVector::ZeroVector);

				// Move Upwards
				FVector DeltaMove = MoveComp.WorldUp * WallScrambleComp.Settings.ScrambleSpeed * DeltaTime;
				Movement.AddDelta(DeltaMove);

				// Rotate Player
				FQuat TargetRotation = FQuat::MakeFromXZ(-WallScrambleComp.Data.WallHit.ImpactNormal, MoveComp.WorldUp);
				FQuat NewRotation = Math::QInterpConstantTo(Owner.ActorQuat, TargetRotation, DeltaTime, Math::DegreesToRadians(720.0));
				Movement.SetRotation(NewRotation);
			}
			else // Remote
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WallScramble");
		}
	}

	bool TraceForValidScramble(FPlayerWallScrambleData& WallScrambleData) const
	{
		FHitResult WallTrace = TraceForWall();

#if !RELEASE
		FTemporalLog TempLog = TEMPORAL_LOG(this).Section("ValidScrambleTrace");
#endif

		// Did you hit a wall?
		if (!WallTrace.bBlockingHit)
			return false;

		if (!WallTrace.Component.HasTag(ComponentTags::WallScrambleable))
			return false;
		
		// Check for the wall verticality
   		float WallPitch = 90.0 - Math::RadiansToDegrees(WallTrace.ImpactNormal.AngularDistance(MoveComp.WorldUp));
		if (WallPitch > WallScrambleComp.WallSettings.WallPitchMaximum + KINDA_SMALL_NUMBER || WallPitch < WallScrambleComp.WallSettings.WallPitchMinimum - KINDA_SMALL_NUMBER)
			return false;

		// Make sure that input is towards the wall
		if(!WallScrambleComp.bForceScramble && WallScrambleComp.State == EPlayerWallScrambleState::None)
		{
			float InputAngleDifference = Math::DotToDegrees(MoveComp.MovementInput.DotProduct(-WallTrace.ImpactNormal));
			if ((InputAngleDifference >= 90.0 && WallScrambleComp.State == EPlayerWallScrambleState::None))
			{
				return false;
			}
		}

		// Line trace to make sure we have a wall at roughly hand position along the wall
		FHazeTraceSettings HandHeightTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		HandHeightTraceSettings.UseLine();
		HandHeightTraceSettings.UseShapeWorldOffset(FVector::ZeroVector);

#if !RELEASE
		if (IsDebugActive() || PlayerWallScramble::CVar_DebugWallScramble.GetInt() == 1)
			HandHeightTraceSettings.DebugDrawOneFrame();
#endif

		FVector HandTraceStart = Player.ActorLocation + (MoveComp.WorldUp * WallScrambleComp.Settings.TopHeight);
		FVector HandTraceEnd = HandTraceStart - (WallTrace.Normal * (WallScrambleComp.WallSettings.TargetDistanceToWall + 10));

		FHitResult HandHeightHit = HandHeightTraceSettings.QueryTraceSingle(HandTraceStart, HandTraceEnd);

#if !RELEASE
		TempLog.HitResults("HandHit1", HandHeightHit, HandHeightTraceSettings.Shape, HandHeightTraceSettings.ShapeWorldOffset);
#endif

		if (!HandHeightHit.bBlockingHit)
		{
			//If initial trace failed, retrace slightly higher up incase we hit inbetween 2 meshes
			HandHeightHit = HandHeightTraceSettings.QueryTraceSingle(HandTraceStart + (MoveComp.WorldUp * 5), HandTraceEnd + (MoveComp.WorldUp * 5));

#if !RELEASE
				TempLog.HitResults("HandHit2", HandHeightHit, HandHeightTraceSettings.Shape, HandHeightTraceSettings.ShapeWorldOffset);
#endif

			if(!HandHeightHit.bBlockingHit)
				return false;
		}

		//Line trace to make sure we have a wall at roughly our foot position along the wall
		FHazeTraceSettings FootHeightTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		FootHeightTraceSettings.UseLine();
		FootHeightTraceSettings.UseShapeWorldOffset(FVector::ZeroVector);

#if !RELEASE
		if (IsDebugActive() || PlayerWallScramble::CVar_DebugWallScramble.GetInt() == 1)
			FootHeightTraceSettings.DebugDrawOneFrame();
#endif

		FVector FootTraceStart = Player.ActorLocation + (MoveComp.WorldUp * WallScrambleComp.Settings.BottomHeight);
		FVector FootTraceEnd = FootTraceStart - (WallTrace.Normal * (WallScrambleComp.WallSettings.TargetDistanceToWall + 10));

		FHitResult FootHeightHit = FootHeightTraceSettings.QueryTraceSingle(FootTraceStart, FootTraceEnd);
	
#if !RELEASE
		TempLog.HitResults("FootHit1", FootHeightHit, FootHeightTraceSettings.Shape, FootHeightTraceSettings.ShapeWorldOffset);
#endif

		if(!FootHeightHit.bBlockingHit)
		{
			//Incase our initial foot height trace failed then trace slightly above initial position (incase we hit inbetween 2 meshes)

			FootHeightHit = FootHeightTraceSettings.QueryTraceSingle(FootTraceStart + (MoveComp.WorldUp * 5), FootTraceEnd + (MoveComp.WorldUp * 5));

#if !RELEASE
			TempLog.HitResults("FootHit2", FootHeightHit, FootHeightTraceSettings.Shape, FootHeightTraceSettings.ShapeWorldOffset);
#endif
			if(!FootHeightHit.bBlockingHit)		
				return false;
		}

		FHazeTraceSettings PredictionTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		PredictionTraceSettings.UseLine();
		PredictionTraceSettings.UseShapeWorldOffset(FVector::ZeroVector);

		FVector PredictionTraceStart = Player.ActorLocation + (MoveComp.WorldUp * (WallScrambleComp.Settings.TopHeight + WallScrambleComp.Settings.PredictionHeight));
		FVector PredictionTraceEnd = PredictionTraceStart - (WallTrace.Normal * (WallScrambleComp.WallSettings.TargetDistanceToWall + 10));

		FHitResult PredictionHit = PredictionTraceSettings.QueryTraceSingle(PredictionTraceStart, PredictionTraceEnd);
		
#if !RELEASE
		TempLog.HitResults("PredictionHit1", PredictionHit, PredictionTraceSettings.Shape, PredictionTraceSettings.ShapeWorldOffset);
#endif

		WallScrambleData.PredictedScrambleHit = PredictionHit;
		WallScrambleData.WallHit = WallTrace;
		WallScrambleData.WallPitch = WallPitch;

		if(PredictionHit.bStartPenetrating)
			return false;

		if(!PredictionHit.bBlockingHit)
		{
			//Retrace slightly higher to make sure we arent hitting inbetween meshes
			PredictionHit = PredictionTraceSettings.QueryTraceSingle(PredictionTraceStart + (MoveComp.WorldUp * 5), PredictionTraceEnd + (MoveComp.WorldUp * 5));

#if !RELEASE
			TempLog.HitResults("PredictionHit2", PredictionHit, PredictionTraceSettings.Shape, PredictionTraceSettings.ShapeWorldOffset);
#endif

			WallScrambleData.PredictedScrambleHit = PredictionHit;

			if(!PredictionHit.bStartPenetrating && PredictionHit.bBlockingHit)
				return true;

			//If we are currently scrambling then check for a valid mantle surface
			if(WallScrambleComp.State == EPlayerWallScrambleState::Scramble)
			{
				//If we have a valid mantle surface, assign data so MantleEnter can attempt to activate
				FPlayerLedgeMantleData MantleData;
				if(MantleComp.TraceForScrambleMantle(Player, MantleData, WallScrambleData, IsDebugActive()))
					MantleComp.Data = MantleData;
			}

			//Return invalid scramble surface so if mantle doesnt take over we go into Scramble Exit
			return false;
		}

		return true;
	}

	FHitResult TraceForWall() const
	{
		FHazeTraceSettings Settings = Trace::InitFromMovementComponent(MoveComp);

#if !RELEASE
		FTemporalLog TempLog = TEMPORAL_LOG(this).Section("ScrambleWallTrace");
#endif

		FVector TraceStart = Player.ActorLocation;
		FVector TraceEnd = TraceStart;

		if (IsActive() && ActiveDuration > 0.0 && WallScrambleComp.Data.WallHit.IsValidBlockingHit())
		{
			// If active, trace towards the wall
			TraceEnd -= WallScrambleComp.Data.WallHit.ImpactNormal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal() * Math::Max(WallScrambleComp.WallSettings.WallTraceForwardReach - Player.CapsuleComponent.CapsuleRadius, 0.0);
		}
		else
		{
			// If inactive, trace velocity or forward vector based on length
			FVector TraceDirection = MoveComp.MovementInput.GetSafeNormal();
			if (TraceDirection.IsNearlyZero() || WallScrambleComp.bForceScramble)
				TraceDirection = Player.ActorForwardVector;
			TraceEnd += TraceDirection * Math::Max(WallScrambleComp.WallSettings.WallTraceForwardReach - Player.CapsuleComponent.CapsuleRadius, 0.0);
		}

		if((TraceEnd - TraceStart).Size() < KINDA_SMALL_NUMBER)
			return FHitResult();

		FHitResult WallHit = Settings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
		TempLog.HitResults("WallTrace: ", WallHit, Settings.Shape, Settings.ShapeWorldOffset);
#endif

		return WallHit;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		if(WallScrambleComp.Data.WallHit.bBlockingHit)
			TemporalLog.Value("Scrambling On Object: ", WallScrambleComp.Data.WallHit.Actor.Name);
	}
}

struct FWallScrambleDeactivationParams
{
	EWallScrambleDeactivationStates DeactivationState;
}

enum EWallScrambleDeactivationStates
{
	Inactive,
	Scrambling,
	Cancel,
	Jump,
	LedgeGrab,
	Exit,
	Interrupted
}