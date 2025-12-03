class ASanctuaryUnseenSafeZone : APlayerTrigger
{
	UPROPERTY(DefaultComponent)
	UPointLightComponent PointLight;
	default PointLight.SetIntensity(1000.0);
	default PointLight.SetAttenuationRadius(500.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto GentComp = UGentlemanComponent::GetOrCreate(Player);
		GentComp.SetInvalidTarget(this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto GentComp = UGentlemanComponent::GetOrCreate(Player);
		GentComp.ClearInvalidTarget(this);
	}
}