class UPlayerFireworkLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerFireworksComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UPlayerFireworksComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.FireworkRocket == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
			return true;

		if (UserComp.FireworkRocket == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::PrimaryLevelAbility;
		Prompt.Text = NSLOCTEXT("MoonMarketFireworks", "FireworkPrimary", "Launch");
		Prompt.DisplayType = ETutorialPromptDisplay::Action;

		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.ShowTutorialPrompt(Prompt, this);
		Player.EnableStrafe(this);
		
		AimComp = UPlayerAimingComponent::Get(Player);

		FAimingSettings AimSettings;
		AimSettings.bApplyAimingSensitivity = false;
		AimSettings.bShowCrosshair = true;
		AimSettings.bUseAutoAim = false;
		AimSettings.bCrosshairFollowsTarget = false;
		AimComp.StartAiming(this, AimSettings);

		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), UserComp.AimAnim, UserComp.BoneFilter, bLoop = true);

		Player.ApplyCameraSettings(UserComp.CameraSettings, 1.5, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (UserComp.FireworkRocket != nullptr)
		{
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.UseLine();
			TraceSettings.IgnoreActor(Player);

			const FVector Start = Player.ViewLocation + Player.ViewRotation.ForwardVector * 500;
			const FVector End = Start + Player.ViewRotation.ForwardVector * 1000000;
			FHitResult ForwardHit = TraceSettings.QueryTraceSingle(Start, End);

			if(ForwardHit.bBlockingHit)
			{
				//Debug::DrawDebugPoint(ForwardHit.ImpactPoint, 10);
				FVector DirToHit = (ForwardHit.ImpactPoint - UserComp.FireworkRocket.ActorLocation).GetSafeNormal();
				//float Length = (ForwardHit.ImpactPoint - UserComp.FireworkRocket.ActorLocation).Size();
				//Debug::DrawDebugLine(UserComp.FireworkRocket.ActorLocation, UserComp.FireworkRocket.ActorLocation + DirToHit * Length, FLinearColor::Green, Duration = 10);
				UserComp.LaunchFirework(DirToHit);
			}
			else
			{
				//Debug::DrawDebugLine(UserComp.FireworkRocket.ActorLocation, UserComp.FireworkRocket.ActorLocation + Player.ViewRotation.ForwardVector * 10000, FLinearColor::Green, Duration = 10);
				UserComp.LaunchFirework(Player.ViewRotation.ForwardVector);
			}
		}

		Player.ClearCameraSettingsByInstigator(this, 3.0);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.StopOverrideAnimation(UserComp.AimAnim);
		Player.RemoveTutorialPromptByInstigator(this);
		Player.DisableStrafe(this);
		UPlayerAimingComponent::Get(Player).StopAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};