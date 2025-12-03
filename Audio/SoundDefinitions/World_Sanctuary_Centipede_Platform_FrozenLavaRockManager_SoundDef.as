
UCLASS(Abstract)
class UWorld_Sanctuary_Centipede_Platform_FrozenLavaRockManager_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFullyMelted(FSanctuaryFrozenLavaRockManagerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStartMelt(FSanctuaryFrozenLavaRockManagerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnReFreeze(FSanctuaryFrozenLavaRockManagerEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStartFreeze(FSanctuaryFrozenLavaRockManagerEventParams Params){}

	/* END OF AUTO-GENERATED CODE */

	USanctuaryCentipedeLavaRockManagerComponent ManagerComp;
	private TArray<FAkSoundPosition> FrozenRockSoundPositions;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ManagerComp = SanctuaryCentipedeLavaRock::GetManager();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Has Frozen Rocks"))
	bool HasFrozenRocks()
	{
		return ManagerComp.GetFrozenRocks().Num() > 1;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Frozen Rocks In Range"))
	int FrozenRocksInRange(float Range = 2500)
	{
		int RocksInRange = 0;
		float RangeSqrd = Math::Square(Range);
		for(auto Rock : ManagerComp.GetFrozenRocks())
		{
			if(Rock.ActorLocation.DistSquared(Game::GetMio().ActorLocation) <= RangeSqrd)			
				++RocksInRange;			
		}
		PrintToScreenScaled(""+RocksInRange);
		return RocksInRange;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<ASanctuaryCentipedeFrozenLavaRock> FrozenRocks = ManagerComp.GetFrozenRocks();
		if(!FrozenRocks.IsEmpty())
		{
			FrozenRockSoundPositions.SetNum(FrozenRocks.Num());

			for(int i = 0; i < FrozenRocks.Num(); ++i)
			{
				auto Rock = FrozenRocks[i];
				FrozenRockSoundPositions[i].SetPosition(Rock.ActorLocation);
			}

			DefaultEmitter.SetMultiplePositions(FrozenRockSoundPositions);
		}
	}
}