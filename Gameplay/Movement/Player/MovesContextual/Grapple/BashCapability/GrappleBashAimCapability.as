class UPlayerGrappleBashAimCapability : UHazePlayerCapability
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
	USteppingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UGrappleBashPointComponent PointComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FVector EnterDirection;
	FVector LockInAimDirection;
	FVector CurrentAimDirection;
	float LockInTimer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleBashAim)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!IsValid(PointComp))
			return true;

		if (ActiveDuration >= GrappleComp.Settings.GrappleBashMaxAimDuration)
			return true;
		if (LockInTimer >= GrappleComp.Settings.GrappleBashAimLockInTimer)
			return true;
		if (WasActionStarted(ActionNames::MovementJump))
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

		// Get the grapple point we are using to launch ourselves
		PointComp = Cast<UGrappleBashPointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		// Calculate height diff to bash point for animations
		GrappleComp.CalculateHeightOffset();

		LockInTimer = 0.0;
		EnterDirection = Player.ActorVelocity.GetSafeNormal();
		if (EnterDirection.IsNearlyZero())
			EnterDirection = Player.ActorForwardVector;
		UpdateAimAngle(EnterDirection, 0.0);

		// TEMP: Play a random animation just to show what it could look like
#if EDITOR
		Player.PlaySlotAnimation(
			Animation = Cast<UAnimSequence>(LoadObject(nullptr, "/Game/Animation/Assets/Characters/Mio/Traversal/Jump/Mio_Trav_DoubleJump.Mio_Trav_DoubleJump")),
			PlayRate = 0.2,
		);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		Player.SetActorVelocity(FVector::ZeroVector);

		//Make sure we are in the same state as when started (nothing interrupted) and cleanup / reset)
		if (GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleBashAim)
		{
			FVector Impulse;
			if (CurrentAimDirection.Size() > 0.1)
				Impulse = CurrentAimDirection;
			else
				Impulse = LockInAimDirection;
			Impulse *= PointComp.Settings.LaunchImpulse;

			FVector SidewaysImpulse = Impulse.ConstrainToPlane(MoveComp.WorldUp);
			float UpwardImpulse = Impulse.DotProduct(MoveComp.WorldUp);
			if (UpwardImpulse < PointComp.Settings.BaseUpwardsImpulse)
				UpwardImpulse = Math::Min(UpwardImpulse + PointComp.Settings.BaseUpwardsImpulse, PointComp.Settings.BaseUpwardsImpulse);

			Impulse = MoveComp.WorldUp * UpwardImpulse + SidewaysImpulse;

			Player.AddMovementImpulse(Impulse, n"GrappleBash");

			// Broadcast Grapple finished event
			if(IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();
		}
		else
		{
			// Broadcast Grapple interrupted event
			if(IsValid(GrappleComp.Data.CurrentGrapplePoint))
				GrappleComp.Data.CurrentGrapplePoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);
		}

		// Clear Point to be polled as targetable again
		PointComp.ClearPointForPlayer(Player);
		Player.ResetAirDashUsage();
		Player.ResetAirJumpUsage();

		Player.ClearCameraSettingsByInstigator(this, 1.0);
		Player.ClearPointOfInterestByInstigator(this);
		
		PointComp = nullptr;

#if EDITOR
		// TEMP: Play a random animation just to show what it could look like
		Player.PlaySlotAnimation(
			Animation = Cast<UAnimSequence>(LoadObject(nullptr, "/Game/Animation/Assets/Characters/Mio/Traversal/Slide/Mio_Trav_Slide_LongJump.Mio_Trav_Slide_LongJump")),
		);
#endif
	}

	void UpdateAimAngle(FVector WantedDirection, float DeltaTime)
	{
		if (WantedDirection.Size() < 0.3)
			return;

		if (PerspectiveModeComp.GetPerspectiveMode() != EPlayerMovementPerspectiveMode::SideScroller)
		{
			FVector BaseAimDirection;
			switch (PointComp.Settings.AimDirectionMode)
			{
				case EGrappleBashAimDirectionMode::PlayerEnterDirection:
					BaseAimDirection = EnterDirection.ConstrainToPlane(MoveComp.WorldUp);
				break;
				case EGrappleBashAimDirectionMode::PlayerOppositeDirection:
					BaseAimDirection = (-EnterDirection).ConstrainToPlane(MoveComp.WorldUp);
				break;
				case EGrappleBashAimDirectionMode::BashPointForwardDirection:
					BaseAimDirection = PointComp.ForwardVector.ConstrainToPlane(MoveComp.WorldUp);
				break;
			}

			FVector ConstrainedAimDirection = WantedDirection.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			ConstrainedAimDirection = ConstrainedAimDirection.ConstrainToCone(
				BaseAimDirection,
				Math::DegreesToRadians(PointComp.Settings.MaximumAimAngle));

			FQuat UpwardAngle = FQuat(MoveComp.WorldUp.CrossProduct(ConstrainedAimDirection), -Math::DegreesToRadians(PointComp.Settings.UpwardsLaunchAngle));
			ConstrainedAimDirection = UpwardAngle.RotateVector(ConstrainedAimDirection);

			CurrentAimDirection = ConstrainedAimDirection;
		}
		else
		{
			const FRotator ViewRotation = Player.GetViewRotation();
			FVector ConstrainVector = MoveComp.WorldUp.CrossProduct(ViewRotation.RightVector);

			FVector BaseAimDirection;
			switch (PointComp.Settings.AimDirectionMode)
			{
				case EGrappleBashAimDirectionMode::PlayerEnterDirection:
					BaseAimDirection = EnterDirection.ConstrainToPlane(ConstrainVector);
				break;
				case EGrappleBashAimDirectionMode::PlayerOppositeDirection:
					BaseAimDirection = (-EnterDirection).ConstrainToPlane(ConstrainVector);
				break;
				case EGrappleBashAimDirectionMode::BashPointForwardDirection:
					BaseAimDirection = PointComp.ForwardVector.ConstrainToPlane(ConstrainVector);
				break;
			}

			FVector ConstrainedAimDirection = WantedDirection.ConstrainToPlane(ConstrainVector).GetSafeNormal();
			ConstrainedAimDirection = ConstrainedAimDirection.ConstrainToCone(
				BaseAimDirection,
				Math::DegreesToRadians(PointComp.Settings.MaximumAimAngle));

			CurrentAimDirection = ConstrainedAimDirection;
		}

		if (Math::RadiansToDegrees(CurrentAimDirection.AngularDistance(LockInAimDirection)) < 20.0
			&& LockInAimDirection.Size() > 0.1)
		{
			LockInTimer += DeltaTime;
		}
		else
		{
			LockInTimer = 0.0;
			LockInAimDirection = CurrentAimDirection;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			if (HasControl())
				UpdateAimAngle(MoveComp.MovementInput, DeltaTime);
			else
				UpdateAimAngle(MoveComp.SyncedMovementInputForAnimationOnly, DeltaTime);
		}
		else
		{
			FVector2D InputVector = GetAttributeVector2D(n"GamepadLeftStick_NoDeadZone");
			const FRotator ViewRotation = Player.GetViewRotation();
			FVector WorldAimDirection = ViewRotation.UpVector * InputVector.Y
				+ ViewRotation.RightVector * InputVector.X;
			UpdateAimAngle(WorldAimDirection, DeltaTime);
		}

		FVector ShowDirection = CurrentAimDirection;
		if (ShowDirection.Size() < 0.1)
			ShowDirection = LockInAimDirection;
		
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.InterpRotationTo(
					FQuat::MakeFromZX(MoveComp.WorldUp, ShowDirection),
					2.0 * PI
				);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"Grapple", this);
		}

		Debug::DrawDebugArrow(Player.ActorLocation,
			Player.ActorLocation + ShowDirection * 150.0,
			80.0, FLinearColor::Blue, 20.0
		);

		// TEMP: Play a random animation just to show what it could look like
#if EDITOR
		Player.SetSlotAnimationPlayRate(
			Animation = Cast<UAnimSequence>(LoadObject(nullptr, "/Game/Animation/Assets/Characters/Mio/Traversal/Jump/Mio_Trav_DoubleJump.Mio_Trav_DoubleJump")),
			PlayRate = Math::Lerp(0.2, 1.0, Math::Saturate(ActiveDuration / 1.0)),
		);
#endif
	}
};