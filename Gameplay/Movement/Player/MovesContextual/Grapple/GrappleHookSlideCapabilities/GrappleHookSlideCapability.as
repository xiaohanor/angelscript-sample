
asset PlayerSlideGrappleCameraBlendOut of UCameraDefaultBlend
{
	bIncludeLocationVelocity = true;
}

class UPlayerGrappleHookSlideCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleSlide);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UPlayerSlideComponent SlideComp;
	UGrappleSlidePointComponent SlidePoint;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FVector TargetLocation;
	FVector StartLocation;
	FVector RelativeStartLocation;
	FVector TargetDirection;

	FHazeRuntimeSpline Spline;
	FVector PointLocationLastFrame;
	float DistAlongSpline;

	//How far before our targetlocation do we add a point to even out our curve
	const float LedgeClearanceOffset = 250;
	float AlignPointOffsetToUse = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGrappleSlideActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bEnterFinished || GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::SlidePoint)
			return false;

		if (GrappleComp.Data.SlideGrappleVariant != ESlideGrappleVariants::InAir)
			return false;
		
		Params.Data = GrappleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerGrappleSlideDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (Player.IsPlayerDead())
			return true;

		if (MoveComp.HasImpactedWall())
			return true;

		if (GetMoveAlpha() >= 1)
		{
			Params.bMoveFinished = true;
			return true;
		}

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerGrappleSlideActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		Player.CapsuleComponent.OverrideCapsuleHalfHeight(SlideComp.Settings.CapsuleHalfHeight, this);

		GrappleComp.Data = Params.Data;

		SlidePoint = Cast<UGrappleSlidePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		GrappleComp.CalculateHeightOffset();

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleSlide;

		PointLocationLastFrame = SlidePoint.WorldLocation;
		DistAlongSpline = 0;
		
		TargetLocation = SlidePoint.WorldLocation + MoveComp.WorldUp;
		StartLocation = Player.ActorLocation;

		RelativeStartLocation = SlidePoint.WorldTransform.InverseTransformPosition(Player.ActorLocation);
		TargetDirection = (TargetLocation - StartLocation).GetSafeNormal();

		float ClearanceHeightDelta = (SlidePoint.WorldLocation + (-SlidePoint.WorldRotation.ForwardVector * (SlidePoint.OverrideEdgeClearanceValue > 0 ? SlidePoint.OverrideEdgeClearanceValue : LedgeClearanceOffset) - SlidePoint.WorldLocation)).ConstrainToDirection(MoveComp.WorldUp).Size();

		//if we are above the point then no need to offset our entry (Or our point offset by any vertical difference to our LedgeClearance position)
		if(((SlidePoint.WorldLocation + MoveComp.WorldUp * ClearanceHeightDelta) - Player.ActorLocation).GetSafeNormal().DotProduct(MoveComp.WorldUp) <= 0)
		{
			AlignPointOffsetToUse = 0;
		}
		else
		{
			if(SlidePoint.OverrideEdgeClearanceValue > 0)
			{
				AlignPointOffsetToUse = SlidePoint.OverrideEdgeClearanceValue;
			}
			else
			{
				//If we are below the point then add an additional point a certain distance from the point incase there´s a ledge or similar we need to clear
				float HorizontalDelta = (TargetLocation - StartLocation).ConstrainToPlane(MoveComp.WorldUp).Size();

				if(HorizontalDelta > LedgeClearanceOffset)
					AlignPointOffsetToUse = LedgeClearanceOffset;
				else if(HorizontalDelta < LedgeClearanceOffset)
				{
					//If we are horizontally closer to the point than our default offset
					AlignPointOffsetToUse = HorizontalDelta / 3;
				}
			}
		}
		
		//Do we have a prefered Direction to launch the player in
		if (SlidePoint.bUsePreferedDirection)
		{
			//If we have a stored Direction vector then use that
			FVector AssistedDirection = GrappleComp.Data.StoredSlideDirection == FVector::ZeroVector ? SlidePoint.Owner.ActorTransform.TransformVector(SlidePoint.PreferedDirection.GetSafeNormal()) : GrappleComp.Data.StoredSlideDirection;
			float Dot = AssistedDirection.DotProduct(TargetDirection);
			float Deg = Math::Acos(Dot);
			Deg = Math::RadiansToDegrees(Deg);

			//If we are inside the Acceptance Range, then align our TargetDirection with the prefered direction
			if (Deg < SlidePoint.AcceptanceDegrees)
				TargetDirection = AssistedDirection;
		}

		//Construct our spline
		ConstructSpline();

		//Assign anim data
		GrappleComp.AnimData.SlideSplineLength = Spline.Length;

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			Player.ApplyCameraSettings(GrappleComp.GrappleCamSetting, 1.35, this, SubPriority = 52);
			Player.PlayCameraShake(GrappleComp.GrappleShake, this, 2.0);
			HandleCameraOnActivation();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerGrappleSlideDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		//Make sure we are in the same state as when started (nothing interrupted) and cleanup / reset)
		if (GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleSlide && Params.bMoveFinished)
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);

			FSlideParameters SlideParams;
			if (SlidePoint.bForceSlideInPreferredDirection)
			{
				SlideParams.SlideType = ESlideType::StaticDirection;
				SlideParams.SlideWorldDirection = SlidePoint.WorldTransform.TransformVector(SlidePoint.PreferedDirection).GetSafeNormal();
			}
			else
			{
				SlideParams.SlideType = ESlideType::Freeform;
			}

			SlideComp.StartTemporarySlide(this, SlideParams);

			//Broadcast finished grappling event
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			//Reset Component Data
			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();
		}
		else if(GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleSlide && !Params.bMoveFinished)
		{
			// The grapple was interrupted
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			//Move was interrupted by none grapple moves
			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);
		}

		Player.ClearCameraSettingsByInstigator(this, 1);
		Player.ClearPointOfInterestByInstigator(this);

		Player.ApplyBlendToCurrentView(0.5, PlayerSlideGrappleCameraBlendOut);

		SlidePoint.ClearPointForPlayer(Player);
		SlidePoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetLocation = SlidePoint.WorldLocation + MoveComp.WorldUp;
		StartLocation += SlidePoint.WorldLocation - PointLocationLastFrame;

		TargetDirection = (TargetLocation - StartLocation).GetSafeNormal();
		if (SlidePoint.bUsePreferedDirection)
		{
			FVector AssistedDirection = GrappleComp.Data.StoredSlideDirection == FVector::ZeroVector ? SlidePoint.Owner.ActorTransform.TransformVector(SlidePoint.PreferedDirection.GetSafeNormal()) : GrappleComp.Data.StoredSlideDirection;
			float Dot = AssistedDirection.DotProduct(TargetDirection);
			float Deg = Math::Acos(Dot);
			Deg = Math::RadiansToDegrees(Deg);
			if(Deg < SlidePoint.AcceptanceDegrees)
			{
				TargetDirection = AssistedDirection;
			}
		}

		ConstructSpline();

		PointLocationLastFrame = SlidePoint.WorldLocation;

#if EDITOR
		if(IsDebugActive())
			Spline.DrawDebugSpline();
#endif
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{	
				
				// float Speed = Math::Lerp(0, SlidePoint.LaunchVelocity, GrappleComp.AccelerationCurve.GetFloatValue(ActiveDuration / GrappleComp.Settings.GrappleToSlideAccelerationDuration));
				float Speed = Math::Lerp(Math::Max(SlidePoint.LaunchVelocity * 1.1, GrappleComp.Settings.GrappleLaunchEnterSpeed), SlidePoint.LaunchVelocity, GetMoveAlpha());

				DistAlongSpline += Speed * DeltaTime;
				DistAlongSpline = Math::Clamp(DistAlongSpline, 0.0, Spline.Length);

				FVector NewLocation = Spline.GetLocationAtDistance(DistAlongSpline);
				FVector NewVelocity = Spline.GetDirectionAtDistance(DistAlongSpline) * Speed;

				FVector DeltaMove = NewLocation - Player.ActorLocation;
				Movement.AddDeltaWithCustomVelocity(DeltaMove, NewVelocity);
				Movement.SetRotation(Spline.GetDirectionAtDistance(DistAlongSpline).Rotation());

				//Assign anim data
				GrappleComp.AnimData.SlideSplineRemainingDistance = Spline.Length - DistAlongSpline;

				if(DistAlongSpline == Spline.Length)
				{
					FHazeTraceSettings GroundTrace = Trace::InitFromMovementComponent(MoveComp);
					FHitResult GroundHit = GroundTrace.QueryTraceSingle(Player.ActorLocation + DeltaMove, Player.ActorLocation + DeltaMove + (-MoveComp.WorldUp * 50));

					if(GroundHit.bBlockingHit)
					{
						FVector Delta = GroundHit.ImpactPoint - Player.ActorLocation;
						Movement.AddDeltaWithCustomVelocity(Delta, FVector::ZeroVector);
					}
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"Grapple", this);
		}
		
		GrappleComp.RetractGrapple(ActiveDuration);
	}

	void HandleCameraOnActivation()
	{
		if(GrappleComp.Data.CurrentGrapplePoint.PointOfInterestOffset == FVector::ZeroVector)
			return;

		auto Poi = Player.CreatePointOfInterest();
		Poi.FocusTarget.SetFocusToComponent(GrappleComp.Data.CurrentGrapplePoint);
		Poi.FocusTarget.LocalOffset = GrappleComp.Data.CurrentGrapplePoint.PointOfInterestOffset;
		Poi.Settings.Duration = 0.5;
		Poi.Settings.RegainInputTime = 0.2;
		Poi.FocusTarget.WorldOffset = (FVector::UpVector * -500.0); // + Dir;
		Poi.Apply(this, 1.5);
	}
	
	float GetMoveAlpha() const
	{
		if(DistAlongSpline == 0)
			return 0;

		return DistAlongSpline / Spline.Length;
	}

	void ConstructSpline()
	{
		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(StartLocation);

		if (AlignPointOffsetToUse > 0)
		{
			Spline.AddPoint(TargetLocation + (-(SlidePoint.WorldRotation.ForwardVector * AlignPointOffsetToUse)));
		}

		Spline.AddPoint(TargetLocation);
		Spline.SetCustomExitTangentPoint(TargetLocation + SlidePoint.WorldRotation.ForwardVector);
		Spline.SetCustomCurvature(1);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
	}
};

struct FPlayerGrappleSlideActivationParams
{
	FPlayerGrappleData Data;
}

struct FPlayerGrappleSlideDeactivationParams
{
	bool bMoveFinished = false;
}