class ACellEjectionManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor SequenceActor;
	float TimeRemainingWhenEjected = 0.0;

	UFUNCTION()
	void PlayersApproach()
	{
		UCellEjectionEffectEventHandler::Trigger_PlayersApproach(this);
	}

	UFUNCTION()
	void PlayersLeave()
	{
		UCellEjectionEffectEventHandler::Trigger_PlayersLeave(this);
	}

	UFUNCTION()
	void Eject()
	{
		UCellEjectionEffectEventHandler::Trigger_Ejected(this);
	}

	UFUNCTION()
	void StopSequence()
	{
		TimeRemainingWhenEjected = SequenceActor.TimeRemaining;
	}

	UFUNCTION(BlueprintPure)
	float GetSequenceTime()
	{
		return SequenceActor.DurationAsSeconds - TimeRemainingWhenEjected;
	}
}