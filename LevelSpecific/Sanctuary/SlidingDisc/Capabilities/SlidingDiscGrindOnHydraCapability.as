struct FSlidingDiscGrindOnHydraActivationParams
{
	ADiscSlideHydra Hydra;
}

class USlidingDiscGrindOnHydraCapability : UHazeCapability
{
	FSlidingDiscGrindOnHydraActivationParams ActivatedParams;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb; // maybeh?

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 30; // Before SlidingDiscMovement
	default CapabilityTags.Add(SlidingDiscTags::GrindingDiscMovement);

	UHazeMovementComponent MovementComponent;
	USimpleMovementData Movement;
	ASlidingDisc SlidingDisc;

	FVector Direction;
	FHazeAcceleratedFloat AccSpeed;

	bool bShouldExit = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSimpleMovementData();
		SlidingDisc = Cast<ASlidingDisc>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSlidingDiscGrindOnHydraActivationParams & Params) const
	{
		if(MovementComponent.HasMovedThisFrame())
			return false;

		if(SlidingDisc.GrindingOnHydra == nullptr)
			return false;

		if(SlidingDisc.GrindingOnHydra.SurfaceActor.RuntimeSpline.Points.Num() == 0)
			return false;

		Params.Hydra = SlidingDisc.GrindingOnHydra;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActivatedParams.Hydra.SkeletalMesh.GetAnimInstance() == nullptr)
			return true;

		if (bShouldExit)
			return true;

		if(SlidingDisc.GrindingOnHydra == nullptr)
			return true;

		if(SlidingDisc.GrindingOnHydra != ActivatedParams.Hydra)
			return true;

		if(MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSlidingDiscGrindOnHydraActivationParams Params)
	{
		ActivatedParams = Params;
		SlidingDisc.BlockCapabilities(SlidingDiscTags::SlidingDiscMovement, this);
		SlidingDisc.GrindingOnHydra = ActivatedParams.Hydra;
		AccSpeed.SnapTo(MovementComponent.Velocity.Size());
		Direction = MovementComponent.Velocity.GetSafeNormal();
		// AccLocation.SnapTo(FVector::ZeroVector);
		SlidingDisc.AccPivotRot.SnapTo(SlidingDisc.BasePivot.ComponentQuat);
		bShouldExit = false;

		DevPrintStringCategory(n"SlidingDisc", "Disc", "On Hydra", 3.0, ColorDebug::Lapis);
		USlidingDiscEventHandler::Trigger_OnHydra(SlidingDisc);

		for (auto Player : Game::Players)
		{
			// Player.BlockCapabilities(CameraTags::CameraModifiers, this);
			Player.ApplyCameraSettings(SlidingDisc.GrindingOnHydra.CameraSettings, 1.0, this, EHazeCameraPriority::VeryHigh);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto Player : Game::Players)
		{
			// Player.UnblockCapabilities(CameraTags::CameraModifiers, this);
			Player.ClearCameraSettingsByInstigator(this, 1.0);
		}

		DevPrintStringCategory(n"SlidingDisc", "Disc", "Airborne", 3.0, ColorDebug::Eggblue);
		USlidingDiscEventHandler::Trigger_OnAirborne(SlidingDisc);

		SlidingDisc.UnblockCapabilities(SlidingDiscTags::SlidingDiscMovement, this);
		if (SlidingDisc.GrindingOnHydra.SurfaceActor != nullptr)
			SlidingDisc.GrindingOnHydra.SurfaceActor.bPlayersAreGrinding = false;

		SlidingDisc.GrindingOnHydra.bManuallyHopOffGrind = false;
		SlidingDisc.GrindingOnHydra = nullptr;
		SlidingDisc.bHasHoppedOnGrinding = false;
		ActivatedParams = FSlidingDiscGrindOnHydraActivationParams();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(Movement))
		{
			if(HasControl())
				DirectionalMovementNew(DeltaTime);
			else
				Movement.ApplyCrumbSyncedAirMovement();

			MovementComponent.ApplyMove(Movement);
		}

		FHazeFrameForceFeedback FrameForceFeedback;
		FrameForceFeedback.LeftMotor = 0.20;
		FrameForceFeedback.RightMotor = 0.20;
		ForceFeedback::PlayWorldForceFeedbackForFrame(FrameForceFeedback, SlidingDisc.ActorLocation);
	}

	private void DirectionalMovementNew(float DeltaTime)
	{
		AccSpeed.AccelerateTo(ActivatedParams.Hydra.TriggerGrindingComp.GrindSpeed, 5.0, DeltaTime);

		if (ActivatedParams.Hydra.bManuallyHopOffGrind)
		{
			auto DiscExitComp = UDiscSlideHydraExitGrindComponent::Get(ActivatedParams.Hydra);
			if (DiscExitComp != nullptr)
			{
				FVector ImpulseEndWorldLocation = DiscExitComp.WorldTransform.TransformPosition(DiscExitComp.ExitImpulse);
				FVector WorldImpulseDirection = ImpulseEndWorldLocation - DiscExitComp.WorldLocation;
				Movement.AddVelocity(WorldImpulseDirection);
			}
			// Movement.AddOwnerVelocity(); // we 100% override the speed atm
			// Movement.AddVelocity(FVector::UpVector * ActivatedParams.Hydra.TriggerGrindingComp.GrindExitUpwardsImpulse);
			// Movement.AddVelocity(SlidingDisc.BasePivot.WorldRotation.ForwardVector * ActivatedParams.Hydra.TriggerGrindingComp.GrindExitSpeed);
			// Movement.AddGravityAcceleration();
			bShouldExit = true;
			return;
		}
		
		const FHazeRuntimeSpline& Spliney = ActivatedParams.Hydra.SurfaceActor.RuntimeSpline;
		float ClosestDistance = Spliney.GetClosestSplineDistanceToLocation(SlidingDisc.ActorLocation);
		float FutureDistance = ClosestDistance + AccSpeed.Value * DeltaTime;
		bool bCappedOut = FutureDistance > Spliney.Length;
		bool bHopOffByDistance = SlidingDisc.GrindHopOffDistance > 0.0 && FutureDistance > SlidingDisc.GrindHopOffDistance;


		if (bCappedOut || bHopOffByDistance)
			bShouldExit = true;

		FutureDistance = Math::Clamp(FutureDistance, 0.0, Spliney.Length);
		FVector ClosestLocation;
		FRotator ClosestRotation;
		Spliney.GetLocationAndRotationAtDistance(ClosestDistance, ClosestLocation, ClosestRotation);
		FVector ToClosestLocation = ClosestLocation - SlidingDisc.ActorLocation;

		FVector FutureLocation;
		FRotator FutureRotation;
		Spliney.GetLocationAndRotationAtDistance(FutureDistance, FutureLocation, FutureRotation);

		FVector ToFutureLocation = FutureLocation - SlidingDisc.ActorLocation;
		Direction = Math::VInterpNormalRotationTo(Direction, ToFutureLocation.GetSafeNormal(), DeltaTime, 90.0);

		float DurationAlpha = Math::Clamp(ActiveDuration / 2.0, 0.0, 1.0);
		
		// float QuickerDurationOverTime = Math::Lerp(2.0, 0.1, DurationAlpha);
		// AccLocation.AccelerateTo(ClosestLocation, QuickerDurationOverTime, DeltaTime);

		ToFutureLocation = Math::Lerp(FVector::ZeroVector, ToFutureLocation, DurationAlpha);
		
		// Movement.AddDelta(FVector());
		Movement.AddDelta(ToFutureLocation);
		// Movement.AddDelta(Direction * AccSpeed.Value * DeltaTime);
		// Movement.AddVelocity(ToClosestLocation);

		SlidingDisc.AccPivotRot.AccelerateTo(FutureRotation.Quaternion(), 1.0, DeltaTime);
		SlidingDisc.BasePivot.SetWorldRotation(SlidingDisc.AccPivotRot.Value);
		SlidingDisc.AccRollRot.AccelerateTo(0.0, 1.0, DeltaTime);
		FRotator RollRot;
		RollRot.Roll = SlidingDisc.AccRollRot.Value;
		SlidingDisc.Pivot.SetRelativeRotation(RollRot);

#if EDITOR
		TEMPORAL_LOG(SlidingDisc, "Sliding").Value("Speed", MovementComponent.Velocity.Size());
		TEMPORAL_LOG(SlidingDisc, "Sliding").Value("Grind Distance", ClosestDistance);

		TEMPORAL_LOG(SlidingDisc, "Sliding").Value("To New Loc Diff", ToFutureLocation.Size());
		TEMPORAL_LOG(SlidingDisc).Sphere("NewLoc", FutureLocation, 100.0, ColorDebug::Lavender);

		TEMPORAL_LOG(SlidingDisc).Line("To Target Location", Owner.ActorLocation, FutureLocation, 2.0, ColorDebug::Lavender);
		TEMPORAL_LOG(SlidingDisc).Line("To Closest Location", Owner.ActorLocation, ClosestLocation, 2.0, ColorDebug::Amethyst);
		TEMPORAL_LOG(SlidingDisc).Arrow("Velocity", Owner.ActorLocation, Owner.ActorLocation + MovementComponent.Velocity, 3.0, 20.0, ColorDebug::Magenta);

		TEMPORAL_LOG(SlidingDisc).Arrow("TargetRotation Z", Owner.ActorLocation, Owner.ActorLocation + FutureRotation.UpVector * 300.0, 3.0, 20.0, ColorDebug::Blue);
		TEMPORAL_LOG(SlidingDisc).Arrow("TargetRotation X", Owner.ActorLocation, Owner.ActorLocation + FutureRotation.ForwardVector * 300.0, 3.0, 20.0, ColorDebug::Red);
		TEMPORAL_LOG(SlidingDisc).Arrow("TargetRotation Y", Owner.ActorLocation, Owner.ActorLocation + FutureRotation.RightVector * 300.0, 3.0, 20.0, ColorDebug::Green);
		// TEMPORAL_LOG(SlidingDisc).Sphere("Acc Location", AccLocation.Value, 100.0, ColorDebug::White);
		TEMPORAL_LOG(SlidingDisc).RuntimeSpline("Hydra Spline", Spliney);
#endif

		if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
		{
			Debug::DrawDebugString(Owner.ActorLocation, "Closest Distance " + ClosestDistance);
			Debug::DrawDebugString(Owner.ActorLocation, "\n\nSpeed " + AccSpeed.Value);
		}
		if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
		{
			Debug::DrawDebugLine(Owner.ActorLocation, FutureLocation, ColorDebug::Lavender);
			Debug::DrawDebugCoordinateSystem(Owner.ActorLocation, FutureRotation, 300.0);
			// Debug::DrawDebugLine(Owner.ActorLocation, AccLocation.Value, ColorDebug::Ruby);
		}
	}

	FVector GetHydraGrindCameraLocation()
	{
		return SlidingDisc.ActorLocation - SlidingDisc.BasePivot.WorldRotation.ForwardVector * 3000.0 + SlidingDisc.BasePivot.WorldRotation.UpVector * 500.0;
	}

	FRotator GetHydraGrindCameraRotation()
	{
		return SlidingDisc.BasePivot.WorldRotation;
	}
}