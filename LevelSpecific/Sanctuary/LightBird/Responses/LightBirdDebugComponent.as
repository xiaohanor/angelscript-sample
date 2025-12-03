class ULightBirdDebugComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

 	private ULightBirdResponseComponent ResponseComponent;
 	private ULightBirdChargeComponent ChargeComponent;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComponent = ULightBirdResponseComponent::GetOrCreate(Owner);
		ResponseComponent.OnAttached.AddUFunction(this, n"HandleAttached");
		ResponseComponent.OnDetached.AddUFunction(this, n"HandleDetached");
		ResponseComponent.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		ResponseComponent.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");

		ChargeComponent = ULightBirdChargeComponent::Get(Owner);
		if (ChargeComponent != nullptr)
		{
			ChargeComponent.OnFullyCharged.AddUFunction(this, n"HandleFullyCharged");
			ChargeComponent.OnChargeDepleted.AddUFunction(this, n"HandleChargeDepleted");
		}
	}

	UFUNCTION()
	private void HandleAttached()
	{
		Print(f"Attached: {Owner.Name}");
	}

	UFUNCTION()
	private void HandleDetached()
	{
		Print(f"Detached: {Owner.Name}");
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		Print(f"Illuminated: {Owner.Name}");
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		Print(f"Unilluminated: {Owner.Name}");
	}
	
	UFUNCTION()
	private void HandleFullyCharged()
	{
		Print(f"Fully Charged: {Owner.Name} ({ChargeComponent.ChargeTime} / {ChargeComponent.ChargeDuration})");
	}

	UFUNCTION()
	private void HandleChargeDepleted()
	{
		Print(f"Charge Depleted: {Owner.Name} ({ChargeComponent.ChargeTime} / {ChargeComponent.ChargeDuration})");
	}
#endif
}