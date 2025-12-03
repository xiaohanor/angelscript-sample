class AIslandWalkerLegPoison : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent Gas;
	default Gas.SetFloatParameter(n"VelocityMulti", 2);
	default Gas.SetFloatParameter(n"SpriteSizeMin", 500);
	default Gas.SetFloatParameter(n"SpriteSizeMax", 600);
	default Gas.SetFloatParameter(n"SpawnRate", 45.0);
	default Gas.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent Box;

	TArray<AActor> OverlapTargets;
	float StartTime;
	float Duration = 5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Gas.SetFloatParameter(n"VelocityMulti", 2);
		Gas.SetFloatParameter(n"SpriteSizeMin", 500);
		Gas.SetFloatParameter(n"SpriteSizeMax", 600);
		Gas.SetFloatParameter(n"SpawnRate", 45.0);

		Gas.OnSystemFinished.AddUFunction(this, n"Finished");

		Box.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
		Box.OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");

		StartTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	private void BeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                     UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                     const FHitResult&in SweepResult)
	{
		OverlapTargets.Add(OtherActor);
	}

	UFUNCTION()
	private void EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		OverlapTargets.Remove(OtherActor);
	}

	UFUNCTION()
	private void Finished(UNiagaraComponent PSystem)
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(AActor Target: OverlapTargets)
		{
			auto UserComp = UIslandPlayerForceFieldUserComponent::Get(Target);
			if(UserComp != nullptr)
				UserComp.TakeDamagePoison(DeltaSeconds, 0.4, 1);
		}

		if(Time::GetGameTimeSince(StartTime) > Duration)
			Gas.Deactivate();
	}
}