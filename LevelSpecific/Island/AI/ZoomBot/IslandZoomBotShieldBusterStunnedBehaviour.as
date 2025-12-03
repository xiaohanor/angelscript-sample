class UIslandZoomBotShieldBusterStunnedBehaviour : UBasicBehaviour
{
	UIslandZoomBotSettings ZoomBotSettings;
	FRotator Rotation;
	bool bStunned;

	UIslandNunchuckTargetableComponent TargetComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		TargetComponent = UIslandNunchuckTargetableComponent::Get(Owner);
		TargetComponent.Disable(this);

		ZoomBotSettings = UIslandZoomBotSettings::GetSettings(Owner);
		auto ShieldBusterComp = UScifiShieldBusterImpactResponseComponent::Get(Owner);
		ShieldBusterComp.OnImpact.AddUFunction(this, n"OnImpact");
	}

	UFUNCTION()
	private void OnImpact(AHazePlayerCharacter ImpactInstigator,
	                      UScifiShieldBusterTargetableComponent Component)
	{
		// This is crumbed, so the rest can be run locally
		bStunned = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bStunned)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > ZoomBotSettings.ShieldBusterStunTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bStunned = false;
		Rotation.Yaw = 0;
		UIslandZoomBotEffectHandler::Trigger_OnShieldBusterStunnedStart(Owner);
		TargetComponent.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandZoomBotEffectHandler::Trigger_OnShieldBusterStunnedEnd(Owner);
		TargetComponent.Disable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Rotation.Yaw += DeltaTime * 700;
		DestinationComp.RotateInDirection(Rotation.ForwardVector);
	}
}