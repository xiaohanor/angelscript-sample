class ABattlefieldIceSpikeObjectMove : ABattlefieldTriggerableObjectMove
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnBattlefieldObjectMoveStarted.AddUFunction(this, n"OnBattlefieldObjectMoveStarted");
		OnBattlefieldObjectMoveFinished.AddUFunction(this, n"OnBattlefieldObjectMoveFinished");
		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
	}

	UFUNCTION()
	private void OnBattlefieldObjectMoveStarted()
	{
		FBattlefieldIceSpikeBreakOffParams Params;
		Params.Location = ActorLocation;
		UBattlefieldIceSpikeEffectHandler::Trigger_OnIceSpikeBreak(this, Params);
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	private void OnBattlefieldObjectMoveFinished()
	{
		FBattlefieldIceSpikeImpactParams Params;
		Params.Location = ActorLocation - FVector::UpVector * 1000.0;
		UBattlefieldIceSpikeEffectHandler::Trigger_OnIceSpikeImpact(this, Params);
	}
}