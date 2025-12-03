class UControllableDropShipPilotPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UControllableDropShipPilotPlayerComponent DropShipComp;

	bool bFlying = false;

	FHazeAcceleratedRotator AcceleratedDesiredRotation;

	bool bTutorialCompleted = false;
	float TimeSteered = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DropShipComp = UControllableDropShipPilotPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DropShipComp.CurrentDropShip == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DropShipComp.CurrentDropShip == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Outline, this);
		Player.BlockCapabilities(n"Death", this);

		Player.AttachToComponent(DropShipComp.CurrentDropShip.PilotAttachmentComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = DropShipComp.IdleAnim;
		AnimParams.bLoop = true;
		AnimParams.BlendTime = 0.0;
		Player.PlaySlotAnimation(AnimParams);

		Player.TeleportActor(DropShipComp.CurrentDropShip.PilotAttachmentComp.WorldLocation, DropShipComp.CurrentDropShip.PilotAttachmentComp.WorldRotation, this, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Outline, this);
		Player.UnblockCapabilities(n"Death", this);

		Player.StopSlotAnimation();
		Player.DetachFromActor();

		Player.ClearCameraSettingsByInstigator(this);
		Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DropShipComp.CurrentDropShip.bFlying)
		{
			if (!bFlying)
				StartFlying();
		}

		if (DropShipComp.CurrentDropShip.bFlying)
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			if (Player.IsSteeringPitchInverted())
				Input.Y *= -1.0;
			
			DropShipComp.CurrentDropShip.PilotInput = Input;

			float LeftMotorFF = (-Input.X * 0.1) + (Input.Y * 0.1);
			float RightMotorFF =(Input.X * 0.1) + (Math::Abs(Input.Y * 0.1));
			Player.SetFrameForceFeedback(LeftMotorFF, RightMotorFF, 0.0, 0.0);

			UCameraUserComponent CamUserComp = UCameraUserComponent::Get(Player);

			FRotator DesiredRotation = Player.ActorRotation;
			DesiredRotation.Pitch -= 5.0;
			
			FRotator NewDesired = AcceleratedDesiredRotation.AccelerateTo(DesiredRotation, 0.3, DeltaTime);
			CamUserComp.SetDesiredRotation(NewDesired, this);

			if (!bTutorialCompleted)
			{
				float TutorialOffset = Math::GetMappedRangeValueClamped(FVector2D(-ControllableDropShip::FlyingMaxOffset.Y, -ControllableDropShip::FlyingMaxOffset.Y + 800.0), FVector2D(1000.0, -750.0), DropShipComp.CurrentDropShip.CurrentSplineOffset.Y);
				DropShipComp.CurrentDropShip.SteerTutorialAttachComp.SetRelativeLocation(FVector(0.0, 0.0, TutorialOffset));

				if (Input.Size() > 0.0)
				{
					TimeSteered += DeltaTime;
					if (TimeSteered >= 5.0)
					{
						bTutorialCompleted = true;
						Player.RemoveTutorialPromptByInstigator(this);
					}
				}
			}
		}
	}

	void StartFlying()
	{
		AcceleratedDesiredRotation.SnapTo(Player.ViewRotation);

		bFlying = true;

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRightUpDown;
		TutorialPrompt.Text = NSLOCTEXT("ControllableShip", "SteerPrompt", "Steer");
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, DropShipComp.CurrentDropShip.SteerTutorialAttachComp, FVector(0.0, 0.0, 0.0), 0.0);

		Player.ApplyCameraSettings(DropShipComp.CurrentDropShip.PilotCamSettings, DropShipComp.CurrentDropShip.bSnapActivated ? 0.0 : 2.0, this, EHazeCameraPriority::VeryHigh);
		Player.PlayCameraShake(DropShipComp.CurrentDropShip.PilotPassiveCamShake, this);
	}
}