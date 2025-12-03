struct FJetskiWaterPerlinWaves
{
	UPROPERTY(EditAnywhere)
	protected float WaveSpeed = 1;

	UPROPERTY(EditAnywhere)
	protected float WaveSize = 1000;

	UPROPERTY(EditAnywhere)
	protected float WaveHeight = 10;

	UPROPERTY(EditAnywhere)
	protected float WaveNormalSampleArea = 200;

	FJetskiWaterPerlinWaves(float InWaveSpeed, float InWaveSize, float InWaveHeight, float InWaveNormalSampleArea)
	{
		WaveSpeed = InWaveSpeed;
		WaveSize = InWaveSize;
		WaveHeight = InWaveHeight;
		WaveNormalSampleArea = InWaveNormalSampleArea;
	}

	// FB TODO: Ugly quick fix to keep basically the same settings after I tweaked how the sample location is calculated
	FJetskiWaterPerlinWaves(FJetskiFloatingDebrisCalculatedSineSettings OldSettings)
	{
		WaveSpeed = OldSettings.WaveSpeed * 0.0008;
		WaveSize = OldSettings.WaveSize * 1000;
		WaveHeight = OldSettings.WaveHeight;
		WaveNormalSampleArea = OldSettings.NormalSampleArea;
	}

	/**
	 * User perlin noise to generate fake wave heights
	 * @return Height offset relative to Location.Z
	 */
	float CalculatePerlinWaveHeightOffset(FVector Location) const
	{
		const float Time = Time::GlobalCrumbTrailTime;
		FVector2D SampleLocation = FVector2D(Location.X / WaveSize, Location.Y / WaveSize);
		SampleLocation += FVector2D(Time * WaveSpeed, 0);
		return Math::PerlinNoise2D(SampleLocation) * WaveHeight;
	}

	/**
	 * User perlin noise to generate fake wave normals
	 * @return Normal in World Space
	 */
	FVector CalculatePerlinWaveNormal(FVector Location) const
	{
		FVector Forward = Location + FVector(WaveNormalSampleArea, 0, 0);
		FVector Right = Location + FVector(0, WaveNormalSampleArea, 0);
		FVector Back = Location + FVector(-WaveNormalSampleArea, 0, 0);
		FVector Left = Location + FVector(0, -WaveNormalSampleArea, 0);

		Forward.Z += CalculatePerlinWaveHeightOffset(Forward);
		Right.Z += CalculatePerlinWaveHeightOffset(Right);
		Back.Z += CalculatePerlinWaveHeightOffset(Back);
		Left.Z += CalculatePerlinWaveHeightOffset(Left);

		// Debug::DrawDebugPoint(Forward, 10, FLinearColor::Yellow);
		// Debug::DrawDebugPoint(Right, 10, FLinearColor::Yellow);
		// Debug::DrawDebugPoint(Back, 10, FLinearColor::Yellow);
		// Debug::DrawDebugPoint(Left, 10, FLinearColor::Yellow);

		const FPlane Plane1(Forward, Right, Back);
		const FPlane Plane2(Forward, Back, Left);

		return (Plane1.Normal + Plane2.Normal) * 0.5;
	}

	#if EDITOR
	void DebugDraw(FVector Location, int Resolution = 5, float SampleDistance = 500) const
	{
		FVector WaveLocation = Location;
		WaveLocation.Z += CalculatePerlinWaveHeightOffset(WaveLocation);

		Debug::DrawDebugCircle(WaveLocation, WaveNormalSampleArea, 12, FLinearColor::Green, 3);

		for(int x = -Resolution; x < Resolution; x++)
		{
			for(int y = -Resolution; y < Resolution; y++)
			{
				FVector SampleLocation = Location;
				SampleLocation += FVector(x * SampleDistance, y * SampleDistance, 0);
				SampleLocation.Z += CalculatePerlinWaveHeightOffset(SampleLocation);
				Debug::DrawDebugPoint(SampleLocation, 10, FLinearColor::Yellow);
			}
		}

		FVector WaveNormal = CalculatePerlinWaveNormal(WaveLocation);
		Debug::DrawDebugDirectionArrow(WaveLocation, WaveNormal, 500, 50, FLinearColor::Red, 10);
	}

	void Visualize(const UHazeScriptComponentVisualizer Visualizer, FVector Location, FVector&out OutWaveLocation, FVector&out OutWaveNormal, int Resolution = 5, float SampleDistance = 500) const
	{
		OutWaveLocation = Location;
		OutWaveLocation.Z += CalculatePerlinWaveHeightOffset(OutWaveLocation);

		Visualizer.DrawCircle(OutWaveLocation, WaveNormalSampleArea, FLinearColor::Green, 3);

		for(int x = -Resolution; x < Resolution; x++)
		{
			for(int y = -Resolution; y < Resolution; y++)
			{
				FVector SampleLocation = Location;
				SampleLocation += FVector(x * SampleDistance, y * SampleDistance, 0);
				SampleLocation.Z += CalculatePerlinWaveHeightOffset(SampleLocation);
				Visualizer.DrawPoint(SampleLocation, FLinearColor::Yellow, 10);
			}
		}

		OutWaveNormal = CalculatePerlinWaveNormal(OutWaveLocation);
		Visualizer.DrawArrow(OutWaveLocation, OutWaveLocation + OutWaveNormal * 500, FLinearColor::Red, 50, 10, true);
	}
	#endif
};