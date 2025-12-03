class UPlayerGrappleBashStartCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleBash);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 6;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UGrappleBashPointComponent PointComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	bool bActivatedWithCameraEffects;
	bool bReachedPoint;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleBashStart)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!IsValid(PointComp) || ActiveDuration > 5.0)
			return true;

		if (bReachedPoint)
			return true;

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Block everything that should be blocked while grappling
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		Player.BlockCapabilities(PlayerGrappleTags::GrappleEnter, this);
		Speed = GrappleComp.Settings.GrappleBashEnterStartSpeed;
		bReachedPoint = false;

		// Get the grapple point we are using to launch ourselves
		PointComp = Cast<UGrappleBashPointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		// Calculate height diff to bash point for animations
		GrappleComp.CalculateHeightOffset();

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			bActivatedWithCameraEffects = true;
			HandleCameraOnActivation();
		}
		else
		{
			bActivatedWithCameraEffects = false;
		}
	}

	void HandleCameraOnActivation()
	{
		//Assign camera settings with capability tick order as priority
		Player.ApplyCameraSettings(GrappleComp.GrappleCamSetting, .85, this, SubPriority = 28);

		//Start with a juicy shake
		Player.PlayCameraShake(GrappleComp.GrappleShake, this, 2.0);

		//Calculate an offset for the poi, we don't want to look directly at the point, but rather a bit ahead of it and under it
		FVector ConstrainedTargetLocation = PointComp.WorldLocation.ConstrainToPlane(MoveComp.GetWorldUp());
		FVector ConstrainedStartLocation = Player.ActorLocation.ConstrainToPlane(MoveComp.GetWorldUp());
		FVector DirOffset = (ConstrainedTargetLocation - ConstrainedStartLocation).GetSafeNormal() * 1500.0;
		DirOffset += MoveComp.WorldUp * -600.0;

		//Apply that poi
		auto Poi = Player.CreatePointOfInterest();
		Poi.FocusTarget.SetFocusToComponent(GrappleComp.Data.CurrentGrapplePoint);
		Poi.FocusTarget.LocalOffset = GrappleComp.Data.CurrentGrapplePoint.PointOfInterestOffset;
		Poi.Settings.Duration = GrappleComp.Settings.GrappleDuration - 1.0;
		Poi.FocusTarget.WorldOffset = DirOffset;
		Poi.Settings.ClearOnInput = CameraPOIDefaultClearOnInput;
		Poi.Settings.RegainInputTime = 0.2;
		Poi.Apply(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		Player.UnblockCapabilities(PlayerGrappleTags::GrappleEnter, this);

		//Make sure we are in the same state as when started (nothing interrupted) and cleanup / reset)
		if (GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleBashStart
			&& IsValid(PointComp) && !PointComp.IsDisabledForPlayer(Player))
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);
			GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleBashAim;
		}
		else
		{
			// Clear Point to be polled as targetable again
			PointComp.ClearPointForPlayer(Player);
			Player.SetActorVelocity(FVector::ZeroVector);
		}

		Player.ClearCameraSettingsByInstigator(this, 1.0);
		Player.ClearPointOfInterestByInstigator(this);
		
		PointComp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{		
				Speed = Math::FInterpConstantTo(Speed, GrappleComp.Settings.GrappleBashEnterMaxSpeed,
					DeltaTime, GrappleComp.Settings.GrappleBashEnterAcceleration);

				FVector TargetLocation = PointComp.WorldLocation;
				FVector Delta = TargetLocation - Player.ActorLocation;

				if (Delta.Size() < Speed * DeltaTime)
					bReachedPoint = true;

				Delta = Delta.GetClampedToMaxSize(Speed * DeltaTime);
				Movement.AddDelta(Delta);
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

		HandleGrappleHookActor();
	}

	void HandleCameraDuringMove()
	{
		float Alpha = Math::Saturate(ActiveDuration / GrappleComp.Settings.GrappleDuration);
		float BlendFraction = Math::Lerp(1.0, 0.0, Alpha);
		BlendFraction = Math::Clamp(BlendFraction, 0, 1);

		Player.ApplyManualFractionToCameraSettings(BlendFraction, this);
	}

	void HandleGrappleHookActor()
	{
		float Alpha = Math::Saturate(ActiveDuration / GrappleComp.Settings.GrappleDuration);
		FVector NewLoc = Math::Lerp(GrappleComp.Data.CurrentGrapplePoint.WorldLocation, Player.Mesh.GetSocketLocation(n"LeftAttach"), Alpha);
		GrappleComp.Grapple.SetActorLocation(NewLoc);
		float NewTense = Math::Lerp(0.15, 2.15, Alpha);
		GrappleComp.Grapple.Tense = NewTense;
	}
};

