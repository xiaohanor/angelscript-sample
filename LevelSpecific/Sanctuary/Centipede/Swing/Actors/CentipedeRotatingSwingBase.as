event void FCentipedeSwingJumpToEnabledSignature(bool bEnabled);

class ACentipedeRotatingSwingBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	ACentipedeRotatingSwingBase NextWheel;

	UPROPERTY()
	FCentipedeSwingJumpToEnabledSignature SetJumpToEnabled;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;
	default DisableComponent.SetEnableAutoDisable(true);
	default DisableComponent.AutoDisableRange = 10000;

	UFUNCTION()
	void CentipedeAttached()
	{
		SetJumpToEnabled.Broadcast(false);

		if (NextWheel != nullptr)
			NextWheel.EnableJumpAutoTargeting();
	}

	UFUNCTION()
	void EnableJumpAutoTargeting()
	{
		SetJumpToEnabled.Broadcast(true);
	}
};