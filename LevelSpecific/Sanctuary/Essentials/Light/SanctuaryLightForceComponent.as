class USanctuaryLightForceComponent : UFauxPhysicsForceComponent
{
	default bWorldSpace = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto LightBirdResponseComp = ULightBirdResponseComponent::Get(Owner);
		if (LightBirdResponseComp != nullptr)
		{
			LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
			LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		}
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		Force *= -1.0; 
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		Force *= -1.0; 
	}
};