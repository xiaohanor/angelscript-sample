class UOtherPlayerIndicatorCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::OtherPlayerIndicator);
	default TickGroup = EHazeTickGroup::Gameplay;

	UOtherPlayerIndicatorWidget Widget;
	UOtherPlayerIndicatorComponent IndicatorComp;
	UOtherPlayerIndicatorComponent IndicatorComp_OtherPlayer;

	UOtherPlayerIndicatorWidget SelfWidget;
	UFadeManagerComponent FadeManager;

	bool bIsLocationOverridden = false;
	FHazeAcceleratedFloat OverrideAttachFraction;
	FVector StartBlendLocation = FVector::ZeroVector;
	FHazeAcceleratedVector OverrideDetachedLocation;

	bool bShowInFullscreen = false;
	
	bool bHasWidgetPosition = false;
	FVector WidgetPosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IndicatorComp = UOtherPlayerIndicatorComponent::Get(Player);
		FadeManager = UFadeManagerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto OtherPlayerComp = UOtherPlayerIndicatorComponent::Get(Player.OtherPlayer);
		if (OtherPlayerComp == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		IndicatorComp_OtherPlayer = UOtherPlayerIndicatorComponent::Get(Player.OtherPlayer);
		Widget = Player.AddWidget(IndicatorComp_OtherPlayer.WidgetClass);

		bHasWidgetPosition = false;
		bIsLocationOverridden = false;
		OverrideAttachFraction.SnapTo(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveWidget(Widget);
		Widget = nullptr;
		
		if (SelfWidget != nullptr)
		{
			Player.RemoveWidget(SelfWidget);
			Widget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector AttachOffset;
		AttachOffset.Z = Player.OtherPlayer.CapsuleComponent.UnscaledCapsuleHalfHeight * 2.f;

		FVector PlayerWidgetPosition = Player.OtherPlayer.Mesh.WorldTransform.TransformPosition(AttachOffset);
		PlayerWidgetPosition += IndicatorComp_OtherPlayer.IndicatorWorldOffset.Get();

		// Move other player marker component to correct location
		if (!IndicatorComp_OtherPlayer.OverrideIndicatorLocation.IsDefaultValue())
		{
			if (!bHasWidgetPosition)
				WidgetPosition = IndicatorComp_OtherPlayer.OverrideIndicatorLocation.Get();

			if (!bIsLocationOverridden)
			{
				// We've just started using override location, detach
				bIsLocationOverridden = true;
				OverrideDetachedLocation.SnapTo(WidgetPosition, Player.OtherPlayer.ActorVelocity);
			}

			// Accelerate in world space in case override location is changing
			OverrideDetachedLocation.AccelerateTo(IndicatorComp_OtherPlayer.OverrideIndicatorLocation.Get(), 0.5, DeltaTime);
			WidgetPosition = OverrideDetachedLocation.Value;
		}
		else
		{
			if (!bHasWidgetPosition)
				WidgetPosition = PlayerWidgetPosition;

			if (bIsLocationOverridden)
			{
				// We've just stopped using override location, attach 
				bIsLocationOverridden = false;
				OverrideAttachFraction.SnapTo(0.f);
				StartBlendLocation = WidgetPosition;
			}

			// Accelerate fraction to ensure we reach player (which may be moving) within given time
			OverrideAttachFraction.AccelerateTo(1.0, 0.5, DeltaTime);
			WidgetPosition = Math::EaseInOut(StartBlendLocation, PlayerWidgetPosition, OverrideAttachFraction.Value, 3.0);
		}

		Widget.IndicatorMode = IndicatorComp.IndicatorMode.Get();
		Widget.IndicatorOpacityMultiplier = IndicatorComp.IndicatorOpacityMultiplier.Get();
		Widget.CurrentDistance = PlayerWidgetPosition.Distance(Player.ActorLocation);
		Widget.bIsFadedOut = FadeManager.CurrentFadeColor.A >= 0.999;
		Widget.SetWidgetWorldPosition(WidgetPosition);

		if (Widget.IndicatorMode == EOtherPlayerIndicatorMode::AlwaysVisibleEvenFullscreen
			|| Widget.IndicatorMode == EOtherPlayerIndicatorMode::DefaultEvenFullscreen)
		{
			if (!bShowInFullscreen)
			{
				Widget.SetWidgetShowInFullscreen(true);
				bShowInFullscreen = true;
			}
		}
		else
		{
			if (bShowInFullscreen)
			{
				Widget.SetWidgetShowInFullscreen(false);
				bShowInFullscreen = false;
			}
		}

		bHasWidgetPosition = true;

		if (IndicatorComp.IndicatorMode.Get() == EOtherPlayerIndicatorMode::AlwaysVisibleBothPlayers)
		{
			if (SelfWidget == nullptr)
			{
				SelfWidget = Player.AddWidget(IndicatorComp.WidgetClass);
				SelfWidget.OverrideWidgetPlayer(Player.OtherPlayer);
				SelfWidget.UpdateColor();
			}

			SelfWidget.IndicatorMode = IndicatorComp.IndicatorMode.Get();
			SelfWidget.IndicatorOpacityMultiplier = IndicatorComp.IndicatorOpacityMultiplier.Get();
			SelfWidget.CurrentDistance = 0.0;

			FVector SelfAttachOffset;
			SelfAttachOffset.Z = Player.CapsuleComponent.UnscaledCapsuleHalfHeight * 2.f;

			FVector SelfWidgetPosition = Player.Mesh.WorldTransform.TransformPosition(AttachOffset);
			SelfWidget.SetWidgetWorldPosition(SelfWidgetPosition);
		}
		else
		{
			if (SelfWidget != nullptr)
			{
				Player.RemoveWidget(SelfWidget);
				SelfWidget = nullptr;
			}
		}
	}
};