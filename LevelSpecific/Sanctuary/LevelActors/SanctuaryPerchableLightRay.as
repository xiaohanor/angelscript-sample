class ASanctuaryPerchableLightRay : ASanctuaryDynamicPerchSpline
{
	UPROPERTY(DefaultComponent)
	USceneComponent LightRaySource;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY(EditAnywhere)
	float RayLength = 3000.0;

	UPROPERTY(EditAnywhere)
	int MaxBounces = 10;

	UPROPERTY(EditAnywhere)
	bool bStartEnabled;

	USanctuaryLightRayResponseComponent AffectedLightRayResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();		
	
		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

		if (!bStartEnabled)
			AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TraceRay();

		Super::Tick(DeltaSeconds);	
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		if(AffectedLightRayResponseComp != nullptr)
		{
			AffectedLightRayResponseComp.StopIlluminate(this);
			AffectedLightRayResponseComp = nullptr;
		}
		AddActorDisable(this);
	}

	void TraceRay()
	{
		FVector TraceStart = LightRaySource.WorldLocation;
		FVector TraceDirection = LightRaySource.ForwardVector;
		float RemainingTrace = RayLength;
		int Bounces = 0;

		Spline.SplinePoints.Reset();
		FHazeSplinePoint SourceSplinePoint;
		SourceSplinePoint.RelativeLocation = Spline.WorldTransform.InverseTransformPositionNoScale(LightRaySource.WorldLocation);
		SourceSplinePoint.bOverrideTangent = true;
		SourceSplinePoint.bDiscontinuousTangent = true;
		SourceSplinePoint.ArriveTangent = FVector::ZeroVector;
		SourceSplinePoint.LeaveTangent = FVector::ZeroVector;

		Spline.SplinePoints.Add(SourceSplinePoint);

		while (RemainingTrace > 0.0 && Bounces < MaxBounces)
		{
			auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(this);
			Trace.IgnorePlayers();
			auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceStart + TraceDirection * RemainingTrace);

			RemainingTrace -= HitResult.Distance;

			FVector TraceEnd = (HitResult.bBlockingHit ? HitResult.Location : HitResult.TraceEnd);

			FHazeSplinePoint SplinePoint;
			SplinePoint.RelativeLocation = Spline.WorldTransform.InverseTransformPositionNoScale(TraceEnd);
			SplinePoint.bOverrideTangent = true;
			SplinePoint.bDiscontinuousTangent = true;
			SplinePoint.ArriveTangent = FVector::ZeroVector;
			SplinePoint.LeaveTangent = FVector::ZeroVector;

			Spline.SplinePoints.Add(SplinePoint);

//			Debug::DrawDebugLine(TraceStart, TraceEnd, FLinearColor::Green, 20.0, 0.0);
//			Debug::DrawDebugLine(TraceStart, TraceStart + TraceDirection * 300.0, FLinearColor::Red, 50.0, 0.0);
//			Debug::DrawDebugLine(TraceEnd, TraceEnd + HitResult.ImpactNormal * 300.0, FLinearColor::Blue, 5.0, 0.0);

			if(HitResult.Actor != nullptr)
			{
				auto ResponseComp = USanctuaryLightRayResponseComponent::Get(HitResult.Actor);
				if(ResponseComp != nullptr)
				{
					AffectedLightRayResponseComp = ResponseComp;
					ResponseComp.Illuminated(this);
				}
				else
				{
					if(AffectedLightRayResponseComp != nullptr)
					{
						AffectedLightRayResponseComp.StopIlluminate(this);
						AffectedLightRayResponseComp = nullptr;
					}
				}
			}
			

			if (HitResult.bBlockingHit && HitResult.Component.HasTag(n"Mirror"))
			{
				TraceDirection = TraceDirection.GetReflectionVector(HitResult.ImpactNormal);
				TraceStart = HitResult.Location + HitResult.ImpactNormal * 0.125;
				Bounces++;
			}
			else break;		
		}
	}
}