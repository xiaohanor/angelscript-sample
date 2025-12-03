class AIslandRiftAudioLevelScriptActor : AAudioLevelScriptActor
{
	UPROPERTY(EditDefaultsOnly)
	TArray<TSoftObjectPtr<AHazeActor>> SpinningDangerSoftObjects1;

	UPROPERTY(EditDefaultsOnly)
	TArray<TSoftObjectPtr<AHazeActor>> SpinningDangerSoftObjects2;

	UFUNCTION(BlueprintEvent)
	void SetupSpinningDangers(TArray<AHazeActor> Group1, TArray<AHazeActor> Group2) {}

	bool bHasFoundSpinningDangers = false;

	private bool CanResolveSpinningDangers()
	{
		for(auto& SoftPtr : SpinningDangerSoftObjects1)
		{
			if(!SoftPtr.IsValid())
				return false;

			auto Actor = SoftPtr.Get();
			if (Actor == nullptr || !Actor.HasActorBegunPlay())
				return false;
		}

		for(auto& SoftPtr : SpinningDangerSoftObjects2)
		{
			if(!SoftPtr.IsValid())
				return false;

			auto Actor = SoftPtr.Get();
			if (Actor == nullptr || !Actor.HasActorBegunPlay())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SpinningDangerSoftObjects1.Num() != 0 && !bHasFoundSpinningDangers)
		{
			bool bCanResolve = CanResolveSpinningDangers();
			if(bCanResolve)
			{
				bHasFoundSpinningDangers = true;

				TArray<AHazeActor> Group1;
				TArray<AHazeActor> Group2;

				for(auto& SoftPtr : SpinningDangerSoftObjects1)
				{
					Group1.Add(SoftPtr.Get());
				}

				for(auto& SoftPtr : SpinningDangerSoftObjects2)
				{
					Group2.Add(SoftPtr.Get());
				}

				SetupSpinningDangers(Group1, Group2);
			}
		}
	}
}
	