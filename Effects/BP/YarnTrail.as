
/**
 * Trace async and send that data to niagara.
 */

class AYarnTrail : AHazeNiagaraActor
{
	const float TraceRadius = 10.0;
	const float SpeedThreshold = Math::Square(0.01);

	FHitResult HitData;
	bool bValidHit = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const FVector Vel = AttachParentActor.GetActorVelocity();
		if(Vel.SizeSquared() > SpeedThreshold)
		{
			DoAsyncTrace();
		}

		FVector P = HitData.Location;
		FVector N = HitData.Normal;

		NiagaraComponent0.SetNiagaraVariableVec3("TraceImpactPoint", P);
		NiagaraComponent0.SetNiagaraVariableVec3("TraceImpactNormal", N);

		// Debug::DrawDebugSphere(P,TraceRadius, 4, FLinearColor::Yellow, Duration = 2.0);
		// Debug::DrawDebugArrow(P, P + N*1000.0, 100, FLinearColor::Yellow);

	}

	void DoAsyncTrace()
	{
		FVector Start = GetActorLocation();
		// FVector Start = GetActorCenterLocation();
		// Start += AttachParentActor.GetActorVelocity() * (1.0 / 60.0) * 10.0;
		// Start += FVector(0.0, 0.0, 1000.0);

		FVector End = Start;
		End -= FVector(0.0, 0.0, 2000.0);

		FCollisionQueryParams QueryParams;
		QueryParams.AddIgnoredActor(Game::Mio);
		QueryParams.AddIgnoredActor(Game::Zoe);

		AsyncTrace::AsyncSweepByChannel(
			EAsyncTraceType::Single,
			Start, End,
			FQuat::Identity,
			ECollisionChannel::ECC_Visibility,
			FCollisionShape::MakeSphere(TraceRadius),
			Params = QueryParams,
			InDelegate = FScriptTraceDelegate(this, n"OnTraceFinished"),
		);

		// AsyncTrace::AsyncLineTraceByChannel(
		// 	EAsyncTraceType::Single,
		// 	Start, End,
		// 	ECollisionChannel::ECC_Visibility,
		// 	Params = QueryParams,
		// 	InDelegate = FScriptTraceDelegate(this, n"OnTraceFinished"),
		// );
	}

	UFUNCTION()
	private void OnTraceFinished(uint64 TraceHandle, const TArray<FHitResult>&in OutHits, uint UserData)
	{
		bValidHit = false;
		for (const FHitResult& Hit : OutHits)
		{
			if (!Hit.bBlockingHit)
				continue;

			// Level streaming can cause the hit to be blocking, but the component and actor has been destroyed
			if(!IsValid(Hit.Component))
				continue;

			if (Hit.Component.IsAttachedTo(Game::Mio.RootComponent))
				continue;

			if (Hit.Component.IsAttachedTo(Game::Zoe.RootComponent))
				continue;

			HitData = Hit;
			bValidHit = true;

			break;
		}

	}

}