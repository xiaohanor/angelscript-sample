class USkylineSniperAimingComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FVector EndWorldPosition;

	AHazeActor Sniper;

	FSkylineSniperAimingEventData Data;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Sniper = Cast<AHazeActor>(Owner);
		Data.AimingComponent = this;
	}

	void StartAim()
	{
		USkylineSniperAimingEffectHandler::Trigger_OnStartedAiming(Sniper, Data);
	}

	void SetAim(FVector InWorldLocation)
	{
		EndWorldPosition = InWorldLocation;
	}

	void DecidedAim()
	{
		USkylineSniperAimingEffectHandler::Trigger_OnDecidedAiming(Sniper, Data);
	}

	void EndAim()
	{
		USkylineSniperAimingEffectHandler::Trigger_OnStoppedAiming(Sniper, Data);
	}
}