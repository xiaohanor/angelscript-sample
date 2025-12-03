class USanctuarySnakeHeadRotationCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default CapabilityTags.Add(n"SanctuarySnake");
	default CapabilityTags.Add(n"SanctuarySnakeHeadRotation");

	USanctuarySnakeSettings Settings;
	USanctuarySnakeComponent SanctuarySnakeComponent;
	ASanctuarySnake Snake;

	FVector SlerpedWorldUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);
		Settings = USanctuarySnakeSettings::GetSettings(Owner);
		Snake = Cast<ASanctuarySnake>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SlerpedWorldUp = SanctuarySnakeComponent.WorldUp;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector Location;
		FVector Normal = SanctuarySnakeComponent.WorldUp;
		GetLocationAndNormalFromTraces(Location, Normal, 300.0, 3);
//		Debug::DrawDebugLine(Snake.Pivot.WorldLocation, Snake.Pivot.WorldLocation + Normal * 500.0, FLinearColor::Blue, 5.0, 0.0);

//		SlerpedWorldUp = SlerpedWorldUp.SlerpTowards(SanctuarySnakeComponent.WorldUp, 8.0 * DeltaTime);
		SlerpedWorldUp = SlerpedWorldUp.SlerpTowards(Normal, 30.0 * DeltaTime);

		Snake.Pivot.SetWorldRotation(FQuat::MakeFromZX(SlerpedWorldUp, Snake.MovementComponent.Velocity));
//		Snake.Pivot.SetWorldRotation(FQuat::MakeFromXZ(Snake.MovementComponent.Velocity, SlerpedWorldUp));

	//	Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + SanctuarySnakeComponent.WorldUp * 400.0, FLinearColor::Blue, 5.0, 0.0);
	}

	void GetLocationAndNormalFromTraces(FVector &OutLocation, FVector &OutNormal, float Radius = 100.0, int Traces = 3)
	{
//		Debug::DrawDebugSphere(Snake.Pivot.WorldLocation, 150.0, 24, FLinearColor::Green, 5.0, 0.0);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);

		FVector TraceStart = Snake.Pivot.WorldLocation;

		FVector AverageLocation;
		FVector AverageNormal;

//		AverageNormal += Snake.MovementWorldUp;
//		AverageNormal += Snake.Pivot.UpVector;

		TArray<FVector> LocationSamples;
		TArray<FVector> NormalSamples;

		float AngleStep = TWO_PI / Traces;

		int BlockingHits = 0;

		for (int i = 0; i < Traces; i++)
		{
			FVector RelativeTraceStart = FVector(Math::Cos(i * AngleStep) * Radius, Math::Sin(i * AngleStep) * Radius, Math::Sin(Math::DegreesToRadians(-60.0)) * Radius);

			FVector TraceEnd = Snake.Pivot.WorldTransform.TransformPosition(RelativeTraceStart);

			FHitResult HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);
			
//			Debug::DrawDebugLine(HitResult.TraceStart, HitResult.TraceEnd, FLinearColor::Green, 5.0, 0.0);

			if (HitResult.bBlockingHit)
			{
				BlockingHits += 1;
				LocationSamples.Add(HitResult.Location);
			//	NormalSamples.Add(HitResult.ImpactNormal);
			//	AverageLocation += HitResult.Location;
			//	AverageNormal += HitResult.ImpactNormal;

			}
			else
			{
			//	LocationSamples.Add(HitResult.TraceEnd);
			}
		}


		if (BlockingHits != Traces)
		{
			OutLocation = FVector::ZeroVector;
			OutNormal = Snake.MovementWorldUp;
		//	Debug::DrawDebugLine(Snake.Pivot.WorldLocation, Snake.Pivot.WorldLocation + OutNormal * 550.0, FLinearColor::Red, 20.0, 0.0);
			return;
		}

		for (int i = 0; i < LocationSamples.Num(); i++)
		{					
			FVector SampleNormal = (LocationSamples[Math::WrapIndex(i + 1, 0, LocationSamples.Num())] - LocationSamples[i]).CrossProduct((LocationSamples[Math::WrapIndex(i + 2, 0, LocationSamples.Num())] - LocationSamples[i]));
			AverageNormal += SampleNormal;
		}


//		OutLocation = (AverageLocation / LocationSamples.Num());
		OutNormal = (AverageNormal / LocationSamples.Num()).GetSafeNormal();


		OutLocation = FVector::ZeroVector;
//		OutNormal = FVector::ZeroVector;

//		OutNormal = AverageNormal.GetSafeNormal();
	}
}