struct FJetskiWaterSampleTriangle
{
	UPROPERTY(EditAnywhere)
	int IndexA = 0;

	UPROPERTY(EditAnywhere)
	int IndexB = 0;

	UPROPERTY(EditAnywhere)
	int IndexC = 0;
};

UCLASS(NotBlueprintable)
class UJetskiWaterPlaneComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TArray<FJetskiWaterSampleTriangle> SampleTriangles;

	UPROPERTY(EditAnywhere, Category = "Perlin")
	bool bAddPerlinWaves = true;

	UPROPERTY(EditAnywhere, Category = "Perlin", Meta = (EditCondition = "bAddPerlinWaves"))
	FJetskiWaterPerlinWaves PerlinWaveSettings;

	TArray<UJetskiWaterSampleComponent> SampleComponents;

	private TOptional<uint> CachedWaveHeightFrame;
	private float CachedWaveHeight;

	private TOptional<uint> CachedWaveNormalFrame;
	private FVector CachedWaveNormal;

	TInstigated<float> OverrideWaterHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FetchSampleComponents();
	}

	float GetWaveHeight()
	{
		if(!OverrideWaterHeight.IsDefaultValue())
			return OverrideWaterHeight.Get();

		if(CachedWaveHeightFrame.IsSet() && CachedWaveHeightFrame.Value == Time::FrameNumber)
			return CachedWaveHeight;

		if(SampleComponents.IsEmpty())
			FetchSampleComponents();
		
		float WaveHeight = 0;

		for(auto SampleComp : SampleComponents)
		{
			WaveHeight += SampleComp.SampleWaveHeight();
		}
		
		WaveHeight /= SampleComponents.Num();

		if(bAddPerlinWaves)
		{
			WaveHeight += PerlinWaveSettings.CalculatePerlinWaveHeightOffset(
				Owner.ActorLocation
			);
		}

		CachedWaveHeightFrame.Set(Time::FrameNumber);
		CachedWaveHeight = WaveHeight;

		return WaveHeight;
	}

	FVector GetWaveNormal()
	{
		if(!OverrideWaterHeight.IsDefaultValue())
			return FVector::UpVector;

		if(CachedWaveNormalFrame.IsSet() && CachedWaveNormalFrame.Value == Time::FrameNumber)
			return CachedWaveNormal;

		FVector WaveNormal = FVector::ZeroVector;
		for(auto Triangle : SampleTriangles)
		{
			if(!SampleComponents.IsValidIndex(Triangle.IndexA) || !SampleComponents.IsValidIndex(Triangle.IndexB) || !SampleComponents.IsValidIndex(Triangle.IndexC))
			{
				PrintWarning("Invalid index", 0);
				continue;
			}

			const FVector LocationA = SampleComponents[Triangle.IndexA].SampleWaveLocation();
			const FVector LocationB = SampleComponents[Triangle.IndexB].SampleWaveLocation();
			const FVector LocationC = SampleComponents[Triangle.IndexC].SampleWaveLocation();

			FPlane WaterPlane = FPlane(LocationA, LocationB, LocationC);
			if(WaterPlane.Normal.Z > 0)
				WaveNormal += WaterPlane.Normal;
			else
				WaveNormal -= WaterPlane.Normal;
		}

		WaveNormal /= SampleTriangles.Num();

		if(bAddPerlinWaves)
		{
			const FVector SmallWaveNormal = PerlinWaveSettings.CalculatePerlinWaveNormal(Owner.ActorLocation);
			const float NormalFactor = Math::Saturate(WaveNormal.GetAngleDegreesTo(FVector::UpVector) / 5);

			// If the large waves are flat, use the small waves
			WaveNormal = Math::Lerp(SmallWaveNormal, WaveNormal, NormalFactor);
			WaveNormal.Normalize();
		}

		CachedWaveNormalFrame.Set(Time::FrameNumber);
		CachedWaveNormal = WaveNormal;

		return WaveNormal;
	}

	void FetchSampleComponents()
	{
		SampleComponents.Empty();
		Owner.GetComponentsByClass(SampleComponents);
		SampleComponents.Sort();
	}
};

#if EDITOR
class UJetskiWaterPlaneComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UJetskiWaterPlaneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto WaterPlaneComp = Cast<UJetskiWaterPlaneComponent>(Component);
		if(WaterPlaneComp == nullptr)
			return;

		WaterPlaneComp.FetchSampleComponents();

		for(int i = 0; i < WaterPlaneComp.SampleComponents.Num(); i++)
		{
			const FVector Location = WaterPlaneComp.SampleComponents[i].WorldLocation;
			DrawPoint(Location, FLinearColor::Blue, 20);
			DrawWorldString(f"{i}", Location, FLinearColor::White, 1, -1, false, true);
		}

		for(int i = 0; i < WaterPlaneComp.SampleTriangles.Num(); i++)
		{
			const auto Triangle = WaterPlaneComp.SampleTriangles[i];

			if(!WaterPlaneComp.SampleComponents.IsValidIndex(Triangle.IndexA) || !WaterPlaneComp.SampleComponents.IsValidIndex(Triangle.IndexB) || !WaterPlaneComp.SampleComponents.IsValidIndex(Triangle.IndexC))
			{
				PrintWarning("Invalid index", 0);
				continue;
			}

			const FVector LocationA = WaterPlaneComp.SampleComponents[Triangle.IndexA].WorldLocation;
			const FVector LocationB = WaterPlaneComp.SampleComponents[Triangle.IndexB].WorldLocation;
			const FVector LocationC = WaterPlaneComp.SampleComponents[Triangle.IndexC].WorldLocation;

			DrawLine(LocationA, LocationB, FLinearColor::LucBlue, 10);
			DrawLine(LocationB, LocationC, FLinearColor::LucBlue, 10);
			DrawLine(LocationC, LocationA, FLinearColor::LucBlue, 10);

			const FVector Location = (LocationA + LocationB + LocationC) / 3.0;

			DrawWorldString(f"Triangle {i}", Location, FLinearColor::LucBlue, 1, -1, false, true);
		}
	}
};
#endif