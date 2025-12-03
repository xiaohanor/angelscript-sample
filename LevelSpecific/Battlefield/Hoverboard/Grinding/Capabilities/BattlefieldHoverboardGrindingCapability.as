struct FBattlefieldHoverboardGrindingActivationParams
{
	UBattlefieldHoverboardGrindSplineComponent EnteredGrindSplineComp;
	FSplinePosition StartSplinePos;
	float SpeedAtActivation = 0.0;
	bool bActivatedFromRespawn = false;
}

struct FBattlefieldHoverboardGrindingDeactivationParams
{
	bool bFellOffBecauseOfBalance = false;
}

class UBattlefieldHoverboardGrindingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"BattlefieldGrinding");

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 80);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardComponent HoverboardComp;

	USteppingMovementData Movement;

	UBattlefieldHoverboardGrindingSettings GrindSettings;
	UBattlefieldHoverboardGrappleSettings GrappleSettings;

	UBattlefieldHoverboardGrindSplineComponent GrindCurrentlyOn;
	const float WantedRotationInterpSpeed = 10.0;
	const float GrindOffsetInterpSpeed = 12.0;

	FVector GrindInitialOffset;

	bool bTargetHasReachedEnd = false;
	float CurrentSpeed = 0.0;
	float LastTimeFellOffFromBalance = -MAX_flt;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		
		Movement = MoveComp.SetupSteppingMovementData();

		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
		GrappleSettings = UBattlefieldHoverboardGrappleSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardGrindingActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!HoverboardComp.IsOn())
			return false;

		if(GrindComp.RespawnActivationParams.IsSet())
		{
			Params = GrindComp.RespawnActivationParams.Value;
			return true;
		}

		if(DeactiveDuration < 0.1)
			return false;
		
		if(Time::GetGameTimeSince(LastTimeFellOffFromBalance) < 0.6)
			return false;

		// To make sure you don't spam jump when just leaving the grind by jumping
		if(GrindComp.bIsJumpingWhileGrinding
		&& !MoveComp.HasGroundContact()
		&& MoveComp.VerticalSpeed < 0)
			return false;


		UBattlefieldHoverboardGrindSplineComponent EnteredGrindSplineComp;
		// if(MoveComp.HasWallContact())
		// {
		// 	auto WallHit = MoveComp.WallContact; 
		// 	EnteredGrindSplineComp = UBattlefieldHoverboardGrindSplineComponent::Get(WallHit.Actor);
		// }
		if(EnteredGrindSplineComp == nullptr
		&& MoveComp.HasGroundContact())
		{
			auto GroundHit = MoveComp.GroundContact; 
			EnteredGrindSplineComp = UBattlefieldHoverboardGrindSplineComponent::Get(GroundHit.Actor);
		}
		if(EnteredGrindSplineComp == nullptr)
			EnteredGrindSplineComp = GrindComp.GetFirstValidStartGrindSpline(MoveComp.IsOnAnyGround());

		if(EnteredGrindSplineComp == nullptr)
			return false;

		Params.EnteredGrindSplineComp = EnteredGrindSplineComp;
		Params.StartSplinePos = EnteredGrindSplineComp.SplineComp.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);

		if(EnteredGrindSplineComp.bForcedDirection)
		{
			if(EnteredGrindSplineComp.bForceForward)
			{
				if(!Params.StartSplinePos.IsForwardOnSpline())
					Params.StartSplinePos.ReverseFacing();
			}
			else
			{
				if(Params.StartSplinePos.IsForwardOnSpline())
					Params.StartSplinePos.ReverseFacing();
			}
		}
		else
		{
			if(Params.StartSplinePos.WorldRotation.ForwardVector.DotProduct(Player.ActorForwardVector) < 0)
				Params.StartSplinePos.ReverseFacing();
		}
		Params.SpeedAtActivation = Player.ActorVelocity.Size();
		if (Params.SpeedAtActivation < GrappleSettings.GrappleMinimumSpeed && HoverboardComp.bHasQueuedCavernSpeedInitialization)
			Params.SpeedAtActivation = GrappleSettings.GrappleMinimumSpeed;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FBattlefieldHoverboardGrindingDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!HoverboardComp.IsOn())
			return true;

		if(MoveComp.HasWallContact())
		{
			auto WallHit = MoveComp.WallContact; 
			if(UBattlefieldHoverboardGrindSplineComponent::Get(WallHit.Actor) == nullptr)
				return true;
		}

		if(MoveComp.HasGroundContact())
		{
			auto GroundHit = MoveComp.GroundContact; 
			if(UBattlefieldHoverboardGrindSplineComponent::Get(GroundHit.Actor) == nullptr)
				return true;
		}

		if(Math::Abs(GrindComp.GrindBalance) > 0.98)
		{
			Params.bFellOffBecauseOfBalance = true;
			return true;
		}

		if(bTargetHasReachedEnd)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardGrindingActivationParams Params)
	{
		HoverboardComp.bHasQueuedCavernSpeedInitialization = false;
		GrindCurrentlyOn = Params.EnteredGrindSplineComp;
		GrindComp.CurrentGrindSplineComp = GrindCurrentlyOn;
		GrindComp.CurrentSplinePos = Params.StartSplinePos;

		GrindInitialOffset = Player.ActorLocation -  GrindComp.CurrentSplinePos.WorldLocation;

		GrindComp.GrindBalance = 0.0;
		float VelocityDotSplineRight = MoveComp.PreviousVelocity.DotProduct(GrindComp.CurrentSplinePos.WorldRightVector);
		float NormalizedSpeedToSplineRight = Math::NormalizeToRange(Math::Abs(VelocityDotSplineRight), 0.0, GrindSettings.SpeedSidewaysForMaximumBalanceLandImpulse);
		NormalizedSpeedToSplineRight = Math::Clamp(NormalizedSpeedToSplineRight, 0, 1.0);
		float LandBalanceImpulse = NormalizedSpeedToSplineRight * GrindSettings.MaximumBalanceLandImpulse * Math::Sign(VelocityDotSplineRight);
		GrindComp.GrindBalanceVelocity = LandBalanceImpulse;

		TEMPORAL_LOG(Player, "Grind Balance")
			.Value("Land Impulse", LandBalanceImpulse)
			.Value("Normalized Speed to Spline right", NormalizedSpeedToSplineRight)
		;

		CurrentSpeed = Params.SpeedAtActivation;

		bTargetHasReachedEnd = false;

		if(Params.EnteredGrindSplineComp.OverridingCameraSettings != nullptr)
			Player.ApplySettings(Params.EnteredGrindSplineComp.OverridingCameraSettings, this);
		else
			Player.ApplySettings(BattlefieldHoverboardDefaultGrindCameraSettings, this);
		if(Params.EnteredGrindSplineComp.GrindSettings != nullptr)
			Player.ApplySettings(Params.EnteredGrindSplineComp.GrindSettings, this, EHazeSettingsPriority::Override);

		Player.ApplyCameraSettings(GrindSettings.CameraSettings, GrindSettings.CameraBlendTime, this, EHazeCameraPriority::VeryHigh);
		if(GrindCurrentlyOn.bGrindCameraShake)
			Player.PlayCameraShake(GrindSettings.GrindCameraShake, this);

		if(GrindCurrentlyOn.bAlignPlayerWithGrind)
			Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		MoveComp.AddMovementIgnoresActor(this, GrindCurrentlyOn.Owner);

		GrindCurrentlyOn.AddOnGrindInstigator(Player, this);
		GrindComp.bIsOnGrind = true;
		GrindComp.GrindingInstigators.Add(this);

		GrindComp.OnStartedGrinding.Broadcast(GrindCurrentlyOn, Player);
		GrindCurrentlyOn.OnPlayerStartedGrinding.Broadcast(GrindCurrentlyOn, Player);

		if(Params.bActivatedFromRespawn)
			GrindComp.RespawnActivationParams.Reset();

		FBattlefieldHoverboardGrindEffectParams EffectParams;
		EffectParams.AttachRootOnHoverboard = HoverboardComp.Hoverboard.RootComponent;
		EffectParams.GrindSpline = GrindCurrentlyOn;
		UBattlefieldHoverboardEffectHandler::Trigger_OnStartedGrinding(HoverboardComp.Hoverboard, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBattlefieldHoverboardGrindingDeactivationParams Params)
	{
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 2.0);
		if(GrindCurrentlyOn.bGrindCameraShake)
			Player.StopCameraShakeByInstigator(this);

		MoveComp.RemoveMovementIgnoresActor(this);

		GrindCurrentlyOn.RemoveOnGrindInstigator(Player, this);
		GrindComp.bIsOnGrind = false;
		GrindComp.GrindingInstigators.RemoveSingleSwap(this);

		if(GrindCurrentlyOn.bAlignPlayerWithGrind)
			Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);

		HoverboardComp.ResetWantedRotationToCurrentRotation();
		HoverboardComp.AccRotation.SnapTo(HoverboardComp.WantedRotation);

		GrindComp.OnStoppedGrinding.Broadcast(GrindCurrentlyOn, Player);
		GrindCurrentlyOn.OnPlayerStoppedGrinding.Broadcast(GrindCurrentlyOn, Player);

		if(Params.bFellOffBecauseOfBalance)
		{
			LastTimeFellOffFromBalance = Time::GameTimeSeconds;
			FVector Impulse 
				= GrindComp.CurrentSplinePos.WorldRightVector * GrindSettings.BalanceFallOffSidewaysImpulseSize * GrindComp.GrindBalance
				- GrindComp.CurrentSplinePos.WorldUpVector * GrindSettings.BalanceFallOffDownwardsImpulseSize;
			MoveComp.AddPendingImpulse(Impulse);
		}

		UBattlefieldHoverboardEffectHandler::Trigger_OnStoppedGrinding(HoverboardComp.Hoverboard);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Default argument into prepare move
		FVector WorldUp = FVector::ZeroVector;
		GrindComp.CurrentSplinePos = GrindComp.CurrentSplinePos.CurrentSpline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		if(GrindCurrentlyOn.bAlignPlayerWithGrind)
			WorldUp = GrindComp.CurrentSplinePos.WorldUpVector;

		if (MoveComp.PrepareMove(Movement, WorldUp))
		{
			if (HasControl())
			{
				CurrentSpeed = Math::Clamp(CurrentSpeed, GrindSettings.MinGrindingSpeed, GrindSettings.MaxGrindingSpeed);

				float TotalSpeed = CurrentSpeed + GrindComp.AccGrindRubberbandingSpeed.Value;

				float RemainingDistance = 0.0;
				bTargetHasReachedEnd = !GrindComp.CurrentSplinePos.Move(TotalSpeed * DeltaTime, RemainingDistance);
				FVector SplineWorldLocation = GrindComp.CurrentSplinePos.WorldLocation;

				GrindInitialOffset = Math::VInterpTo(GrindInitialOffset, FVector::ZeroVector, DeltaTime, GrindOffsetInterpSpeed);
				FVector GrindBalanceOffset 
					= GrindComp.CurrentSplinePos.WorldRightVector * GrindComp.GrindBalance * GrindSettings.BalanceOffsetMax.Y
					- GrindComp.CurrentSplinePos.WorldUpVector * Math::Abs(GrindComp.GrindBalance) * GrindSettings.BalanceOffsetMax.Z;

				FVector TargetLocation = SplineWorldLocation + GrindInitialOffset + GrindBalanceOffset;
				
				float DistanceToEndOfGrind = GrindComp.CurrentSplinePos.IsForwardOnSpline() 
					? GrindComp.CurrentGrindSplineComp.SplineComp.SplineLength - GrindComp.CurrentSplinePos.CurrentSplineDistance
					: GrindComp.CurrentSplinePos.CurrentSplineDistance;

				if(DistanceToEndOfGrind <= TotalSpeed * DeltaTime)
					Movement.AddDelta(GrindComp.CurrentSplinePos.WorldForwardVector * TotalSpeed * DeltaTime);
				else
					Movement.AddDelta(TargetLocation - Player.ActorLocation);

				FRotator TargetRotation = GrindComp.CurrentSplinePos.WorldRotation.Rotator();
				if(!GrindCurrentlyOn.bAlignPlayerWithGrind)
				{
					TargetRotation.Pitch = 0;
					TargetRotation.Roll = 0;
				}
				FRotator NewRotation = Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, GrindSettings.RotationInterpSpeed);
				Movement.SetRotation(NewRotation);

				Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.5), EMovementEdgeNormalRedirectType::Hard);

				bool bDisregardCameraPitch = !GrindComp.CurrentGrindSplineComp.bAlignPlayerWithGrind;
				FRotator CameraLookAheadRotation = GrindComp.GetCameraLookAheadRotation(GrindComp.CurrentSplinePos, TotalSpeed, bDisregardCameraPitch);
				HoverboardComp.CameraWantedRotation = Math::RInterpTo(HoverboardComp.CameraWantedRotation, CameraLookAheadRotation, DeltaTime, WantedRotationInterpSpeed);
				
				TEMPORAL_LOG(Player, "Hoverboard Grinding")
					.DirectionalArrow("Grind Offset", Player.ActorLocation, GrindInitialOffset, 5, 40, FLinearColor::Green)
					.Value("Remaining Distance", RemainingDistance)
					.Value("Distance to end of grind", DistanceToEndOfGrind)
					.Sphere("Spline Pos", GrindComp.CurrentSplinePos.WorldLocation, 50, FLinearColor::Red, 10)
					.Rotation("Spline Pos Rotation", TargetRotation, GrindComp.CurrentSplinePos.WorldLocation, 2000.0)
				;

				ApplyHaptics();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"HoverboardGrinding");
		}
	}

	private void ApplyHaptics()
	{
		FHazeFrameForceFeedback ForceFeedBack;

		float BaseValue = 0.15;
		float NoiseBased = 0.05 * ((Math::PerlinNoise1D(Time::GameTimeSeconds * 4.5) + 1.0) * 0.5);
		
		float MotorStrength = (BaseValue + NoiseBased);

		ForceFeedBack.LeftMotor = MotorStrength;
		ForceFeedBack.RightMotor = MotorStrength;
		Player.SetFrameForceFeedback(ForceFeedBack);
	}
};