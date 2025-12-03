class USanctuaryGhostDamageComponent : UActorComponent
{
	AHazeActor HazeOwner;
	AHazeActor DamagingLightBird;
	bool bGrabbed = false;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);

		auto LightBirdResponseComp = ULightBirdResponseComponent::Get(Owner);
		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

		auto DarkPortalResponseComp = UDarkPortalResponseComponent::Get(Owner);
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"OnReleased");
		DarkPortalResponseComp.OnAttached.AddUFunction(this, n"OnAttached");
		DarkPortalResponseComp.OnDetached.AddUFunction(this, n"OnDetached");

		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void OnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bGrabbed = true;
	}

	UFUNCTION()
	private void OnReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bGrabbed = false;
	}

	UFUNCTION()
	private void OnDetached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		bGrabbed = false;
	}

	UFUNCTION()
	private void OnAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		bGrabbed = true;
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		if(!bGrabbed) return;
		USanctuaryGhostCommonEventHandler::Trigger_OnLightDamageStart(HazeOwner);
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		DamagingLightBird = nullptr;
		USanctuaryGhostCommonEventHandler::Trigger_OnLightDamageStop(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DamagingLightBird == nullptr) 
			return;

		// TODO: Need networking
		HealthComp.TakeDamage(0.05, EDamageType::Light, Game::Mio);
	}
}