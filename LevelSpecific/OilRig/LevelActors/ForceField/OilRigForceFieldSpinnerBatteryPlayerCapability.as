class UOilRigForceFieldSpinnerBatteryPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UOilRigForceFieldSpinnerBatteryPlayerComponent PlayerComp;
	AOilRigForceFieldSpinnerBattery Battery;

	bool bBatteryGrabbed = false;
	bool bExiting = false;
	bool bExitFinished = false;
	float ExitStartTime = 0.0;

	float ExitDuration = 1.0;

	bool bCancelled = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UOilRigForceFieldSpinnerBatteryPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerComp.Battery == nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerComp.Battery == nullptr)
			return true;

		if (bExitFinished)
			return true;

		if (Battery.bBroken)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		bBatteryGrabbed = false;
		bExitFinished = false;
		bExiting = false;
		ExitStartTime = 0.0;
		bCancelled = false;

		Battery = Cast<AOilRigForceFieldSpinnerBattery>(PlayerComp.Battery);
		Battery.InteractingPlayer = Player;

		Player.SetAnimFloatParam(n"ForceFieldSpinnerBatteryProgress", 0.0);

		Player.AddLocomotionFeature(
			Player == Game::Mio ? Battery.FeatureMio : Battery.FeatureZoe,
			 this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		bBatteryGrabbed = false;

		if (!bCancelled)
		{
			Player.StopButtonMash(this);
			Player.RemoveCancelPromptByInstigator(this);
			Battery.ReleaseBattery();
		}

		if (Battery.bBroken)
		{
			Player.ApplyKnockdown(-Battery.ActorForwardVector * 200.0, 2.0);
		}

		Player.RemoveLocomotionFeature(
			Player == Game::Mio ? Battery.FeatureMio : Battery.FeatureZoe,
			 this);

		Battery.InteractionStopped();

		PlayerComp.Battery = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bExiting)
		{
			if (ActiveDuration >= ExitStartTime + ExitDuration)
				bExitFinished = true;

			return;
		}

		Player.RequestLocomotion(n"ForceFieldSpinnerBattery", this);

		if (!bBatteryGrabbed)
		{
			if (ActiveDuration >= 0.8)
				GrabBattery();
			else
				return;
		}

		if (WasActionStarted(ActionNames::Cancel))
		{
			Cancelled();
			return;
		}

		float MashAlpha = Player.GetButtonMashProgress(this);

		float LeftFF = Math::Sin(ActiveDuration * 50.0) * 0.3 * MashAlpha;
		float RightFF = Math::Sin(-ActiveDuration * 50.0) * 0.3 * MashAlpha;
		Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);

		Player.SetAnimFloatParam(n"ForceFieldSpinnerBatteryProgress", MashAlpha);
	}

	void GrabBattery()
	{
		Battery.BatteryRoot.AttachToComponent(Player.Mesh, n"Align", EAttachmentRule::KeepWorld);

		FButtonMashSettings MashSettings;
		MashSettings.Duration = 1.0;
		MashSettings.WidgetAttachComponent = Battery.ButtonMashAttachmentComp;
		MashSettings.Mode = EButtonMashMode::ButtonHold;
		Player.StartButtonMash(MashSettings, this);
		Player.SetButtonMashAllowCompletion(this, false);

		bBatteryGrabbed = true;

		Player.ShowCancelPrompt(this);
	}

	void Cancelled()
	{
		CrumbCancelled();
	}

	UFUNCTION(CrumbFunction)
	void CrumbCancelled()
	{
		if (bCancelled)
			return;

		bCancelled = true;
		Player.StopButtonMash(this);
		Player.RemoveCancelPromptByInstigator(this);

		ExitStartTime = ActiveDuration;
		bExiting = true;

		Battery.ReleaseBattery();
	}
}