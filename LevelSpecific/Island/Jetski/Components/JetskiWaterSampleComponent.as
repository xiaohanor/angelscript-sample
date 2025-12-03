UCLASS(NotBlueprintable)
class UJetskiWaterSampleComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	int Index = -1;

	private TOptional<uint> CachedWaterCompFrame;

	private TOptional<uint> CachedWaveHeightFrame;
	private float CachedWaveHeight;

	private TOptional<uint> CachedWaveNormalFrame;
	private FVector CachedWaveNormal;

	private AJetski Jetski;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(OceanWaves::HasOceanWavePaint())
			OceanWaves::RemoveWaveDataInstigator(GetWaveInstigator());
	}

	FInstigator GetWaveInstigator() const
	{
		return FInstigator(this, Owner.Name);
	}

	private FVector GetWaveSampleLocation() const
	{
		FVector Location = WorldLocation;
		
		if(Jetski != nullptr && OceanWaves::HasOceanWavePaint())
		{
			const FVector HorizontalVelocity = Jetski.ActorVelocity.VectorPlaneProject(FVector::UpVector);
			Location += (HorizontalVelocity * OceanWaves::GetSmoothDelayInSeconds());
		}
		
		return Location;
	}

	float SampleWaveHeight()
	{
		if(CachedWaveHeightFrame.IsSet() && CachedWaveHeightFrame.Value == Time::FrameNumber)
			return CachedWaveHeight;

		CachedWaveHeightFrame.Set(Time::FrameNumber);
		CachedWaveHeight = Jetski::GetWaveHeightAtLocation(GetWaveSampleLocation(), GetWaveInstigator());

		return CachedWaveHeight;
	}

	FVector SampleWaveLocation()
	{
		const float WaveHeight = SampleWaveHeight();
		return FVector(WorldLocation.X, WorldLocation.Y, WaveHeight);
	}

	FVector SampleWaveNormal()
	{
		if(CachedWaveNormalFrame.IsSet() && CachedWaveNormalFrame.Value == Time::FrameNumber)
			return CachedWaveNormal;

		CachedWaveNormalFrame.Set(Time::FrameNumber);
		CachedWaveNormal = Jetski::GetWaveNormalAtLocation(GetWaveSampleLocation(), GetWaveInstigator());

		return CachedWaveNormal;
	}

	int opCmp(UJetskiWaterSampleComponent Other) const
	{
		if(Index > Other.Index)
			return 1;
		else if(Index < Other.Index)
			return -1;

		return 0;
	}
};

#if EDITOR
class UJetskiWaterSampleComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UJetskiWaterSampleComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto WaterSampleComp = Cast<UJetskiWaterSampleComponent>(Component);
		if(WaterSampleComp == nullptr)
			return;

		FVector Location = WaterSampleComp.WorldLocation;
		DrawPoint(Location, FLinearColor::LucBlue, 20);
	}
};
#endif