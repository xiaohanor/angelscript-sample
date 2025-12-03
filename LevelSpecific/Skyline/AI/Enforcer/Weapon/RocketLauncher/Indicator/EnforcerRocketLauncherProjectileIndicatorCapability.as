class UEnforcerRocketLauncherProjectileIndicatorCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::OtherPlayerIndicator);
	default TickGroup = EHazeTickGroup::Gameplay;

	UEnforcerRocketLauncherProjectileIndicatorComponent IndicatorComp;

	FHazeAcceleratedFloat OverrideAttachFraction;
	FVector StartBlendLocation = FVector::ZeroVector;
	
	bool bHasWidgetPosition = false;
	FVector WidgetPosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IndicatorComp = UEnforcerRocketLauncherProjectileIndicatorComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(IndicatorComp.Widgets.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(IndicatorComp.Widgets.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasWidgetPosition = false;
		OverrideAttachFraction.SnapTo(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(FEnforcerRocketLauncherProjectileIndicatorWidgetData Widget : IndicatorComp.Widgets)
			UpdateWidget(DeltaTime, Widget);
	}

	void UpdateWidget(float DeltaTime, FEnforcerRocketLauncherProjectileIndicatorWidgetData WidgetData)
	{
		FVector PlayerWidgetPosition = Owner.ActorLocation;

		// Move other player marker component to correct location
		if (!bHasWidgetPosition)
			WidgetPosition = PlayerWidgetPosition;

		// Accelerate fraction to ensure we reach player (which may be moving) within given time
		OverrideAttachFraction.AccelerateTo(1.0, 0.5, DeltaTime);
		WidgetPosition = Math::EaseInOut(StartBlendLocation, PlayerWidgetPosition, OverrideAttachFraction.Value, 3.0);

		WidgetData.Widget.SetWidgetWorldPosition(WidgetPosition);
		bHasWidgetPosition = true;
	}
};