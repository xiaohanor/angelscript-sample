
class UPlayerHealthDisplayCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"HealthDisplay");
	default DebugCategory = n"PlayerHealth";

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	UPlayerHealthComponent HealthComp;
	UPlayerHealthSettings HealthSettings;
	UPlayerHealthOverlayWidget HealthOverlay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UPlayerHealthComponent::Get(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HealthComp.bIsDead)
			return false;
		if (!HealthSettings.bDisplayHealth)
			return false;
		if (!HealthSettings.bDisplayHealthWhenFullHealth && HealthComp.Health.GetDisplayHealth() >= 1.0)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HealthComp.bIsDead)
			return true;
		if (!HealthSettings.bDisplayHealth)
			return true;
		if (!HealthSettings.bDisplayHealthWhenFullHealth && HealthComp.Health.GetDisplayHealth() >= 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthOverlay = Cast<UPlayerHealthOverlayWidget>(
			Widget::AddFullscreenWidget(HealthComp.HealthOverlayWidget)
		);
		HealthOverlay.OverrideWidgetPlayer(Player);
		HealthOverlay.UpdateWheelPosition();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HealthOverlay != nullptr)
		{
			Widget::RemoveFullscreenWidget(HealthOverlay);
			HealthOverlay = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HealthOverlay != nullptr)
		{
			// Update health value in the health wheel
			HealthOverlay.HealthWheel.Health = HealthComp.Health;

			// When the player's view is fading out, we also fade out the health overlay
			HealthOverlay.SetColorAndOpacity(FLinearColor(1.0, 1.0, 1.0, 1.0 - Player.GetFadeOutPercentage()));
		}
	}
};