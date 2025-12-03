class USkylineBossShockWaveComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossShockWave> ShockWaveClass;
	TArray<ASkylineBossShockWave> ShockWaves;

	void DestroyShockWaves()
	{
		auto ShockWavesToDestroy = ShockWaves;
		for (auto& ShockWave : ShockWavesToDestroy)
		{
			ShockWave.DestroyActor();
		}
	}

	UFUNCTION()
	private void RemoveShockWave(AActor Actor, EEndPlayReason EndPlayReason)
	{
		ShockWaves.Remove(Cast<ASkylineBossShockWave>(Actor));
	}	
}