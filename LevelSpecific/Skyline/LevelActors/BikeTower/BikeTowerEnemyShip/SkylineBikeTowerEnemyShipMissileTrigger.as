class ASkylineBikeTowerEnemyShipMissileTrigger : APlayerTrigger
{
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditAnywhere)
	ASkylineBikeTowerEnemyShip EnemyShip;

	UPROPERTY(EditAnywhere)
	TArray<float> LaunchTimes;

	UPROPERTY(EditAnywhere)
	TArray<float> ImpactTimes;

	UPROPERTY(EditAnywhere)
	TArray<AActor> Targets;

	bool bHasTriggered = false;

	default BrushColor = FLinearColor::DPink;
	default BrushComponent.LineThickness = 10.0;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		if (bHasTriggered)
			return;

		bHasTriggered = true;

		Super::TriggerOnPlayerEnter(Player);

		for (auto LaunchTime : LaunchTimes)
		{
			QueueComp.Idle(LaunchTime);
			QueueComp.Event(this, n"LaunchMissile");
		}
	}

	UFUNCTION()
	private void LaunchMissile()
	{
		if (!IsValid(EnemyShip) || EnemyShip.IsActorDisabled())
			return;

		if (Targets.Num() == 0)
			return;

		LaunchTimes.RemoveAt(0);

		EnemyShip.LaunchMissileAtTarget(Targets[0], ImpactTimes[0]);
		if (Targets.Num() > 1)
			Targets.RemoveAt(0);

		if (ImpactTimes.Num() > 1)
			ImpactTimes.RemoveAt(0);
	}
};