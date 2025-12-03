
class AHelixRuntimeSpline : AHazeActor
{

	// Will automatically update the 3D spline  
	UFUNCTION(Category = "Helix Properties", CallInEditor)
	void ManuallyGenerateHelix()
	{
		HelixNiagaraComponent.GenerateHelix();
	}

	// Will automatically update the spline on construction script. 
	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	bool bAutoGenerateHelixWhileEditing = true;

	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UHelixSplineNiagaraComponent HelixNiagaraComponent;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = HelixNiagaraComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default Billboard.SpriteName = "T_Loft_Spline";
#endif

	default PrimaryActorTick.bStartWithTickEnabled = true;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (bAutoGenerateHelixWhileEditing == false)
			return;

		HelixNiagaraComponent.GenerateHelix();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HelixNiagaraComponent.SendDataToNiagara();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HelixNiagaraComponent.GenerateHelix();
	}

}

class UHelixSplineNiagaraComponent : UNiagaraComponent
{
	default bTickInEditor = false;
	//default PrimaryComponentTick.bStartWithTickEnabled = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreenScaled("ITS TICKING");
	}

	void SendDataToNiagara()
	{
		if(Spline.Points.Num() < 2)
			return;

		// float NormExecIndex = (Time::GetGameTimeSeconds() * 0.2) % 1.0;
		// float Dist = NormExecIndex * Spline.Length;
		// FVector Majs = DebugEvalPos(Dist);
		// Debug::DrawDebugPoint(Majs, 10, FLinearColor::Red, 5.5);
		// PrintToScreen("Norm: " + NormExecIndex);
		// PrintToScreen("Dist: " + Dist);

		SetNiagaraVariableFloat("SplineLength", Spline.Length);
		TArray<FVector> SplineLocations;
		SplineLocations.Reserve(150);
		Spline.GetLocations(SplineLocations, 150);

		FTransform WorldTM = GetWorldTransform();

		Debug::DrawDebugArrow(
			WorldTM.GetLocation(),
			WorldTM.GetLocation() + WorldTM.Rotation.ForwardVector*1000,
			100,

		);


		for(int i = 0; i < SplineLocations.Num(); ++i)
		{
			SplineLocations[i] = WorldTM.TransformPositionNoScale(SplineLocations[i]);
		}

		NiagaraDataInterfaceArray::SetNiagaraArrayVector(
			this, 
			n"SplineLocations", 
			// Spline.Points
			SplineLocations
		);

	}

	FVector DebugEvalPos(const float Dist)
	{
		int NumSamples = Spline.Points.Num() - 1;

		float Alpha;
		int32 PrevKey, NextKey;

		// find neighbor keys

		const float SplineDistanceStep = (1.0/NumSamples) * Spline.Length;
		const float InvSplineDistanceStep = 1.0 / SplineDistanceStep;

		const float Key = Dist * InvSplineDistanceStep;
		PrevKey = Math::Clamp(Math::FloorToInt(Key), 0, NumSamples);
		NextKey = Math::Clamp(Math::CeilToInt(Key), 0, NumSamples);

		Alpha = Math::Frac(Key);

		// SplineLUT.FindNeighborKeys(InDistance, PrevKey, NextKey, Alpha);

		if (NextKey == PrevKey)
		{
			if (PrevKey >= 0)
			{
				return Spline.Points[PrevKey];
			}
			else
			{
				return FVector::ZeroVector;
			}
		}

		return Math::Lerp(Spline.Points[PrevKey], Spline.Points[NextKey], Alpha);
	}

	// y = radius, x = height.
	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	FRuntimeFloatCurve HelixCurvature;

	// Mirrors it. It will generate the helix in the clockwise (rotational) direction.
	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	bool bCounterClockwise = false;

	// The spline structure will not change only what is considered backwards and forwards
	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	bool bFlipDirection= false;
	bool bPreviousFlipDirection = false;

	/* Will be clamped to [0, 360] degree range internally.*/
	// UPROPERTY(EditAnywhere, Category = "Helix Properties", meta = (ClampMin = "3", UIMin = "3", ClampMax = "360", UIMax = "360"))
	// int PointsPerTurn = 16;
	int PointsPerTurn = 16;

	UPROPERTY(EditAnywhere, Category = "Helix Properties", meta = (ClampMin = "0", UIMin = "0"))
	float Height = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Helix Properties", meta = (ClampMin = "0", UIMin = "0"))
	float Radius = 300.0;

	UPROPERTY(EditAnywhere, Category = "Helix Properties", meta = (ClampMin = "1", UIMin = "1"))
	int Turns = 8;

	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	FVector AxisScales = FVector::OneVector;

	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	float NoiseStrength = 50.0;

	UPROPERTY(EditAnywhere, Category = "Helix Properties")
	float NoiseScale = 1.0;

	float Pitch = 0.0;
	float StepSize_Angular = 0.0;
	float StepSize_Pitch = 0.0;
	int TotalIterations = 0;
	float MaxPaddingFromCenter = 0.0;

	FVector CompLocation = FVector::ZeroVector;
	FVector SpiralCenter = FVector::ZeroVector;
	FQuat CompQuat = FQuat::Identity;
	TArray<FVector> SpiralParticleLocations;

	FHazeRuntimeSpline Spline;

	void ModuleSplineWithCurlNoise()
	{
		if(NoiseStrength <= 0.0)
			return;

		TArray<FVector> Offsets;
		Offsets.Reserve(Spline.Points.Num());

		for(int i = 0; i < Spline.Points.Num() - 1; ++i)
		{
			const FVector D = Spline.GetDirectionAtSplinePointIndex(i);
			const FVector P = Spline.Points[i];

			// FVector CurlVelocity = CurlNoiseAsset.GetCurl(P, NoiseScale) * NoiseStrength;
			FVector CurlVelocity = FVector(Math::PerlinNoise3D(P * NoiseScale) * NoiseStrength);

			FVector Offset = CurlVelocity.VectorPlaneProject(D); 
			Offsets.Add(Offset);
		}

		for(int i = 0; i < Spline.Points.Num() - 1; ++i)
		{
			Spline.OffsetPoint(Offsets[i], i);
		}


	}

	// Will automatically update the 3D spline  
	UFUNCTION(Category = "Helix Properties", CallInEditor)
	void GenerateHelix()
	{
		InitData();
		GenerateHelixData();
		UpdateSpline();
		ModuleSplineWithCurlNoise();
	}

	void InitData()
	{
		TotalIterations = Turns * PointsPerTurn;
		Pitch = Height / Turns;
		StepSize_Angular = 360.0 / PointsPerTurn;
		StepSize_Angular *= bCounterClockwise ? -1 : 1;
		StepSize_Pitch = Pitch / PointsPerTurn;
		MaxPaddingFromCenter = Math::Max(Height, Radius);

		// Spline.ClearSplinePoints(false);
		Spline = FHazeRuntimeSpline();

		// CompLocation = GetWorldLocation();
		// CompQuat = GetComponentQuat();
		// CompQuat *= FQuat(FVector::RightVector, PI * 0.5);
		CompQuat = FQuat(FVector::RightVector, PI * 0.5);
		CompQuat.Normalize();

//		System::DrawDebugLine(CompLocation, CompLocation + CompQuat.Vector() * 1000.f);

		SpiralCenter = CompLocation + CompQuat.Vector()*Height*0.5;
	}

	void GenerateHelixData()
	{
		const auto AmountOfPoints = PointsPerTurn * Turns;
		SpiralParticleLocations.Reset(AmountOfPoints);

		const FVector EulerAxisScales = FVector(AxisScales.Z, AxisScales.Y, AxisScales.X);

		if (HelixCurvature.GetNumKeys() > 1)
		{
			FVector2D CurvatureLengthRange, CurvatureRadiusRange;
			HelixCurvature.GetValueRange(CurvatureRadiusRange.X, CurvatureRadiusRange.Y);
			HelixCurvature.GetTimeRange(CurvatureLengthRange.X, CurvatureLengthRange.Y);
			const float MaxCurvatureRadius = Math::Abs(CurvatureRadiusRange.X - CurvatureRadiusRange.Y);
			const float MaxCurvatureLength = Math::Abs(CurvatureLengthRange.X - CurvatureLengthRange.Y);

			const FVector2D LengthOfHelixRange = FVector2D(0, TotalIterations * StepSize_Angular);

			for (auto i = 0; i < TotalIterations; ++i)
			{
				const float RadStepSize = Math::DegreesToRadians(i*StepSize_Angular);
				const float CurvatureTime = Math::GetMappedRangeValueClamped(
					LengthOfHelixRange,
					CurvatureLengthRange,
					i * StepSize_Angular	
				);
				float RadiusScale = HelixCurvature.GetFloatValue(CurvatureTime);

				if(MaxCurvatureRadius != 0.0)
					RadiusScale /= MaxCurvatureRadius;
				else
					RadiusScale /= KINDA_SMALL_NUMBER;

				const FVector Offset = FVector(
					Math::Sin(RadStepSize) * Radius * RadiusScale,
					Math::Cos(RadStepSize) * Radius * RadiusScale,
					i*StepSize_Pitch
				);
				const FVector Offset_Rotated = CompQuat.RotateVector(Offset * EulerAxisScales);
				const FVector SpiralPointLocation = CompLocation + Offset_Rotated;
				SpiralParticleLocations.Add(SpiralPointLocation);
			}
		}
		else
		{
			// Just make a straight spline with the desired radius
			for (auto i = 0; i < TotalIterations; ++i)
			{
				const float RadStepSize = Math::DegreesToRadians(i*StepSize_Angular);
				const FVector Offset = FVector(
					Math::Sin(RadStepSize) * Radius,
					Math::Cos(RadStepSize) * Radius,
					i*StepSize_Pitch
				);

				const FVector Offset_Rotated = CompQuat.RotateVector(Offset * EulerAxisScales);
				const FVector SpiralPointLocation = CompLocation + Offset_Rotated;
				SpiralParticleLocations.Add(SpiralPointLocation);
			}
		}

	}

	void UpdateSpline()
	{
		if (SpiralParticleLocations.Num() <= 0)
			return;

		// Spline.ClearSplinePoints(false);
		Spline = FHazeRuntimeSpline();

		if(bFlipDirection)
		{
			TArray<FVector> NewSpiralLocations;
			NewSpiralLocations.Reserve(SpiralParticleLocations.Num());

			for (int i = SpiralParticleLocations.Num() - 1; i >= 0 ; i--)
				NewSpiralLocations.Add(SpiralParticleLocations[i]);

			SpiralParticleLocations = NewSpiralLocations;
		}

		for (int i = 0; i < SpiralParticleLocations.Num(); ++i)
		{
			Spline.AddPoint( SpiralParticleLocations[i],);
		}

		// DebugPoints();

	}

	void DebugPoints()
	{
		for(int i = 0; i < Spline.Points.Num() - 2; ++i)
		{
		
			FVector P0 = Spline.Points[i];
			FVector P1 = Spline.Points[i+1];
			Debug::DrawDebugLine(P0, P1, FLinearColor::Red, 20, 3.0);
		}
	}

}


class UHelixSplineNiagaraComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UHelixSplineNiagaraComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		const UHelixSplineNiagaraComponent SplineNiagaraComp = Cast<UHelixSplineNiagaraComponent>(Component);
		if(SplineNiagaraComp == nullptr)
			return;

		auto Spline = SplineNiagaraComp.Spline;

		if(Spline.Points.Num() < 2)
			return;

		TArray<FVector> SplineLocations = Spline.Points;
		FTransform WorldTM = SplineNiagaraComp.GetWorldTransform();
		for(int i = 0; i < SplineLocations.Num(); ++i)
			SplineLocations[i] = WorldTM.TransformPositionNoScale(SplineLocations[i]);
		Spline.Points = SplineLocations;

		Spline.VisualizeSplineSimple(this, 500);
	}
}