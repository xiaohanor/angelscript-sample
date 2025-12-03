struct FCrystalSiegeLineAttackData
{
	UPROPERTY()
	float ForwardAmount = 100.0;
	UPROPERTY()
	float ForwardOffset;
	UPROPERTY()
	bool bInstantSpawnAll = false;
	UPROPERTY(meta = (EditCondition="!bInstantSpawnAll", EditConditionHides))
	float FireRate = 0.05;
	float FireTime;
	UPROPERTY()
	int MaxFires = 10;
	int CurrentFires;
}

class ACrystalSiegeLineAttackActor : ACrystalSiegeGroundAttackActor
{
	UPROPERTY(EditAnywhere)
	FCrystalSiegeLineAttackData CurrentAttackData;

	TArray<FCrystalSiegeLineAttackData> RunningAttacks;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TArray<FCrystalSiegeLineAttackData> DataToRemove;

		for (FCrystalSiegeLineAttackData& AttackData : RunningAttacks)
		{
			if (!AttackData.bInstantSpawnAll)
			{
				while(Time::GameTimeSeconds > AttackData.FireTime)
				{
					AttackData.FireTime += AttackData.FireRate;
					AttackData.ForwardOffset += AttackData.ForwardAmount;
					AttackData.CurrentFires++;
					RunSpawnLogic(AttackData);
				}

				if (SplineActor != nullptr && AttackData.ForwardOffset >= SplineActor.Spline.SplineLength)
				{
					DataToRemove.Add(AttackData);
				}
				else if (AttackData.CurrentFires >= AttackData.MaxFires)
				{
					DataToRemove.Add(AttackData);
				}
			}
			else
			{
				if (Time::GameTimeSeconds > AttackData.FireTime)
				{
					if (SplineActor != nullptr)
					{
						for (float f = 0; f < SplineActor.Spline.SplineLength; f += AttackData.ForwardAmount)
						{
							AttackData.ForwardOffset += AttackData.ForwardAmount;
							RunSpawnLogic(AttackData);
						}
					}
					else
					{
						for (int i = 0; i < AttackData.MaxFires - 1; i++)
						{
							AttackData.ForwardOffset += AttackData.ForwardAmount;
							AttackData.CurrentFires++;
							RunSpawnLogic(AttackData);
						}
					}

					DataToRemove.Add(AttackData);
				}
			}
		}

		if (DataToRemove.Num() > 0)
		{
			for (FCrystalSiegeLineAttackData& Data : DataToRemove)
			{
				RunningAttacks.Remove(Data);
			}
		}
	}

	void FireAttack(float DelayTime = 0.0) override
	{
		Super::FireAttack(DelayTime);

		FCrystalSiegeLineAttackData NewAttack = CurrentAttackData;
		NewAttack.FireTime = Time::GameTimeSeconds + DelayTime;
		RunningAttacks.Add(NewAttack);
	}

	void RunSpawnLogic(FCrystalSiegeLineAttackData AttackData)
	{
		FVector SpawnLoc;
		if (SplineActor != nullptr)
			SpawnLoc = SplineActor.Spline.GetWorldLocationAtSplineDistance(AttackData.ForwardOffset);
		else	
			SpawnLoc = ActorLocation + ActorForwardVector * AttackData.ForwardOffset;
		SpawnCrystalSpike(SpawnLoc, ActorRotation);
	}
};