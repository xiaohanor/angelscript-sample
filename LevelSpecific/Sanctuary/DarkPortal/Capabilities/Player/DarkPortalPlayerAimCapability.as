class UDarkPortalPlayerAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalAim);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UDarkPortalUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	AHazeNiagaraActor SurfaceIndicator;
	UHazeUserWidget IndicatorWidget;
	float LastActivationTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkPortalUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSinceActivation = Time::GetRealTimeSince(LastActivationTime);
		if (TimeSinceActivation > 0.33 || LastActivationTime == 0.0)
		{
			if (IsActioning(ActionNames::PrimaryLevelAbility))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastActivationTime = Time::RealTimeSeconds;

		if (UserComp.IndicatorEffect != nullptr)
		{
			SurfaceIndicator = AHazeNiagaraActor::Spawn();
			SurfaceIndicator.NiagaraComponent0.Asset = UserComp.IndicatorEffect;
			SurfaceIndicator.NiagaraComponent0.WorldScale3D = FVector::OneVector * 0.25;
			SurfaceIndicator.SetActorHiddenInGame(true);
			SurfaceIndicator.NiagaraComponent0.SetRenderedForPlayer(Game::Mio, UserComp.bShowAimForOtherPlayer);
		}

		FAimingSettings AimSettings;
		if (TargetablesComp.TargetingMode.Get() == EPlayerTargetingMode::ThirdPerson)
			AimSettings.bShowCrosshair = true;
		AimSettings.bUseAutoAim = true;
		AimSettings.bCrosshairFollowsTarget = false;
		AimSettings.CrosshairLingerDuration = 0.5;
		AimSettings.OverrideAutoAimTarget = UDarkPortalAutoAimComponent;
		AimSettings.OverrideCrosshairWidget = UserComp.CrosshairWidgetClass;

		UserComp.AnimationData.bIsAiming = true;

		if (UserComp.CameraAimSettings != nullptr)
			Player.ApplyCameraSettings(UserComp.CameraAimSettings, 0.8, this, EHazeCameraPriority::Low);

		AimComp.StartAiming(UserComp, AimSettings);
		UDarkPortalPlayerEventHandler::Trigger_AimingStarted(Player);
		UDarkPortalEventHandler::Trigger_PlayerAimStart(UserComp.Companion);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (SurfaceIndicator != nullptr)
		{
			SurfaceIndicator.DestroyActor();
			SurfaceIndicator = nullptr;
		}

		if (IndicatorWidget != nullptr)
		{
			Player.RemoveWidget(IndicatorWidget);
			IndicatorWidget = nullptr;
		}

		Player.ClearCameraSettingsByInstigator(this, 1.0);

		AimComp.StopAiming(UserComp);

		UserComp.AnimationData.bIsAiming = false;
		UserComp.LastAimStartTime = Time::GameTimeSeconds;

		UDarkPortalPlayerEventHandler::Trigger_AimingStopped(Player);
		UDarkPortalEventHandler::Trigger_PlayerAimStop(UserComp.Companion);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto AimingTarget = AimComp.GetAimingTarget(UserComp);

		// If the portal at any point attaches during aiming, recall it immediately
		if (Portal.IsSettled())
			Portal.Recall();

		FDarkPortalTargetData TargetData;
		if (TargetablesComp.TargetingMode.Get() == EPlayerTargetingMode::ThirdPerson)
		{
			FVector AimStart = AimingTarget.AimOrigin;
			
			// Don't allow the player to hit or aim at things behind them, even if they are in front of the camera
			FVector ClosestPlayerLocation;
			Player.CapsuleComponent.GetClosestPointOnCollision(AimingTarget.AimOrigin, ClosestPlayerLocation);

			float PlayerOffset = (ClosestPlayerLocation - AimingTarget.AimOrigin).DotProduct(AimingTarget.AimDirection);
			PlayerOffset = Math::Clamp(PlayerOffset, 0, (UserComp.bUseBoatAimingRange ? 4000.0 : DarkPortal::Aim::Range) - 1.0);
			AimStart += AimingTarget.AimDirection * PlayerOffset;

			TargetData = Portal.GetTargetDataFromTrace(AimStart, AimingTarget.AimOrigin + AimingTarget.AimDirection * (UserComp.bUseBoatAimingRange ? 4000.0 : DarkPortal::Aim::Range));
		}
		else
		{
			if (AimingTarget.AutoAimTarget != nullptr)
			{
				// TODO: Find normal by tracing from location downwards (comp space) with offest
				TargetData = FDarkPortalTargetData(
					AimingTarget.AutoAimTarget,
					NAME_None,
					AimingTarget.AutoAimTargetPoint,
					AimingTarget.AutoAimTarget.ForwardVector
				);
			}
		}

		if (SurfaceIndicator != nullptr)
		{
			if (TargetData.IsValid() && !Portal.IsSettled())
			{
				SurfaceIndicator.SetActorLocationAndRotation(
					TargetData.WorldLocation,
					FRotator::MakeFromX(TargetData.WorldNormal)
				);
				SurfaceIndicator.SetActorHiddenInGame(false);
			}
			else
			{
				SurfaceIndicator.SetActorHiddenInGame(true);
			}
		}

		if (TargetData.IsValid() && !Portal.IsSettled() && SceneView::IsFullScreen())
		{
			if (IndicatorWidget == nullptr)
			{
				if (UserComp.IndicatorWidget.IsValid())
				{
					IndicatorWidget = Player.AddWidget(UserComp.IndicatorWidget);
				}
			}

			if (IndicatorWidget != nullptr)
			{
				IndicatorWidget.AttachWidgetToComponent(TargetData.SceneComponent);
				IndicatorWidget.SetWidgetRelativeAttachOffset(TargetData.SceneComponent.WorldTransform.InverseTransformPosition(TargetData.WorldLocation));
				IndicatorWidget.SetWidgetShowInFullscreen(true);
			}
		}
		else
		{
			if (IndicatorWidget != nullptr)
			{
				Player.RemoveWidget(IndicatorWidget);
				IndicatorWidget = nullptr;
			}
		}

		UserComp.AimTargetData = TargetData;
	}

	ADarkPortalActor GetPortal() const property
	{
		return UserComp.Portal;
	}
}