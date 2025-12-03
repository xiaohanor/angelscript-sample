class UPlayerGrappleToSlideGroundedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleSlide);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8; 

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerSlideComponent SlideComp;
	USweepingMovementData Movement;

	FVector TargetLocation;
	FVector StartLocation;
	FVector RelativeStartLocation;
	FVector TargetDirection;

	FHazeRuntimeSpline Spline;
	FVector PointLocationLastFrame;
	float DistAlongSpline;
	float InitialHorizontalSpeed = 0;

	UGrappleSlidePointComponent TargetSlidePoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();
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

		if (GrappleComp.Data.SlideGrappleVariant == ESlideGrappleVariants::InAir)
			return false;

		UGrappleSlidePointComponent TargetPoint = Cast<UGrappleSlidePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		if(TargetPoint == nullptr)
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
		GrappleComp.Data = Params.Data;
		TargetSlidePoint = Cast<UGrappleSlidePointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleSlide;

		PointLocationLastFrame = TargetSlidePoint.WorldLocation;
		DistAlongSpline = 0;

		TargetLocation = TargetSlidePoint.WorldLocation;
		StartLocation = Player.ActorLocation;

		RelativeStartLocation = TargetSlidePoint.WorldTransform.InverseTransformPosition(Player.ActorLocation);
		TargetDirection = (TargetLocation - StartLocation).GetSafeNormal();

		//This needs to be aligned with our target direction to handle if we grapple behind ourselves while running towards screen
		InitialHorizontalSpeed = MoveComp.HorizontalVelocity.Size();

		if (TargetSlidePoint.bUsePreferedDirection)
		{
			//If we have a stored Direction vector then use that
			FVector AssistedDirection = GrappleComp.Data.StoredSlideDirection == FVector::ZeroVector ? 
											TargetSlidePoint.Owner.ActorTransform.TransformVector(TargetSlidePoint.PreferedDirection.GetSafeNormal()) :
												GrappleComp.Data.StoredSlideDirection;

			float Dot = AssistedDirection.DotProduct(TargetDirection);
			float Deg = Math::Acos(Dot);
			Deg = Math::RadiansToDegrees(Deg);

			//If we are inside the Acceptance Range, then align our TargetDirection with the prefered direction
			if (Deg < TargetSlidePoint.AcceptanceDegrees)
				TargetDirection = AssistedDirection.GetSafeNormal();
		}

		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(StartLocation);
		Spline.AddPoint(TargetLocation);
		Spline.SetCustomExitTangentPoint(TargetLocation + TargetDirection);
		Spline.SetCustomCurvature(1.0);

		GrappleComp.AnimData.SlideSplineLength = Spline.Length;

		Player.CapsuleComponent.OverrideCapsuleHalfHeight(SlideComp.Settings.CapsuleHalfHeight, this);
		HandleCameraOnActivation();
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerGrappleSlideDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);

		if(Params.bMoveFinished)
		{
			//Broadcast finished grappling event
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			//Reset Component Data
			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();

			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);

			FSlideParameters SlideParams;
			if(TargetSlidePoint.bForceSlideInPreferredDirection)
			{
				SlideParams.SlideType = ESlideType::StaticDirection;
				SlideParams.SlideWorldDirection = TargetSlidePoint.WorldTransform.TransformVector(TargetSlidePoint.PreferedDirection).GetSafeNormal();
			}
			else
			{
				SlideParams.SlideType = ESlideType::Freeform;

			}
			SlideComp.StartTemporarySlide(this, SlideParams);
		}
		else
		{
			//Broadcast interrupted grappling event
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			if(GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleSlide)
			{
				//Reset Component Data
				GrappleComp.Data.ResetData();
				GrappleComp.AnimData.ResetData();

				GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
				GrappleComp.Grapple.SetActorHiddenInGame(true);
			}
		}
		
		Player.ClearCameraSettingsByInstigator(this, 0);
		Player.ClearPointOfInterestByInstigator(this);

		TargetSlidePoint.ClearPointForPlayer(Player);
		TargetSlidePoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetLocation = TargetSlidePoint.WorldLocation;
		StartLocation += TargetSlidePoint.WorldLocation - PointLocationLastFrame;

		TargetDirection = (TargetLocation - StartLocation).GetSafeNormal();
		if (TargetSlidePoint.bUsePreferedDirection)
		{
			FVector AssistedDirection = GrappleComp.Data.StoredSlideDirection == FVector::ZeroVector ? TargetSlidePoint.Owner.ActorTransform.TransformVector(TargetSlidePoint.PreferedDirection.GetSafeNormal()) : GrappleComp.Data.StoredSlideDirection;
			float Dot = AssistedDirection.DotProduct(TargetDirection);
			float Deg = Math::Acos(Dot);
			Deg = Math::RadiansToDegrees(Deg);
			if(Deg < TargetSlidePoint.AcceptanceDegrees)
			{
				TargetDirection = AssistedDirection;
			}
		}

		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(StartLocation);
		Spline.AddPoint(TargetLocation);
		Spline.SetCustomExitTangentPoint(TargetLocation + TargetDirection.GetSafeNormal());
		Spline.SetCustomCurvature(1.0);

		if(IsDebugActive())
			Spline.DrawDebugSpline();

		PointLocationLastFrame = TargetSlidePoint.WorldLocation;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{		
				float Speed = Math::Lerp(InitialHorizontalSpeed, TargetSlidePoint.LaunchVelocity, GrappleComp.AccelerationCurve.GetFloatValue(ActiveDuration / GrappleComp.Settings.GrappleToSlideAccelerationDuration));

				DistAlongSpline += Speed * DeltaTime;
				DistAlongSpline = Math::Clamp(DistAlongSpline, 0.0, Spline.Length);

				FVector NewLocation = Spline.GetLocationAtDistance(DistAlongSpline);
				FVector NewVelocity = Spline.GetDirectionAtDistance(DistAlongSpline) * Speed;

				FVector DeltaMove = NewLocation - Player.ActorLocation;
				Movement.AddDeltaWithCustomVelocity(DeltaMove, NewVelocity);
				Movement.SetRotation(Spline.GetDirectionAtDistance(DistAlongSpline).Rotation());

				//Assign anim data
				GrappleComp.AnimData.SlideSplineRemainingDistance = Spline.Length- DistAlongSpline;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"Slide", this);
		}

		HandleGrappleHookActor();
	}

	float TimePerSplineDistanceUnit = 0.05;
	float MoveDuration = 0;

	float GetMoveAlpha() const
	{
		if(DistAlongSpline == 0)
			return 0;

		return DistAlongSpline / Spline.Length;
	}

	void HandleGrappleHookActor()
	{
		FVector NewLoc = Math::Lerp(GrappleComp.Data.CurrentGrapplePoint.WorldLocation, Player.Mesh.GetSocketLocation(n"LeftAttach"), GetMoveAlpha());
		GrappleComp.Grapple.SetActorLocation(NewLoc);
		float NewTense = Math::Lerp(0.15, 2.15, GetMoveAlpha());
		GrappleComp.Grapple.Tense = NewTense;
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
};