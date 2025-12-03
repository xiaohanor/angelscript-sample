class USanctuaryLightOrbPulseComponent : UActorComponent
{

	ASanctuaryLightOrb Orb;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem PulseNiagara;

	UPROPERTY(EditAnywhere)
	float PulseRange = 500;

	UPROPERTY(EditAnywhere)
	float PulseForce = 10;

	float ActivationCooldown = 0.25;
	float TimeAtActivation;

	bool bIsOnCooldown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Orb = Cast<ASanctuaryLightOrb>(Owner);

		Orb.OnActivated.AddUFunction(this, n"OnActivated");
		Orb.OnDeactivated.AddUFunction(this, n"OnDeactivated");
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsOnCooldown)
			return;

		if(Time::GameTimeSeconds > TimeAtActivation + ActivationCooldown)
			bIsOnCooldown = false;
	}


	UFUNCTION()
	private void OnActivated()
	{
		if(bIsOnCooldown)
			return;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		TraceSettings.UseSphereShape(PulseRange);
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActor(Owner);

		auto HitResultArray = TraceSettings.QueryTraceMulti(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorForwardVector);
		Debug::DrawDebugSphere(Owner.ActorLocation, PulseRange, 12, FLinearColor::Blue, 10, 0.25);

		for(FHitResult Hit : HitResultArray)
		{
			if(Hit.bBlockingHit)
			{
				auto ResponseComp = USanctuaryLightOrbPulseResponseComponent::Get(Hit.Actor);
				if(ResponseComp != nullptr)
				{
					ResponseComp.AddImpulse(Owner.ActorLocation, PulseForce);
				}
			}
		}
		Niagara::SpawnOneShotNiagaraSystemAtLocation(PulseNiagara, Owner.ActorLocation);

		TimeAtActivation = Time::GameTimeSeconds;
		bIsOnCooldown = true;
	}

	UFUNCTION()
	private void OnDeactivated()
	{
	}
};