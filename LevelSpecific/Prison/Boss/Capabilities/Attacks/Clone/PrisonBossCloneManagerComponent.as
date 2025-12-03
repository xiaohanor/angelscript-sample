class UPrisonBossCloneManagerComponent : UActorComponent
{
	APrisonBoss Boss;
	TArray<APrisonBossClone> Clones;
	TArray<APrisonBossClone> RemainingClones;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<APrisonBoss>(Owner);
	}
	void SpawnClone(FVector Loc, FRotator Rot, bool bFinalClone)
	{
		APrisonBossClone Clone = SpawnActor(Boss.AttackDataComp.CloneClass, Loc, Rot);
		Clone.Spawn(bFinalClone);
		Clone.Boss = Boss;
		Clones.Add(Clone);
		RemainingClones.Add(Clone);
	}

	void TriggerCloneAttack(FRandomStream RandomStream)
	{
		int CloneIndex = RandomStream.RandRange(0, RemainingClones.Num() - 1);
		RemainingClones[CloneIndex].Attack();
		RemainingClones.RemoveAt(CloneIndex);
	}

	void DeleteClones()
	{
		for (APrisonBossClone Clone : RemainingClones)
		{
			Clone.DestroyClone();
		}

		Clones.Empty();
		RemainingClones.Empty();
	}
}