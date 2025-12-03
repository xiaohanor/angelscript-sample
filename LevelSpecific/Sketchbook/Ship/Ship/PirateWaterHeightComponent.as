struct FPirateWaterSampleTriangle
{
	UPROPERTY(EditAnywhere)
	int IndexA = 0;
	UPROPERTY(EditAnywhere)
	int IndexB = 0;
	UPROPERTY(EditAnywhere)
	int IndexC = 0;
}

UCLASS(NotBlueprintable, HideCategories = "Rendering ComponentTick Disable Debug Activation Cooking Tags Physics LOD Collision")
class UPirateWaterHeightComponent : UActorComponent
{
	TArray<UPirateWaterSampleComponent> SampleComponents;

	UPROPERTY(EditDefaultsOnly)
	TArray<FPirateWaterSampleTriangle> SampleTriangles;

	float SpawnTime = -BIG_NUMBER;
	const float SafetyTime = 0.5;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		FetchSampleComponents();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnTime = Time::GameTimeSeconds;
		FetchSampleComponents();
	}

	FVector GetWaterUpVector() const
	{
		FVector WaterUpVector = FVector::ZeroVector;
		for(auto Triangle : SampleTriangles)
		{
			if(!SampleComponents.IsValidIndex(Triangle.IndexA) || !SampleComponents.IsValidIndex(Triangle.IndexB) || !SampleComponents.IsValidIndex(Triangle.IndexC))
			{
				PrintWarning("Invalid index", 0);
				continue;
			}

			FVector LocationA = SampleComponents[Triangle.IndexA].SampleWaterLocation();
			FVector LocationB = SampleComponents[Triangle.IndexB].SampleWaterLocation();
			FVector LocationC = SampleComponents[Triangle.IndexC].SampleWaterLocation();

			// Debug::DrawDebugPoint(LocationA, 100, FLinearColor::Red);
			// Debug::DrawDebugPoint(LocationB, 100, FLinearColor::Green);
			// Debug::DrawDebugPoint(LocationC, 100, FLinearColor::Blue);

			FPlane WaterPlane = FPlane(LocationA, LocationB, LocationC);
			if(WaterPlane.Normal.Z > 0)
			{
				WaterUpVector += WaterPlane.Normal;
			}
			else
			{
				WaterUpVector -= WaterPlane.Normal;
			}
		}

		return WaterUpVector / SampleTriangles.Num();
	}

	float GetWaterHeight()
	{
		if(SampleComponents.IsEmpty())
			FetchSampleComponents();
		
		float WaterHeight = 0;

		for(auto SampleComp : SampleComponents)
		{
			WaterHeight += SampleComp.CalculateWaveHeight();
		}
		
		WaterHeight /= SampleComponents.Num();

		if(!CanFetchWaterHeight())
		{
			// We can't actually get the water height for a few frames, so fake the result for a short duration
			float FakeAlpha = Time::GetGameTimeSince(SpawnTime) / SafetyTime;
			return Math::Lerp(Pirate::GetWaterPlaneHeight(), WaterHeight, FakeAlpha);
		}

		return WaterHeight;
	}

	bool CanFetchWaterHeight() const
	{
		return Time::GetGameTimeSince(SpawnTime) > SafetyTime;
	}

	float GetMaxWaterHeight() const
	{
		float WaterHeight = 0;

		for(auto SampleComp : SampleComponents)
		{
			WaterHeight = Math::Max(WaterHeight, SampleComp.CalculateWaveHeight());
		}

		return WaterHeight;
	}

	void FetchSampleComponents()
	{
		SampleComponents.Empty();
		Owner.GetComponentsByClass(SampleComponents);
		SampleComponents.Sort();
	}
};

#if EDITOR
class UPirateWaterHeightComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPirateWaterHeightComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto WaterHeightComp = Cast<UPirateWaterHeightComponent>(Component);
		if(WaterHeightComp == nullptr)
			return;

		WaterHeightComp.FetchSampleComponents();

		for(int i = 0; i < WaterHeightComp.SampleComponents.Num(); i++)
		{
			FVector Location = WaterHeightComp.SampleComponents[i].WorldLocation;
			DrawPoint(Location, FLinearColor::Blue, 20);
			DrawWorldString(f"{i}", Location, FLinearColor::White, 1, -1, false, true);
		}

		for(int i = 0; i < WaterHeightComp.SampleTriangles.Num(); i++)
		{
			auto Triangle = WaterHeightComp.SampleTriangles[i];

			if(!WaterHeightComp.SampleComponents.IsValidIndex(Triangle.IndexA) || !WaterHeightComp.SampleComponents.IsValidIndex(Triangle.IndexB) || !WaterHeightComp.SampleComponents.IsValidIndex(Triangle.IndexC))
			{
				PrintWarning("Invalid index", 0);
				continue;
			}

			FVector LocationA = WaterHeightComp.SampleComponents[Triangle.IndexA].WorldLocation;
			FVector LocationB = WaterHeightComp.SampleComponents[Triangle.IndexB].WorldLocation;
			FVector LocationC = WaterHeightComp.SampleComponents[Triangle.IndexC].WorldLocation;
			DrawLine(LocationA, LocationB, FLinearColor::LucBlue, 20);
			DrawLine(LocationB, LocationC, FLinearColor::LucBlue, 20);
			DrawLine(LocationC, LocationA, FLinearColor::LucBlue, 20);

			FVector Location = (LocationA + LocationB + LocationC) / 3.0;

			DrawWorldString(f"Triangle {i}", Location, FLinearColor::LucBlue, 1, -1, false, true);
		}
	}
};
#endif