

namespace OceanWaves
{
	bool HasOceanWavePaint()
	{
		return TListedActors<AOceanWavePaint>().Single != nullptr;
	}

	AOceanWavePaint GetOceanWavePaint()
	{
		auto OceanWavePaint = TListedActors<AOceanWavePaint>().Single;
		if(OceanWavePaint == nullptr)
			devError("There needs to be one AOceanWavePaint actor to get water height.");
		return OceanWavePaint;
	}
	
	// Inserts a request for wave data
	UFUNCTION()
	void RequestWaveData(FInstigator Instigator, FVector WorldPos)
	{
		OceanWaves::GetOceanWavePaint().QueryWaveData(Instigator, WorldPos);
	}
	// Inserts a request for wave data
	UFUNCTION()
	void RequestWaveDataRaycast(FInstigator Instigator, FVector Start, FVector Direction)
	{
		OceanWaves::GetOceanWavePaint().QueryWaveDataRaycast(Instigator, Start, Direction);
	}

	UFUNCTION()
	bool HasRequestedWaveData(FInstigator Instigator)
	{
		return OceanWaves::GetOceanWavePaint().HasRequestedWaveData(Instigator);
	}

	// Checks if wave data is ready
	UFUNCTION()
	bool IsWaveDataReady(FInstigator Instigator)
	{
		return OceanWaves::GetOceanWavePaint().IsWaveDataReady(Instigator);
	}

	// returns the most up-to-date wave data for this instigator
	UFUNCTION()
	FWaveData GetLatestWaveData(FInstigator Instigator)
	{
		return OceanWaves::GetOceanWavePaint().GetLatestWaveData(Instigator);
	}
	

	
	// Gets the number of frames of delay there is between the input and output
	UFUNCTION()
	int GetCurrentDelayInFrames()
	{
		auto OceanWavePaint = OceanWaves::GetOceanWavePaint();
		if(OceanWavePaint == nullptr)
			return 0;

		return int(OceanWavePaint.CurrentDelayFrames);
	}

	UFUNCTION()
	float GetCurrentDelayInSeconds()
	{
		auto OceanWavePaint = OceanWaves::GetOceanWavePaint();
		if(OceanWavePaint == nullptr)
			return 0;

		return OceanWavePaint.CurrentDelaySeconds;
	}

	UFUNCTION()
	float GetSmoothDelayInSeconds()
	{
		auto OceanWavePaint = OceanWaves::GetOceanWavePaint();
		if(OceanWavePaint == nullptr)
			return 0;

		return OceanWavePaint.SmoothDelaySeconds.GetValue();
	}

	UFUNCTION()
	void RemoveWaveDataInstigator(FInstigator Instigator)
	{
		auto OceanWavePaint = OceanWaves::GetOceanWavePaint();
		if(OceanWavePaint == nullptr)
			return;
	
		OceanWavePaint.RemoveWaveDataInstigator(Instigator);
	}
}