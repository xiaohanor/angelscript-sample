class AIslandTowerAudioLevelScriptActor : AAudioLevelScriptActor
{
	UPROPERTY(EditDefaultsOnly)
	TArray<TSoftObjectPtr<AHazeActor>> SpinningDangerSoftObjects;

	UFUNCTION(BlueprintEvent)
	void SetupSpinningDangers(TArray<AHazeActor> SpinningDangers) {};

	bool bHasFoundSpinningDangers = false;

	UPROPERTY(EditAnywhere)
	UHazeAudioAuxBus SagePovAuxBus = nullptr;

	UFUNCTION(BlueprintPure)
	UHazeAudioAuxBus GetProxyPlatformOverride(UHazeAudioAuxBus Default) const
	{
		if (Game::IsPlatformSage())
			return SagePovAuxBus;

		return Default;
	}

	private bool CanResolveSpinningDangers()
	{
		for(auto& SoftPtr : SpinningDangerSoftObjects)
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
		if(SpinningDangerSoftObjects.Num() != 0 && !bHasFoundSpinningDangers)
		{
			bool bCanResolve = CanResolveSpinningDangers();
			if(bCanResolve)
			{
				bHasFoundSpinningDangers = true;

				TArray<AHazeActor> SpinningDangers;		

				for(auto& SoftPtr : SpinningDangerSoftObjects)
				{
					SpinningDangers.Add(SoftPtr.Get());
				}			

				SetupSpinningDangers(SpinningDangers);
			}
		}
	}
}