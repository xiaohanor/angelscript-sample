struct FPlayerGrappleHookLaunchActivationParams
{
	FPlayerGrappleData Data;
}

class UPlayerGrappleHookLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleLaunch);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UGrappleLaunchPointComponent LaunchComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerAirMotionComponent AirMotionComp;

	FVector TargetLocation;
	FVector StartLocation;
	FVector StartRelativeLocation;
	FVector TargetDirection;
	FVector PointLocLastFrame;
	float Speed;
	float DistAlongSpline;
	bool bActivatedWithCameraEffects = false;

	FHazeRuntimeSpline Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGrappleHookLaunchActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bEnterFinished || GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::LaunchPoint)
			return false;
		
		Params.Data = GrappleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (GetMoveAlpha() >= 1.0)
			return true;

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerGrappleHookLaunchActivationParams Params)
	{
		//Block everything that should be blocked while grappling
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		GrappleComp.Data = Params.Data;

		//Get the grapple point we are using to launch ourselves
		LaunchComp = Cast<UGrappleLaunchPointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleLaunch;

		//Calculate height diff to launch point for animations
		GrappleComp.CalculateHeightOffset();

		if(LaunchComp.bConsumeAirActions)
		{
			Player.ConsumeAirDashUsage();
			Player.ConsumeAirJumpUsage();
		}

		DistAlongSpline = 0.0;
		PointLocLastFrame = LaunchComp.WorldLocation;

		//Target point to launch player through, centered on player capsule
		TargetLocation = LaunchComp.WorldLocation + LaunchComp.UpVector * (LaunchComp.LaunchHeightOffset - Player.CapsuleComponent.CapsuleHalfHeight);
		StartLocation = Player.ActorLocation;

		//Assign our relative start position to accommodate for moving targets
		StartRelativeLocation = LaunchComp.WorldTransform.InverseTransformPosition(Player.ActorLocation);
		TargetDirection = (TargetLocation - StartLocation).GetSafeNormal();
		
		if (LaunchComp.bUsePreferredDirection)
		{
			//If we have a prefered direction then verify that we are inside the Acceptance radius for the assist
			FVector AssistedDirection = LaunchComp.Owner.ActorTransform.TransformVector(LaunchComp.PreferredDirection.GetSafeNormal());
			float Dot = AssistedDirection.DotProduct(TargetDirection);
			float Deg = Math::Acos(Dot);
			Deg = Math::RadiansToDegrees(Deg);

			if(Deg < LaunchComp.AcceptanceDegrees)
			{
				TargetDirection = AssistedDirection;
			}
		}

		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(StartLocation);
		Spline.AddPoint(TargetLocation);
		Spline.SetCustomExitTangentPoint(TargetLocation + TargetDirection.GetSafeNormal());
		Spline.SetCustomCurvature(1.0);

		if (IsDebugActive())
		{
			Debug::DrawDebugArrow(LaunchComp.WorldLocation, LaunchComp.WorldLocation + TargetDirection.GetSafeNormal() * 150.0, 15.0, FLinearColor::Red, 7.0, 10.0);
			Debug::DrawDebugArrow(LaunchComp.WorldLocation, LaunchComp.WorldLocation + Spline.GetDirectionAtDistance(Spline.Length) * 150.0, 15.0, FLinearColor::Green, 7.0, 10.0);
		}

		if (PerspectiveModeComp.IsCameraBehaviorEnabled() && !LaunchComp.bBlockCameraEffectsForPoint)
		{
			bActivatedWithCameraEffects = true;
			HandleCameraOnActivation();
		}
		else
			bActivatedWithCameraEffects = false;
	}

	void HandleCameraOnActivation()
	{
		//Assign camera settings with capability tick order as priority
		Player.ApplyCameraSettings(GrappleComp.GrappleCamSetting, .85, this, SubPriority = 28);

		//Start with a juicy shake
		Player.PlayCameraShake(GrappleComp.GrappleShake, this, 2.0);

		//Calculate an offset for the poi, we don't want to look directly at the point, but rather a bit ahead of it and under it
		FVector ConstrainedTargetLocation = TargetLocation.ConstrainToPlane(MoveComp.GetWorldUp());
		FVector ConstrainedStartLocation = StartLocation.ConstrainToPlane(MoveComp.GetWorldUp());
		FVector DirOffset = (ConstrainedTargetLocation - ConstrainedStartLocation).GetSafeNormal() * 1500.0;
		DirOffset += MoveComp.WorldUp * -600.0;


		if(!LaunchComp.BlockLaunchLookAt)
		{
			//Apply that poi
			auto Poi = Player.CreatePointOfInterest();
			Poi.FocusTarget.SetFocusToComponent(GrappleComp.Data.CurrentGrapplePoint);
			Poi.FocusTarget.LocalOffset = GrappleComp.Data.CurrentGrapplePoint.PointOfInterestOffset;
			Poi.Settings.Duration = GrappleComp.Settings.GrappleLaunchDuration - 1.0;
			Poi.FocusTarget.WorldOffset = DirOffset;
			Poi.Settings.ClearOnInput = CameraPOIDefaultClearOnInput;
			Poi.Settings.RegainInputTime = 0.2;
			Poi.Apply(this, 1.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);

		//Make sure we are in the same state as when started (nothing interrupted) and cleanup / reset)
		if (GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleLaunch)
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);
			
			//Broadcast Grapple finished event
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();
		}
		else
		{
			// Our state was interrupted
			if (IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			GrappleComp.AnimData.bLaunching = false;
		}

		//Clear Point to be polled as targetable again
		LaunchComp.ClearPointForPlayer(Player);

		Player.ClearCameraSettingsByInstigator(this, 1.0);
		Player.ClearPointOfInterestByInstigator(this);
		Player.SetActorVelocity(Spline.GetDirectionAtDistance(Spline.Length) * LaunchComp.LaunchVelocity);
		
		//Apply any air control constraints assigned on the launch point
		if(LaunchComp.bConstrainInput)
		{
			AirMotionComp.TemporarilyWeakenAirControl(0, LaunchComp.BlockInputDuration, 0, LaunchComp.InputBlendInDuration, true);
		}

		LaunchComp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetLocation = LaunchComp.WorldLocation + LaunchComp.UpVector * (LaunchComp.LaunchHeightOffset - Player.CapsuleComponent.CapsuleHalfHeight);
		StartLocation += LaunchComp.WorldLocation - PointLocLastFrame;

		TargetDirection = (TargetLocation - StartLocation).GetSafeNormal();
		if (LaunchComp.bUsePreferredDirection)
		{
			FVector AssistedDirection = LaunchComp.Owner.ActorTransform.TransformVector(LaunchComp.PreferredDirection.GetSafeNormal());
			float Dot = AssistedDirection.DotProduct(TargetDirection);
			float Deg = Math::Acos(Dot);
			Deg = Math::RadiansToDegrees(Deg);
			if(Deg < LaunchComp.AcceptanceDegrees)
			{
				TargetDirection = AssistedDirection;
			}
		}

		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(StartLocation);
		Spline.AddPoint(TargetLocation);
		Spline.SetCustomExitTangentPoint(TargetLocation + TargetDirection.GetSafeNormal());
		Spline.SetCustomCurvature(1.0);

		PointLocLastFrame = LaunchComp.WorldLocation;

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				// Speed = Math::Lerp(GrappleComp.Settings.GrappleLaunchEnterSpeed, LaunchComp.LaunchVelocity, GetMoveAlpha());

				Speed = Math::Lerp(Math::Max(LaunchComp.LaunchVelocity * 1.2, GrappleComp.Settings.GrappleLaunchEnterSpeed), LaunchComp.LaunchVelocity, GetMoveAlpha());
				DistAlongSpline += Speed * DeltaTime;
				DistAlongSpline = Math::Clamp(DistAlongSpline, 0.0, Spline.Length);

				FVector NewLoc = Spline.GetLocationAtDistance(DistAlongSpline);
				FVector NewVel = Spline.GetDirectionAtDistance(DistAlongSpline) * Speed;

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, NewVel);
				Movement.SetRotation(Spline.GetDirectionAtDistance(DistAlongSpline).Rotation());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"Grapple", this);
		}

		if (bActivatedWithCameraEffects)
			HandleCameraDuringMove();

		GrappleComp.RetractGrapple(ActiveDuration);

#if EDITOR
		if (IsDebugActive())
			DrawDebugSpline(Spline);
#endif
	}

	void HandleCameraDuringMove()
	{
		float Alpha = ActiveDuration / GrappleComp.Settings.GrappleLaunchDuration;
		float BlendFraction = Math::Lerp(1.0, 0.0, Alpha);
		BlendFraction = Math::Clamp(BlendFraction, 0, 1);

		Player.ApplyManualFractionToCameraSettings(BlendFraction, this);
	}

	void DrawDebugSpline(FHazeRuntimeSpline& InSpline)
	{
		// start spline point
		Debug::DrawDebugPoint(InSpline.Points[0], 20.0, FLinearColor::Green);

		// end spline point
		Debug::DrawDebugPoint(InSpline.Points.Last(), 20.0, FLinearColor::Blue);

		// draw all spline points that we've assigned
		for(FVector P : InSpline.Points)
			Debug::DrawDebugPoint(P, 10.0, FLinearColor::Purple);

		// Find 150 uniformerly distributed locations on the spline
		TArray<FVector> Locations;
		InSpline.GetLocations(Locations, 150);

		// Draw all locations that we've found on the spline
		for(FVector L : Locations)
			Debug::DrawDebugPoint(L, 5.0, FLinearColor::Yellow);

		// Draw a location moving along the spline based on elasped time
		Debug::DrawDebugPoint(InSpline.GetLocation((Time::GetGameTimeSeconds() * 0.2) % 1.0), 30.0, FLinearColor::White);
	}

	float GetMoveAlpha() const
	{
		if(DistAlongSpline == 0)
			return 0;

		return DistAlongSpline / Spline.Length;
	}
};