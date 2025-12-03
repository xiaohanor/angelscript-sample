class UControllableDropShipPassengerPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerAimingComponent AimingComp;

	UControllableDropShipPassengerPlayerComponent DropShipComp;

	bool bFightStarted = false;

	bool bLeftPunch = false;

	bool bBlocking = false;

	float ShootCooldown = 0.05;
	float CurShotCooldown = 0.0;

	bool bShootLeft = false;

	float ForceFeedbackCooldown = 0.12;
	float CurForcefeedbackCooldown = 0.0;

	float TimeSpentShooting = 0.0;
	bool bTutorialCompleted = false;

	bool bFlying = false;

	UControllableDropShipCrosshair Crosshair;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DropShipComp = UControllableDropShipPassengerPlayerComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
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
		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.BlockCapabilities(n"Death", this);
		Player.BlockCapabilities(n"HitReaction", this);

		Player.AttachToComponent(DropShipComp.CurrentDropShip.Turret.GunnerAttachComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Player.TeleportActor(DropShipComp.CurrentDropShip.Turret.GunnerAttachComp.WorldLocation, DropShipComp.CurrentDropShip.Turret.GunnerAttachComp.WorldRotation, this, false);

		Player.AddLocomotionFeature(DropShipComp.CurrentDropShip.GunnerFeature, this);

		if (DropShipComp.CurrentDropShip.bSnapActivated)
		{	
			Player.ActivateCamera(DropShipComp.CurrentDropShip.Turret.CameraComp, DropShipComp.CurrentDropShip.bSnapActivated ? 0.0 : 1.0, this);

			Player.ApplySettings(DropShipComp.PlayerAimingSettings, this);
			AimingComp.StartAiming(DropShipComp.CurrentDropShip, DropShipComp.AimingSettings);
			Crosshair = Cast<UControllableDropShipCrosshair>(AimingComp.GetCrosshairWidget(DropShipComp.CurrentDropShip));
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Outline, this);
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
		Player.UnblockCapabilities(n"Death", this);
		Player.UnblockCapabilities(n"HitReaction", this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		if (DropShipComp.CurrentDropShip != nullptr)
		{
			Player.DeactivateCamera(DropShipComp.CurrentDropShip.Turret.CameraComp, 0.0);
		}

		Player.ClearSettingsByInstigator(this);
		if (AimingComp.IsAiming(DropShipComp.CurrentDropShip))
			AimingComp.StopAiming(DropShipComp.CurrentDropShip);

		Player.RemoveTutorialPromptByInstigator(this);

		Player.RemoveLocomotionFeature(DropShipComp.CurrentDropShip.GunnerFeature, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"HijackGunner", this);

		if (DropShipComp.CurrentDropShip.bFlying)
		{
			if (!bFlying)
				StartFlying();
		}

		if (!bFlying)
			return;

		DropShipComp.AimBSValues.Y = DropShipComp.CurrentDropShip.TurretPitch;
		DropShipComp.bShooting = IsActioning(ActionNames::PrimaryLevelAbility);
		DropShipComp.CurrentDropShip.Turret.bShooting = IsActioning(ActionNames::PrimaryLevelAbility);

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		FVector2D CameraInput = Player.GetCameraInput();
		
		// If camera input is outside the range [-1,+1], then allow the sum to go outside that range too
		// This happens when the camera input is a mouse cursor, as that can move more than 1 per frame
		Input.X = Math::Clamp(Input.X + CameraInput.X, Math::Min(-1.0, CameraInput.X), Math::Max(1.0, CameraInput.X));
		Input.Y = Math::Clamp(Input.Y + CameraInput.Y, Math::Min(-1.0, CameraInput.Y), Math::Max(1.0, CameraInput.Y));
		DropShipComp.CurrentDropShip.PassengerInput = Input;

		if (IsActioning(ActionNames::PrimaryLevelAbility))
		{
			if (!bTutorialCompleted)
			{
				TimeSpentShooting += DeltaTime;
				if (TimeSpentShooting >= 3.0)
				{
					bTutorialCompleted = true;
					Player.RemoveTutorialPromptByInstigator(this);
				}
			}

			CurShotCooldown += DeltaTime;
			CurForcefeedbackCooldown += DeltaTime;
			if (CurShotCooldown >= ShootCooldown)
			{
				CurShotCooldown = 0.0;
				
				FVector ShootTarget = Player.ViewLocation + (Player.ViewRotation.ForwardVector * 40000.0);
				if (AimingComp.GetAimingTarget(DropShipComp.CurrentDropShip).AutoAimTarget != nullptr)
					ShootTarget = AimingComp.GetAimingTarget(DropShipComp.CurrentDropShip).AutoAimTargetPoint;

				DropShipComp.CurrentDropShip.Shoot(ShootTarget);

				if (CurForcefeedbackCooldown >= ForceFeedbackCooldown)
				{
					CurForcefeedbackCooldown = 0.0;
					Player.PlayForceFeedback(DropShipComp.CurrentDropShip.ShootForceFeedback, false, true, this, 0.5);
					Player.PlayCameraShake(DropShipComp.CurrentDropShip.ShootCamShake, this);

					FHazeCameraImpulse CamImpulse;
					CamImpulse.CameraSpaceImpulse = FVector(-100.0, 0.0, 0.0);
					CamImpulse.Dampening = 0.8;
					CamImpulse.ExpirationForce = 100.0;
					Player.ApplyCameraImpulse(CamImpulse, this);
				}
			}

			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(ActiveDuration * 2.0) * 0.1;
			FF.RightMotor = Math::Sin(-ActiveDuration * 2.0) * 0.1;
			Player.SetFrameForceFeedback(FF);

			if (Crosshair != nullptr)
				Crosshair.bIsShooting = true;
		}
		else
		{
			CurShotCooldown = 0.0;
			CurForcefeedbackCooldown = 0.0;

			if (Crosshair != nullptr)
				Crosshair.bIsShooting = false;
		}
	}

	void StartFlying()
	{
		bFlying = true;

		if (!DropShipComp.CurrentDropShip.bSnapActivated)
		{	
			Player.ActivateCamera(DropShipComp.CurrentDropShip.Turret.CameraComp, 1.0, this);

			Player.ApplySettings(DropShipComp.PlayerAimingSettings, this);
			AimingComp.StartAiming(DropShipComp.CurrentDropShip, DropShipComp.AimingSettings);
			Crosshair = Cast<UControllableDropShipCrosshair>(AimingComp.GetCrosshairWidget(DropShipComp.CurrentDropShip));
		}

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.Text = NSLOCTEXT("ControllableShip", "ShootPrompt", "Shoot");
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, DropShipComp.CurrentDropShip.Turret.ShootTutorialAttachComp, FVector::ZeroVector, 0.0);
	}
}