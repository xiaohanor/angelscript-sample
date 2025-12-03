class UHackableCraneArmCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableCraneArm CraneArm;
	AHazePlayerCharacter Player;

	bool bHasMoved = false;
	bool bHasSpined = false;
	bool bRemoveTutorial = false;

	bool bWasMoving = false;
	int PreviousMoveDir;

	bool bWasPitching = false;
	int PreviousPitchDir;

	bool bWasYawing = false;
	int PreviousYawDir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CraneArm = Cast<AHackableCraneArm>(Owner);
		Player = Drone::GetSwarmDronePlayer();
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CraneArm.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CraneArm.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ActivateCamera(CraneArm.CameraComponent, 3, this);
		CapabilityInput::LinkActorToPlayerInput(CraneArm, Drone::GetSwarmDronePlayer());

		bHasMoved = false;
		bHasSpined = false;
		bRemoveTutorial = false;

		CraneArm.RotateInput = FVector2D::ZeroVector;
		CraneArm.MoveInput = 0;

		if(HasControl())
		{
			CraneArm.SyncedMoveAlpha.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
			CraneArm.SyncedPitchAlpha.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
			CraneArm.SyncedYawAlpha.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
			CraneArm.SyncedInput.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);


			CraneArm.SyncInput();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(CraneArm.CameraComponent, 2);
		CapabilityInput::LinkActorToPlayerInput(CraneArm, nullptr);

		CraneArm.RotateInput = FVector2D::ZeroVector;
		CraneArm.MoveInput = 0;

		if(HasControl())
		{
			CraneArm.SyncedMoveAlpha.OverrideSyncRate(EHazeCrumbSyncRate::Low);
			CraneArm.SyncedPitchAlpha.OverrideSyncRate(EHazeCrumbSyncRate::Low);
			CraneArm.SyncedYawAlpha.OverrideSyncRate(EHazeCrumbSyncRate::Low);
			CraneArm.SyncedInput.OverrideSyncRate(EHazeCrumbSyncRate::Low);

			CraneArm.SyncInput();
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HasControl())
		{
			AddToAlpha(CraneArm.MoveAlpha, CraneArm.MoveInput, CraneArm.StartOffset.Distance(CraneArm.EndOffset), CraneArm.TranslateSpeed, DeltaTime);
			AddToAlpha(CraneArm.PitchAlpha, CraneArm.RotateInput.Y, CraneArm.MaxPitch - CraneArm.MinPitch, -CraneArm.PitchSpeed, DeltaTime);
			AddToAlpha(CraneArm.YawAlpha, CraneArm.RotateInput.X, CraneArm.MaxYaw - CraneArm.MinYaw, -CraneArm.YawSpeed, DeltaTime);
		
			CraneArm.SyncedMoveAlpha.SetValue(CraneArm.MoveAlpha);
			CraneArm.SyncedPitchAlpha.SetValue(CraneArm.PitchAlpha);
			CraneArm.SyncedYawAlpha.SetValue(CraneArm.YawAlpha);
		}
		else
		{
			CraneArm.MoveAlpha = CraneArm.SyncedMoveAlpha.GetValue();
			CraneArm.PitchAlpha = CraneArm.SyncedPitchAlpha.GetValue();
			CraneArm.YawAlpha = CraneArm.SyncedYawAlpha.GetValue();
		}

		ApplyAlphas(DeltaTime);

		TriggerMoveEvents();
		TriggerRotateEvents();
	}

	private void ApplyAlphas(float DeltaTime)
	{
		const float MoveAlpha = CraneArm.AccMoveAlpha.AccelerateTo(CraneArm.MoveAlpha, CraneArm.TranslateDuration, DeltaTime);
		const float PitchAlpha = CraneArm.AccPitchAlpha.SpringTo(CraneArm.PitchAlpha, CraneArm.SpringStiffness, CraneArm.SpringDamping, DeltaTime);
		const float YawAlpha = CraneArm.AccYawAlpha.SpringTo(CraneArm.YawAlpha, CraneArm.SpringStiffness, CraneArm.SpringDamping, DeltaTime);

		const FVector NewLocation = Math::Lerp(CraneArm.StartOffset, CraneArm.EndOffset, MoveAlpha);
		CraneArm.TranslateRoot.SetRelativeLocation(NewLocation);

		const float NewYaw = Math::Lerp(CraneArm.MinYaw, CraneArm.MaxYaw, YawAlpha);
		CraneArm.YawRoot.SetRelativeRotation(FRotator(0.0, NewYaw, 0.0));

		const float NewPitch = Math::Lerp(CraneArm.MinPitch, CraneArm.MaxPitch, PitchAlpha);
		CraneArm.PitchRoot.SetRelativeRotation(FRotator(NewPitch, 0.0, 0.0));
	}

	private void TriggerMoveEvents()
	{
		const bool bIsMoving = Math::Abs(CraneArm.MoveInput) > KINDA_SMALL_NUMBER && !IsAcceleratedAlphaZeroOrOne(CraneArm.AccMoveAlpha);

		if(bIsMoving && bWasMoving)
		{
			const int MoveDir = int(Math::Sign(CraneArm.MoveInput));

			if(MoveDir != PreviousMoveDir)
			{
				UHackableCraneArmEventHandler::Trigger_BaseChangeDirection(CraneArm);
			}

			PreviousMoveDir = MoveDir;
		}
		else if(!bWasMoving && bIsMoving)
		{
			UHackableCraneArmEventHandler::Trigger_BaseStartMoving(CraneArm);
		}
		else if(bWasMoving && !bIsMoving)
		{
			UHackableCraneArmEventHandler::Trigger_BaseStopMoving(CraneArm);
		}

		bWasMoving = bIsMoving;
	}

	private bool IsAcceleratedAlphaZeroOrOne(FHazeAcceleratedFloat AccFloat, float ValueThreshold = 0.01, float VelocityThreshold = 0.1) const
	{
		if(AccFloat.Velocity > VelocityThreshold)
			return false;

		if(AccFloat.Value < ValueThreshold)
			return true;

		if(AccFloat.Value > 1.0 - ValueThreshold)
			return true;

		return false;
	}

	private void TriggerRotateEvents()
	{
		const bool bIsPitching = Math::Abs(CraneArm.RotateInput.Y) > KINDA_SMALL_NUMBER && !IsAcceleratedAlphaZeroOrOne(CraneArm.AccPitchAlpha);
		const bool bIsYawing = Math::Abs(CraneArm.RotateInput.X) > KINDA_SMALL_NUMBER && !IsAcceleratedAlphaZeroOrOne(CraneArm.AccYawAlpha);
		
		const bool bIsRotating = bIsPitching || bIsYawing;
		const bool bWasRotating = bWasPitching || bWasYawing;

		if(!bWasRotating && bIsRotating)
		{
			UHackableCraneArmEventHandler::Trigger_ArmStartMoving(CraneArm);
		}
		else if(bWasRotating && !bIsRotating)
		{
			UHackableCraneArmEventHandler::Trigger_ArmStopMoving(CraneArm);
		}

		if(bIsPitching && bWasPitching)
		{
			const int PitchDir = int(Math::Sign(CraneArm.RotateInput.Y));

			if(PitchDir != PreviousPitchDir)
			{
				UHackableCraneArmEventHandler::Trigger_ArmVerticalChangeDirection(CraneArm);
			}

			PreviousPitchDir = PitchDir;
		}

		if(bIsYawing && bWasYawing)
		{
			const int YawDir = int(Math::Sign(CraneArm.RotateInput.X));

			if(YawDir != PreviousYawDir)
			{
				UHackableCraneArmEventHandler::Trigger_ArmHorizontalChangeDirection(CraneArm);
			}

			PreviousYawDir = YawDir;
		}

		bWasPitching = bIsPitching;
		bWasYawing = bIsYawing;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			// Smoothing is done on the input just to prevent frames where the input is 0,0,0 when it's not intended to be

			const float TargetHorizontalMoveInput = GetAttributeFloat(AttributeNames::MoveRight);
			const float TargetVerticalMoveInput = -GetAttributeFloat(AttributeNames::MoveForward);
			const float TargetMoveInput = Math::Clamp(TargetHorizontalMoveInput + TargetVerticalMoveInput, -1, 1);
			CraneArm.MoveInput = Math::FInterpTo(CraneArm.MoveInput, TargetMoveInput, DeltaTime, 10);

			FVector2D TargetRotateInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection).GetClampedToMaxSize(1);
			CraneArm.RotateInput.X = Math::FInterpTo(CraneArm.RotateInput.X, TargetRotateInput.X, DeltaTime, 10);
			CraneArm.RotateInput.Y = Math::FInterpTo(CraneArm.RotateInput.Y, TargetRotateInput.Y, DeltaTime, 10);

			CraneArm.SyncInput();

			if(!bHasMoved && Math::Abs(TargetMoveInput) > 0)
				bHasMoved = true;

			if(!bHasSpined && (Math::Abs(TargetRotateInput.Y) > 0 || Math::Abs(TargetRotateInput.X) > 0))
				bHasSpined = true;

			if(bHasMoved && bHasSpined && !bRemoveTutorial)
			{
				CraneArm.OnRemoveTutorial.Broadcast();
				bRemoveTutorial = true;
			}
		}
		else
		{
			CraneArm.GetSyncedInput();
		}

		CraneArm.UpdateCameraLocation();


	}

	void AddToAlpha(float& CurrentAlpha, float Change, float Range, float Speed, float DeltaTime)
	{
		float Additive = Change * Speed * DeltaTime / Range;
		CurrentAlpha = Math::Saturate(CurrentAlpha + Additive);
	}
}