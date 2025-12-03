class UTundra_River_WaterslideLaunch_PlayerComponent : UActorComponent
{
	bool bIsBlockActive = false;

	float BlockTimer = 0;
	float MaxBlockTime = 2;

	bool bDebug = false;

	UPROPERTY()
	bool bStartedAtTop = false;

	UPROPERTY()
	UForceFeedbackEffect WaterslideLaunchFF;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> WaterslideLaunchCameraShake;

	UFUNCTION()
	void OnNewLaunchTriggered()
	{
		BlockTimer = MaxBlockTime;
	}
};