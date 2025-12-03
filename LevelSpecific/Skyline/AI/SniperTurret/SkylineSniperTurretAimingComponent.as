class USkylineSniperTurretAimingComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FVector StartWorldPosition;

	UPROPERTY(BlueprintReadOnly)
	FVector EndWorldPosition;

	AHazeActor Sniper;

	FSkylineSniperTurretAimingEventData Data;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Sniper = Cast<AHazeActor>(Owner);
		Data.AimingComponent = this;
	}

	void StartAim()
	{
		USkylineSniperTurretAimingEffectHandler::Trigger_OnStartedAiming(Sniper, Data);
	}

	void SetAim(FVector StartWorldLoc, FVector EndWorldLoc)
	{
		StartWorldPosition = StartWorldLoc;
		EndWorldPosition = EndWorldLoc;
	}

	void DecidedAim()
	{
		USkylineSniperTurretAimingEffectHandler::Trigger_OnDecidedAiming(Sniper, Data);
	}

	void EndAim()
	{
		USkylineSniperTurretAimingEffectHandler::Trigger_OnStoppedAiming(Sniper, Data);
	}
}