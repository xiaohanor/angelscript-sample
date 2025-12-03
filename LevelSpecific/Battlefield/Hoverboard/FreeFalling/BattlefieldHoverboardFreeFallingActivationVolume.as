class ABattlefieldHoverboardFreeFallingActivationVolume : APlayerTrigger
{
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"BattlefieldHoverboardFreeFallingCapability");
	default RequestComp.PlayerCapabilities.Add(n"BattlefieldHoverboardFreeFallingCameraCapability");

	UPROPERTY(DefaultComponent)
	USceneComponent FreeFallOrientation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto FreeFallComp = UBattlefieldHoverboardFreeFallingComponent::GetOrCreate(Player);
		FreeFallComp.bShouldFreeFall = true;
		FreeFallComp.Volume = this;
		FreeFallComp.bIsApproachingGround = false;
	}
};