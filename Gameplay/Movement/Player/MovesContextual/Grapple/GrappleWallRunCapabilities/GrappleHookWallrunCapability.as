
class UPlayerGrappleHookWallrunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleWallRun);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	const float GRAPPLE_REEL_DURATION = 0.09;
	const float GRAPPLE_REEL_DELAY = 0.18;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UPlayerWallRunComponent WallrunComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UGrappleWallrunPointComponent GrappleWallRunPoint;

	FVector TargetLocation;
	FVector StartLocation;
	FVector RelativeStartLocation;

	FVector ExitDirection;
	float EnterSpeed = 2800.0;
	float Speed;
	bool bReachedTarget = false;

	FHazeRuntimeSpline Spline;
	float DistAlongSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		WallrunComp = UPlayerWallRunComponent::GetOrCreate(Player);

		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGrappleHookWallRunActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bEnterFinished || GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::WallrunPoint)
			return false;
		
		//May not be necessary but store the point we activate on for potential networking alignment
		ActivationParams.Data = GrappleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerGrappleHookWallRunDeactivationParams& DeactivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (Math::IsNearlyEqual(DistAlongSpline, Spline.Length, 300.0))
		{
			FVector PlayerToPoint = GrappleWallRunPoint.WorldLocation - Player.ActorLocation;
			PlayerToPoint = PlayerToPoint.ConstrainToPlane(MoveComp.WorldUp);
			PlayerToPoint.Normalize();
			FPlayerWallRunData WallRunData = WallrunComp.TraceForWallRun(Player, PlayerToPoint, FInstigator(this, n"ShouldDeactivate"));
			if (WallRunData.HasValidData())
			{
				DeactivationParams.WallRunData = WallRunData;
				return true;
			}
		}

		if (DistAlongSpline >= Spline.Length)
		{
			DeactivationParams = FPlayerGrappleHookWallRunDeactivationParams();
			return true;
		}

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerGrappleHookWallRunActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		Player.BlockCapabilities(CameraTags::CameraControl, this);
		GrappleComp.Data = ActivationParams.Data;
		GrappleWallRunPoint = Cast<UGrappleWallrunPointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleWallrun;

		//Convert our Start location to a point relative location
		RelativeStartLocation = GrappleWallRunPoint.WorldTransform.InverseTransformPosition(Player.ActorLocation);

		DistAlongSpline = 0.0;
		Speed = EnterSpeed;

		UpdateTargetLocation();
		UpdateRuntimeSpline();

		FVector PlayerToPointDir = (TargetLocation - Player.ActorLocation).GetSafeNormal();		
		bool bForwardWanted;

		//If both directions are allowed or as a failsafe if no direction is allowed for whatever reason, then calculate our direction
		if((GrappleWallRunPoint.bAllowForward && GrappleWallRunPoint.bAllowBackwards) || (!GrappleWallRunPoint.bAllowForward && !GrappleWallRunPoint.bAllowBackwards))
			bForwardWanted = GrappleWallRunPoint.GetWallRunForwardAdjustedByWorldUp(MoveComp.WorldUp).DotProduct(PlayerToPointDir) >= 0.0;
		else
		{
			if(GrappleWallRunPoint.bAllowForward && !GrappleWallRunPoint.bAllowBackwards)
				bForwardWanted = true;
			else if (GrappleWallRunPoint.bAllowBackwards && !GrappleWallRunPoint.bAllowForward)
				bForwardWanted = false;
			else
			{
				//Should never end up here but if we do, calculate our direction like normal
				bForwardWanted = GrappleWallRunPoint.GetWallRunForwardAdjustedByWorldUp(MoveComp.WorldUp).DotProduct(PlayerToPointDir) >= 0.0;
			}
		}
	
		if (bForwardWanted)
		{
			ExitDirection = GrappleWallRunPoint.GetForwardWithEntryAngle();			
			GrappleComp.AnimData.EnterSide = ELeftRight::Right;
		}
		else
		{
			ExitDirection = GrappleWallRunPoint.GetBackwardsWithEntryAngle();
			GrappleComp.AnimData.EnterSide = ELeftRight::Left;
		}

		//Activate Camera / view effects
		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			Player.PlayCameraShake(GrappleComp.GrappleShake, this, 2.0);
			GrappleComp.CalculateHeightOffset();

			Player.ApplyCameraSettings(GrappleComp.GrappleCamSetting, 1.35, this, SubPriority = 54);

			FVector ConstrainedTargetLocation = TargetLocation * FVector(1.0, 1.0, 0.0);
			FVector ConstrainedStartLocation = StartLocation * FVector(1.0, 1.0, 0.0);
			FVector Dir = ConstrainedTargetLocation - ConstrainedStartLocation;
			Dir = Dir.GetSafeNormal();
			Dir *= 900.0;

			auto Poi = Player.CreatePointOfInterest();
			Poi.FocusTarget.SetFocusToComponent(GrappleWallRunPoint);
			FVector WorldOffset;
			if (bForwardWanted)
				WorldOffset = GrappleWallRunPoint.GetForwardWithEntryAngle() * 1000.0;
			else
				WorldOffset = GrappleWallRunPoint.GetBackwardsWithEntryAngle() * 1000.0;

			Poi.FocusTarget.LocalOffset = GrappleWallRunPoint.PointOfInterestOffset;
			Poi.FocusTarget.WorldOffset = ((FVector::UpVector * -600.0) + Dir) + WorldOffset;
			Poi.Settings.Duration = 0.65;
			Poi.Settings.RegainInputTime = 0.2;
			Poi.Apply(this, 0.95);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerGrappleHookWallRunDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		Player.UnblockCapabilities(CameraTags::CameraControl, this);

		if (DeactivationParams.WallRunData.HasValidData())
		{
			WallrunComp.bHasWallRunnedSinceLastGrounded = false;
			FPlayerWallRunData WallRunData = DeactivationParams.WallRunData;
			WallRunData.InitialVelocity = ExitDirection * Math::Clamp(MoveComp.Velocity.DotProduct(ExitDirection), WallrunComp.Settings.MinimumSpeed,  GrappleWallRunPoint.EntrySpeed);
			WallrunComp.StartWallRun(WallRunData);
		}

		//Make sure we are in the same state as when started (nothing interrupted) and cleanup / reset
		if (GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleWallrun)
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);

			//Broadcast grapple finished event
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			//Clear Component data
			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();
		}
		else
		{
			// Our state was interrupted
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			GrappleComp.AnimData.bWallrunGrappling = false;
		}

		GrappleWallRunPoint.ClearPointForPlayer(Player);
		GrappleWallRunPoint = nullptr;

		Player.ClearCameraSettingsByInstigator(this, 2.5);
		Player.ClearPointOfInterestByInstigator(this);
		Player.PlayCameraShake(GrappleComp.GrappleShake, this, 2.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				UpdateTargetLocation();
				UpdateRuntimeSpline();

				if(Speed - (1000 * DeltaTime) < WallrunComp.Settings.MinimumSpeed)
					Speed = WallrunComp.Settings.MinimumSpeed;
				else
					Speed -= 1000 * DeltaTime;

				DistAlongSpline = Math::Min(DistAlongSpline + Speed * DeltaTime, Spline.Length);

				FVector WantedLoc = Spline.GetLocationAtDistance(DistAlongSpline);
				FHazeTraceSettings TraceSettings = Trace::InitFromPrimitiveComponent(Player.CapsuleComponent);
				TraceSettings.UseLine();
				FHitResult Hit = TraceSettings.QueryTraceSingle(WantedLoc + FVector::UpVector * 150.0, WantedLoc);
				if (Hit.bBlockingHit)
				{
					WantedLoc = Hit.Location;
				}

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(WantedLoc, Spline.GetDirectionAtDistance(DistAlongSpline) * Speed);
				Movement.SetRotation(Spline.GetDirectionAtDistance(DistAlongSpline).ToOrientationQuat());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"Grapple", this);
		}

		float Alpha = ActiveDuration / GrappleComp.Settings.GrappleDuration;
		float BlendFraction = Math::Lerp(1.0, 0.0, Alpha);
		BlendFraction = Math::Clamp(BlendFraction, 0, 1);

		GrappleComp.RetractGrapple(ActiveDuration);

		Player.ApplyManualFractionToCameraSettings(BlendFraction, this);
	}

	void UpdateTargetLocation()
	{
		FVector GrapplePointWallOffset = -GrappleWallRunPoint.ForwardVector;
		const float WorldUpAngularDistance = MoveComp.WorldUp.AngularDistance(FVector::UpVector);
		if (!Math::IsNearlyZero(WorldUpAngularDistance))
		{
			const FVector Axis = FVector::UpVector.CrossProduct(MoveComp.WorldUp);
			GrapplePointWallOffset = FQuat(Axis, WorldUpAngularDistance) * GrapplePointWallOffset;
		}

		TargetLocation = GrappleWallRunPoint.WorldLocation - MoveComp.WorldUp * 82.0 + GrapplePointWallOffset * WallrunComp.WallSettings.TargetDistanceToWall;
	}

	void UpdateRuntimeSpline()
	{
		//Update our splines start location to accommodate for moving targets
		StartLocation = GrappleComp.Data.CurrentGrapplePoint.WorldTransform.TransformPosition(RelativeStartLocation);
		FVector PlayerToPoint = TargetLocation - StartLocation;

		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(StartLocation);
		Spline.AddPoint(TargetLocation);
		Spline.SetCustomExitTangentPoint(TargetLocation + ExitDirection * PlayerToPoint.Size() * 2.0);
		Spline.SetCustomEnterTangentPoint(StartLocation + PlayerToPoint);
		Spline.SetCustomCurvature(0.25);
		Spline.Tension = 0.0;
	}
}


struct FPlayerGrappleHookWallRunActivationParams
{
	FPlayerGrappleData Data;
}

struct FPlayerGrappleHookWallRunDeactivationParams
{
	FPlayerWallRunData WallRunData;
}