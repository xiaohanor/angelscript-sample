
class UBattlefieldHoverboardGrappleHookCapability : UHazePlayerCapability
{
	/*
		- This Capability translates the player to the grapple point, performed when grappling to generic grapplepoint components
	*/

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 6;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UBattlefieldHoverboardGrappleComponent GrappleComp;
	UPlayerGrappleComponent PlayerGrappleComp;
	UBattlefieldHoverboardComponent HoverboardComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UGrapplePointComponent TargetedPoint;
	UCameraPointOfInterest PoI;

	UBattlefieldHoverboardGrappleSettings GrappleSettings;

	float GrappleTime = 1.05;
	FVector TargetLocation;
	FVector StartLocation;
	FVector TargetRelativeStartPoint;
	bool bAppliedCameraBump = false;

	FHazeRuntimeSpline Spline;
	float DistAlongSpline;
	float Speed;
	FVector EndPointLocLastframe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UBattlefieldHoverboardGrappleComponent::GetOrCreate(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		PoI = Player.CreatePointOfInterest();

		PlayerGrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		GrappleSettings = UBattlefieldHoverboardGrappleSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleToPoint)
			return false;

		if(GrappleComp.Data.CurrentGrapplePoint.Owner.IsA(ABattlefieldHoverboardGrappleToGrindPoint))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (DistAlongSpline >= Spline.Length)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		GrappleComp.CalculateHeightOffset();

		TargetedPoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		//Reset variables before going into the move
		DistAlongSpline = 0.0;
		Speed = MoveComp.Velocity.Size() + GrappleSettings.GrappleAdditionalSpeed;
		Speed = Math::Clamp(Speed, GrappleSettings.GrappleMinimumSpeed, GrappleSettings.GrappleMaximumSpeed);
		EndPointLocLastframe = GrappleComp.Data.CurrentGrapplePoint.WorldLocation;
		TargetLocation = GrappleComp.Data.CurrentGrapplePoint.WorldLocation;
		StartLocation = Player.ActorLocation;
		TargetRelativeStartPoint = GrappleComp.Data.CurrentGrapplePoint.WorldTransform.InverseTransformPosition(StartLocation);

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
			HandleCameraOnActivation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);

		//If we exited due to finishing the move, we want to hide the grapple actor and set the players velocity to sprint speed. Otherwise do nothing as we are in a new grapple enter at this point
		if (GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleToPoint)
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);

			// Feels nicer to not snap velocity on deactivation, grounded decceleration will slow us down fast enough anyway.
			// If this causes issues we should deccelerate in air to land at run speed rather then snap AND/OR make it a factor of forward input (AL).
			// Player.SetActorVelocity(Player.ActorForwardVector * 750.0);

			//Broadcast finished event from point and clean up
			if(TargetedPoint != nullptr)
				TargetedPoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			UGrapplePointComponent GrapplePoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);

			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();
			PlayerGrappleComp.Data.ResetData();
		}
		else
			GrappleComp.AnimData.bGrappling = false;

		//Clear point for targeting by player again
		if (IsValid(TargetedPoint))
			TargetedPoint.ClearPointForPlayer(Player);

		Player.ClearCameraSettingsByInstigator(this, 2.5);
		Player.ClearPointOfInterestByInstigator(this);

		TargetedPoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//This is a downwards camera impulse to give a feeling of landing when exiting the move. Adding it OnDeactivated felt like it came too late, so instead it's done once after 92.5% of the move
		if(Spline.Points.Num() > 0 && DistAlongSpline >= Spline.Length * 0.925 && !bAppliedCameraBump)
		{
			FHazeCameraImpulse CamImpulse;
			CamImpulse.AngularImpulse = FRotator(-25.0, 0.0, 0.0);
			CamImpulse.WorldSpaceImpulse = FVector(0.0, 0.0, -225.0);
			CamImpulse.ExpirationForce = 17.5;
			CamImpulse.Dampening = 0.8;
			Player.ApplyCameraImpulse(CamImpulse, this);
			bAppliedCameraBump = true;
		}

		FVector RelativeStartLocation = GrappleComp.Data.CurrentGrapplePoint.WorldTransform.TransformPosition(TargetRelativeStartPoint);

		//New cool spline stuff
		FVector MiddlePointLoc = GrappleComp.Data.CurrentGrapplePoint.WorldLocation - RelativeStartLocation;
		
		// float DistToTarget = MiddlePointLoc.Size();
		// float EnterSpeedModifier = Math::GetMappedRangeValueClamped(FVector2D(750.0, 2000.0), FVector2D(0.5, 1.0), DistToTarget);
		
		float Dist = MiddlePointLoc.Size() * 0.4;
		MiddlePointLoc = MiddlePointLoc.GetSafeNormal() * Dist;
		MiddlePointLoc += RelativeStartLocation;
		MiddlePointLoc += Player.MovementWorldUp * GrappleComp.GrappleHeightOffset;
		FVector EndPointTangent = GrappleComp.Data.CurrentGrapplePoint.WorldLocation.ConstrainToPlane(FVector::UpVector) - Player.ActorLocation.ConstrainToPlane(FVector::UpVector);
		RelativeStartLocation += GrappleComp.Data.CurrentGrapplePoint.WorldLocation - EndPointLocLastframe;

		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(RelativeStartLocation);
		Spline.AddPoint(MiddlePointLoc);
		Spline.AddPoint(GrappleComp.Data.CurrentGrapplePoint.WorldLocation);

		Spline.SetCustomExitTangentPoint(GrappleComp.Data.CurrentGrapplePoint.WorldLocation + EndPointTangent.GetSafeNormal() * 500.0);
		Spline.SetCustomCurvature(0.15);
		Spline.Tension = 0.0;

		EndPointLocLastframe = GrappleComp.Data.CurrentGrapplePoint.WorldLocation;

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				DistAlongSpline += Speed * DeltaTime;
				DistAlongSpline = Math::Clamp(DistAlongSpline, 0.0, Spline.Length);

				FVector NewLoc = Spline.GetLocationAtDistance(DistAlongSpline);

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Spline.GetDirectionAtDistance(DistAlongSpline) * Speed);

				FRotator NewRotation = Spline.GetDirectionAtDistance(DistAlongSpline).Rotation();
				NewRotation.Pitch = 0;
				NewRotation.Roll = 0;
				Movement.SetRotation(NewRotation);
				Movement.OverrideStepDownAmountForThisFrame(0.0);

				HoverboardComp.WantedRotation = NewRotation;

				// if(Speed - (500 * DeltaTime) < 750.0)
				// 	Speed = 750.0;
				// else
				// 	Speed -= 500 * DeltaTime;
			}			
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"HoverboardGrappling", this);
		}

		float Alpha = ActiveDuration / GrappleTime;
		float BlendFraction = Math::Lerp(1.0, 0.0, Alpha);

		//CableComp handling
		FVector NewLoc = Math::Lerp(GrappleComp.Data.CurrentGrapplePoint.WorldLocation, Player.Mesh.GetSocketLocation(n"LeftAttach"), Alpha);
		GrappleComp.Grapple.SetActorLocation(NewLoc);
		float NewTense = Math::Lerp(0.15, 2.15, Alpha);
		GrappleComp.Grapple.Tense = NewTense;

		//float Blend = float::ManualFraction(BlendFraction, 1.35);	
		Player.ApplyManualFractionToCameraSettings(BlendFraction, this);
	}

	void HandleCameraOnActivation()
	{
		bAppliedCameraBump = false;

		Player.PlayCameraShake(GrappleSettings.GrappleShake, this, 2.0);
		Player.ApplyCameraSettings(GrappleSettings.GrappleCamSetting, 1.35, this, SubPriority = 50);
		Player.ApplyCameraSettings(GrappleSettings.GrappleLagCamSetting, 0, this, SubPriority = 50);

		
		PoI.FocusTarget.SetFocusToComponent(GrappleComp.Data.CurrentGrapplePoint);

		if(GrappleComp.Data.CurrentGrapplePoint.PointOfInterestOffset == FVector::ZeroVector)
		{
			FVector PlayerToPoint = GrappleComp.Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation;
			PlayerToPoint = PlayerToPoint.ConstrainToPlane(MoveComp.WorldUp);
			PlayerToPoint = PlayerToPoint.GetSafeNormal();

			PoI.FocusTarget.WorldOffset = (PlayerToPoint * 2000) + FVector(0, 0, 50);
		}
		else
			PoI.FocusTarget.LocalOffset = GrappleComp.Data.CurrentGrapplePoint.PointOfInterestOffset;

		PoI.Settings.ClearOnInput = CameraPOIDefaultClearOnInput;
		PoI.Settings.RegainInputTime = 0.2;

		PoI.Settings.Duration = GrappleTime - 0.65;
		PoI.Apply(this, 0.65);
	}
};

