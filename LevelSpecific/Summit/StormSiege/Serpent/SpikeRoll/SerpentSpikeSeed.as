UCLASS(Abstract)
class ASerpentSpikeSeed : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TracePoint;

	ASerpentSpike TargetSpike;
	FHazeAcceleratedVector AcceleratedLocation;

	bool bIsActive = false;

	float TimeWhenActivated = 0;

	const float MoveDuration = 1;
	float MoveSpeed = 30000.0;
	float AllowedEffectImpactRate = 0.2;

	bool bDestroyOnImpacts;

	UFUNCTION()
	void StartMovingTowardsSpike(ASerpentSpike SpikeToTarget)
	{
		TargetSpike = SpikeToTarget;
		FRotator NewRotation = FRotator::MakeFromZ(TargetSpike.ActorLocation - ActorLocation);
		SetActorRotation(NewRotation);

		bIsActive = true;
		TimeWhenActivated = Time::GameTimeSeconds;
		AcceleratedLocation.SnapTo(ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// TODO: Replace with capabilities
		if (!bIsActive)
			return;

		float DistanceTo = (ActorLocation - TargetSpike.ActorLocation).Size();
		
		if (DistanceTo <= MoveSpeed * DeltaSeconds)
		{
			ActorLocation = TargetSpike.ActorLocation;
			TargetSpike.ActivateSpike();
			USerpentSpikeSeedEffectHandler::Trigger_OnSpikeImpacted(this, FSerpentSpikeSeedImpactParams(TracePoint.WorldLocation));
			CustomDisableSeed();
		}
		else
		{
			SetActorLocation(Math::VInterpConstantTo(ActorLocation, TargetSpike.ActorLocation, DeltaSeconds, MoveSpeed));
		}

		if (!bDestroyOnImpacts)
			return;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnoreActor(this);
		TraceSettings.UseLine();

		FVector TaceOffset = TracePoint.WorldLocation + (TargetSpike.ActorLocation - TracePoint.WorldLocation).GetSafeNormal() * MoveSpeed * DeltaSeconds;
		FHitResult Hit = TraceSettings.QueryTraceSingle(TracePoint.WorldLocation, TaceOffset);
		
		if (Hit.bBlockingHit)
		{
			Print(f"{Hit.Actor.Name=}");
			USerpentSpikeSeedEffectHandler::Trigger_OnSpikeImpacted(this, FSerpentSpikeSeedImpactParams(Hit.ImpactPoint));
			
			auto SeedResponse = USerpentSpikeSeedResponseComponent::Get(Hit.Actor);
			if (SeedResponse != nullptr)
				SeedResponse.ActivateSpikeSeedHit();
			
			CustomDisableSeed();
		}
	}

	void CustomDisableSeed()
	{
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
	}
};
