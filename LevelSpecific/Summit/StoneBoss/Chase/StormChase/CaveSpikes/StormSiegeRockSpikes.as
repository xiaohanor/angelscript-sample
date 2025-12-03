class AStormSiegeRockSpikes : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif	

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DirtFalling;
	default DirtFalling.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormSiegeSpikeActivationCapability");

	TArray<UStaticMeshComponent> MeshComps;
	TArray<FVector> OriginalPositions;

	float FallSpeed = 11000.0;
	float FallTime;
	float FallDuration = 5.0;
	float MinDelay = 1.2;
	float MaxDelay = 2.5;
	float StartTime;

	bool bStartedFalling;

	float ActivationDistance;
	float ActivationOffset = 21000.0;

	bool bCheckActivationDistances = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);

		for (UStaticMeshComponent Mesh : MeshComps)
			OriginalPositions.Add(Mesh.WorldLocation);

		Spline = SplineActor.Spline;
		ActivationDistance = Spline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		ActivationDistance -= ActivationOffset;

		SetActorTickEnabled(false);
	}

	//Move to capability later
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < StartTime)
			return;

		if (!bStartedFalling)
		{
			bStartedFalling = true;
			UStormSiegeRockSpikeEffectHandler::Trigger_EndFallingDust(this);
		}

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.WorldLocation -= ActorUpVector * FallSpeed * DeltaSeconds;
		}
	
		if (Time::GameTimeSeconds >= FallTime)
		{
			SetActorTickEnabled(false);
		}
	}

	void ActivateFallingSpikes()
	{
		bStartedFalling = false;

		int index = 0;

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetWorldLocation(OriginalPositions[index]);
			index++;
		}

		float DelayTime = Math::RandRange(MinDelay, MaxDelay);
		FallTime = Time::GameTimeSeconds + FallDuration + DelayTime;
		StartTime = Time::GameTimeSeconds + DelayTime;

		FStormSiegeRockSpikeDustParams Params;
		Params.Location = ActorLocation;
		Params.AttachComp = Root;
		UStormSiegeRockSpikeEffectHandler::Trigger_StartFallingDust(this, Params);

		SetActorTickEnabled(true);
	}
}