struct FBattlefieldHoverboardGrappleHookWallrunActivationParams
{
	UGrapplePointBaseComponent TargetGrapplePoint;
}

class UBattlefieldHoverboardGrappleHookWallrunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleWallRun);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 6;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerGrappleComponent PlayerGrappleComp;
	UBattlefieldHoverboardGrappleComponent GrappleComp;
	UBattlefieldHoverboardWallRunComponent WallRunComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UBattlefieldHoverboardComponent HoverboardComp;

	UGrappleWallrunPointComponent GrappleWallRunPoint;

	UBattlefieldHoverboardGrappleSettings GrappleSettings;

	FVector TargetLocation;
	FVector StartLocation;
	FVector RelativeStartLocation;

	TOptional<FRotator> CameraWallRunStartRotation;

	FVector ExitDirection;
	float EnterSpeed = 2500.0;
	float Speed;
	bool bReachedTarget = false;

	FHazeRuntimeSpline Spline;
	float DistAlongSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		
		PlayerGrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		GrappleComp = UBattlefieldHoverboardGrappleComponent::GetOrCreate(Player);
		WallRunComp = UBattlefieldHoverboardWallRunComponent::GetOrCreate(Player);

		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);

		GrappleSettings = UBattlefieldHoverboardGrappleSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBattlefieldHoverboardGrappleHookWallrunActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleWallrun)
			return false;
		
		//May not be necessary but store the point we activate on for potential networking alignment
		ActivationParams.TargetGrapplePoint = GrappleComp.Data.CurrentGrapplePoint;
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
			FPlayerWallRunData WallRunData = WallRunComp.TraceForWallRun(Player, PlayerToPoint);
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

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBattlefieldHoverboardGrappleHookWallrunActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);

		GrappleWallRunPoint = Cast<UGrappleWallrunPointComponent>(ActivationParams.TargetGrapplePoint);

		//Convert our Start location to a point relative location
		RelativeStartLocation = GrappleWallRunPoint.WorldTransform.InverseTransformPosition(Player.ActorLocation);

		DistAlongSpline = 0.0;
		
		Speed = MoveComp.Velocity.Size() + GrappleSettings.GrappleAdditionalSpeed;
		Speed = Math::Clamp(Speed, GrappleSettings.GrappleMinimumSpeed, GrappleSettings.GrappleMaximumSpeed);

		UpdateTargetLocation();
		UpdateRuntimeSpline();

		FVector PlayerToPointDir = (TargetLocation - Player.ActorLocation).GetSafeNormal();	
		//Debug::DrawDebugDirectionArrow(GrappleWallRunPoint.WorldLocation, GrappleWallRunPoint.GetWallRunForwardAdjustedByWorldUp(MoveComp.WorldUp), 500, 80, FLinearColor::Red, 10, 5);	
		//Debug::DrawDebugDirectionArrow(GrappleWallRunPoint.WorldLocation, PlayerToPointDir, 500, 80, FLinearColor::Blue, 10, 5);	

		//If both directions are allowed or as a failsafe if no direction is allowed for whatever reason, then calculate our direction
		if((GrappleWallRunPoint.bAllowForward && GrappleWallRunPoint.bAllowBackwards) || (!GrappleWallRunPoint.bAllowForward && !GrappleWallRunPoint.bAllowBackwards))
			ExitDirection = GrappleWallRunPoint.GetWallRunForwardAdjustedByWorldUp(MoveComp.WorldUp).DotProduct(PlayerToPointDir) >= 0.0 ? GrappleWallRunPoint.GetForwardWithEntryAngle() : GrappleWallRunPoint.GetBackwardsWithEntryAngle();
		else
		{
			if(GrappleWallRunPoint.bAllowForward && !GrappleWallRunPoint.bAllowBackwards)
			{
				ExitDirection = GrappleWallRunPoint.GetForwardWithEntryAngle();
			}	
			else if (GrappleWallRunPoint.bAllowBackwards && !GrappleWallRunPoint.bAllowForward)
			{
				ExitDirection = GrappleWallRunPoint.GetBackwardsWithEntryAngle();
			}	
			else
			{
				//Should never end up here but if we do, calculate our direction like normal
				ExitDirection = GrappleWallRunPoint.GetWallRunForwardAdjustedByWorldUp(MoveComp.WorldUp).DotProduct(PlayerToPointDir) >= 0.0 ? GrappleWallRunPoint.GetForwardWithEntryAngle() : GrappleWallRunPoint.GetBackwardsWithEntryAngle();
			}
		}

		//Activate Camera / view effects
		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			Player.PlayCameraShake(GrappleSettings.GrappleShake, this, 2.0);
			GrappleComp.CalculateHeightOffset();

			Player.ApplyCameraSettings(GrappleSettings.GrappleCamSetting, 1.35, this, SubPriority = 54);

			// FVector ConstrainedTargetLocation = TargetLocation * FVector(1.0, 1.0, 0.0);
			// FVector ConstrainedStartLocation = StartLocation * FVector(1.0, 1.0, 0.0);
			// FVector Dir = ConstrainedTargetLocation - ConstrainedStartLocation;
			// Dir = Dir.GetSafeNormal();
			// Dir *= 900.0;

			// auto Poi = Player.CreatePointOfInterest();
			// Poi.FocusTarget.SetFocusToComponent(GrappleWallRunPoint);
			// FVector WorldOffset;
			// if (bForwardWanted)
			// 	WorldOffset = GrappleWallRunPoint.GetForwardWithEntryAngle() * 1000.0;
			// else
			// 	WorldOffset = GrappleWallRunPoint.GetBackwardsWithEntryAngle() * 1000.0;

			// Poi.FocusTarget.LocalOffset = GrappleWallRunPoint.PointOfInterestOffset;
			// Poi.FocusTarget.WorldOffset = ((FVector::UpVector * -600.0) + Dir) + WorldOffset;
			// Poi.Settings.Duration = 0.65;
			// Poi.Settings.RegainInputTime = 0.2;
			// Poi.Apply(this, 0.95);
		}

		FVector PlayerToPoint = GrappleWallRunPoint.WorldLocation - Player.ActorLocation;
		PlayerToPoint = PlayerToPoint.ConstrainToPlane(MoveComp.WorldUp);
		PlayerToPoint.Normalize();
		auto WallRunStartRotation = WallRunComp.TraceForWallRotation(Player, GrappleWallRunPoint.WorldLocation, PlayerToPoint);
		if(WallRunStartRotation.IsSet())
		{
			CameraWallRunStartRotation.Set(FRotator::MakeFromYX(WallRunStartRotation.Value.ForwardVector, Player.ActorForwardVector));
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerGrappleHookWallRunDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);

		if (DeactivationParams.WallRunData.HasValidData())
		{
			FPlayerWallRunData WallRunData = DeactivationParams.WallRunData;
			WallRunData.InitialVelocity = ExitDirection * Math::Clamp(MoveComp.Velocity.DotProduct(ExitDirection), WallRunComp.Settings.MinimumSpeed,  WallRunComp.Settings.MaximumSpeed);
			WallRunComp.StartWallRun(WallRunData);
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
			PlayerGrappleComp.Data.ResetData();
		}
		else
			GrappleComp.AnimData.bWallrunGrappling = false;

		if (IsValid(GrappleWallRunPoint))
		{
			GrappleWallRunPoint.ClearPointForPlayer(Player);
			GrappleWallRunPoint = nullptr;
		}

		Player.ClearCameraSettingsByInstigator(this, 2.5);
		Player.ClearPointOfInterestByInstigator(this);
		Player.PlayCameraShake(GrappleSettings.GrappleShake, this, 2.0);
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

				// if(Speed - (1000 * DeltaTime) < WallrunComp.Settings.MinimumSpeed)
				// 	Speed = WallrunComp.Settings.MinimumSpeed;
				// else
				// 	Speed -= 1000 * DeltaTime;

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
			Player.Mesh.RequestLocomotion(n"HoverboardGrappling", this);
		}

		float Alpha = ActiveDuration / GrappleComp.Settings.GrappleDuration;
		float BlendFraction = Math::Lerp(1.0, 0.0, Alpha);

		FVector NewLoc = Math::Lerp(GrappleComp.Data.CurrentGrapplePoint.WorldLocation, Player.Mesh.GetSocketLocation(n"LeftAttach"), Alpha);
		GrappleComp.Grapple.SetActorLocation(NewLoc);
		float NewTense = Math::Lerp(0.15, 2.15, Alpha);
		GrappleComp.Grapple.Tense = NewTense;

		//float Blend = float::ManualFraction(BlendFraction, 1.35);

		if(CameraWallRunStartRotation.IsSet())
		{
			HoverboardComp.CameraWantedRotation = Math::RInterpTo(HoverboardComp.CameraWantedRotation, CameraWallRunStartRotation.Value, DeltaTime, 5);
		}
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

		TargetLocation = GrappleWallRunPoint.WorldLocation - MoveComp.WorldUp * 82.0 + GrapplePointWallOffset * WallRunComp.WallSettings.TargetDistanceToWall;
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