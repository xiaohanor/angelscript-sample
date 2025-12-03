struct FSkylineWaveData
{
	UPROPERTY()
	FRotator Orientation;

	UPROPERTY()
	float Frequency = 1.0;

	UPROPERTY()
	float Length = 100.0;

	UPROPERTY()
	float Amplitude = 100.0;

	UPROPERTY()
	float Offset = 0.0;
}

class USkylineWaveComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TArray<FSkylineWaveData> Waves;

	FVector GetOffsetAtLocation(FVector WorldLocation)
	{
		float Time = Time::PredictedGlobalCrumbTrailTime;

		FVector Offset;

		for (auto Wave : Waves)
			Offset += GetOffsetFromWave(WorldLocation, Time, Wave);

		return Offset;
	}

	FVector GetOffsetFromWave(FVector WorldLocation, float Time, FSkylineWaveData WaveData)
	{	
		FVector Offset;

		Offset = WaveData.Orientation.UpVector * Math::Sin((WorldLocation / (WaveData.Length / TWO_PI)).DotProduct(WaveData.Orientation.ForwardVector) + (Time + WaveData.Offset) * WaveData.Frequency * TWO_PI) * WaveData.Amplitude;

		return Offset;
	}

	FVector GetNormalAtLocation(FVector WorldLocation)
	{
		float Time = Time::PredictedGlobalCrumbTrailTime;

		FVector Normal;

		for (auto Wave : Waves)
			Normal += GetNormalFromWave(WorldLocation, Time, Wave);

		return Normal.SafeNormal;
	}

	FVector GetNormalFromWave(FVector WorldLocation, float Time, FSkylineWaveData WaveData)
	{	
		FVector Normal = WaveData.Orientation.UpVector;
		float F = (WorldLocation / (WaveData.Length / TWO_PI)).DotProduct(WaveData.Orientation.ForwardVector) + (Time + WaveData.Offset) * WaveData.Frequency * TWO_PI;
		Print("" + F, 0.0);
		Normal = Normal.RotateAngleAxis(90.0 * Math::Cos(F), WaveData.Orientation.RightVector);

		return Normal;
	}
}