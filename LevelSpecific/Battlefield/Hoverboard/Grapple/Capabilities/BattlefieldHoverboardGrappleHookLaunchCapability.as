
class UBattlefieldHoverboardGrappleHookLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleLaunch);
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
	UGrappleLaunchPointComponent LaunchComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UBattlefieldHoverboardGrappleSettings GrappleSettings;

	FVector TargetLocation;
	FVector StartLocation;
	FVector StartRelativeLocation;
	FVector TargetDirection;
	FVector PointLocLastFrame;
	float Speed;
	float EnterSpeed;
	float DistAlongSpline;
	bool bActivatedWithCameraEffects = false;

	FHazeRuntimeSpline Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UBattlefieldHoverboardGrappleComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		PlayerGrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);

		GrappleSettings = UBattlefieldHoverboardGrappleSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleLaunch)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (GetMoveAlpha() >= 1.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Block everything that should be blocked while grappling
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);

		//Get the grapple point we are using to launch ourselves
		LaunchComp = Cast<UGrappleLaunchPointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		//Calculate height diff to launch point for animations
		GrappleComp.CalculateHeightOffset();

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
			//If we have a preferred direction then verify that we are inside the Acceptance radius for the assist
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

		Player.PlayForceFeedback(GrappleSettings.LaunchRumble, false, false, this, 1.0);

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			bActivatedWithCameraEffects = true;
			HandleCameraOnActivation();
		}
		else
			bActivatedWithCameraEffects = false;

			EnterSpeed = Player.ActorVelocity.Size() + GrappleSettings.GrappleLaunchAdditionalEnterSpeed;
		}

	void HandleCameraOnActivation()
	{
		//Assign camera settings with capability tick order as priority
		Player.ApplyCameraSettings(GrappleSettings.GrappleCamSetting, .5, this, SubPriority = 28);

		//Start with a juicy shake
		Player.PlayCameraShake(GrappleSettings.GrappleShake, this, 2.0);
		Player.ApplyBlendToCurrentView(0.5);
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
			PlayerGrappleComp.Data.ResetData();
		}
		else
			GrappleComp.AnimData.bLaunching = false;

		//Clear Point to be polled as targetable again
		LaunchComp.ClearPointForPlayer(Player);

		Player.ClearCameraSettingsByInstigator(this, 1.0);
		Player.ClearPointOfInterestByInstigator(this);
		
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
				DistAlongSpline += Speed * DeltaTime;

				float RemainingDistance = 0.0;
				Speed = Math::Lerp(EnterSpeed, LaunchComp.LaunchVelocity, GetMoveAlpha());
				Speed = Math::Clamp(Speed, GrappleSettings.GrappleMinimumSpeed, GrappleSettings.GrappleMaximumSpeed);
				if(DistAlongSpline >= Spline.Length)
				{
					RemainingDistance = DistAlongSpline - Spline.Length;
					// That speed is being applied as a delta so you don't have inconsistent speeds at the end of the spline
					Speed -= (RemainingDistance / DeltaTime);
				}

				DistAlongSpline = Math::Clamp(DistAlongSpline, 0.0, Spline.Length);
				FVector SplineDir = Spline.GetDirectionAtDistance(DistAlongSpline);

				FVector NewLoc = Spline.GetLocationAtDistance(DistAlongSpline);
				FVector NewVel = SplineDir * Speed;

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, NewVel);
				Movement.AddDelta(SplineDir * RemainingDistance);
				Movement.SetRotation(Spline.GetDirectionAtDistance(DistAlongSpline).Rotation());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"HoverboardGrappling", this);
		}

		if (bActivatedWithCameraEffects)
			HandleCameraDuringMove();

		HandleGrappleHookActor();

		if (IsDebugActive())
			DrawDebugSpline(Spline);
	}

	void HandleCameraDuringMove()
	{
		float Alpha = ActiveDuration / GrappleComp.Settings.GrappleLaunchDuration;
		float BlendFraction = Math::Lerp(1.0, 0.0, Alpha);

		Player.ApplyManualFractionToCameraSettings(BlendFraction, this);
	}

	void HandleGrappleHookActor()
	{
		float Alpha = ActiveDuration / GrappleComp.Settings.GrappleLaunchDuration;

		FVector NewLoc = Math::Lerp(GrappleComp.Data.CurrentGrapplePoint.WorldLocation, Player.Mesh.GetSocketLocation(n"LeftAttach"), Alpha);
		GrappleComp.Grapple.SetActorLocation(NewLoc);
		float NewTense = Math::Lerp(0.15, 2.15, Alpha);
		GrappleComp.Grapple.Tense = NewTense;
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

		// Find 150 uniformly distributed locations on the spline
		TArray<FVector> Locations;
		InSpline.GetLocations(Locations, 150);

		// Draw all locations that we've found on the spline
		for(FVector L : Locations)
			Debug::DrawDebugPoint(L, 5.0, FLinearColor::Yellow);

		// Draw a location moving along the spline based on elapsed time
		Debug::DrawDebugPoint(InSpline.GetLocation((Time::GetGameTimeSeconds() * 0.2) % 1.0), 30.0, FLinearColor::White);
	}

	float GetMoveAlpha() const
	{
		if(DistAlongSpline == 0)
			return 0;

		return DistAlongSpline / Spline.Length;
	}
};