event void FOnSeekerDestroy(ASkylineSentryBossMissile Seeker);

class ASkylineSentryBossMissile : AWhipSlingableObject
{
	FOnSeekerDestroy OnSeekerDestroy; 

	UPROPERTY(DefaultComponent)
	USkylineSentryBossAlignmentComponent AlignmentComp;

	UPROPERTY(DefaultComponent)
	USkylineSentryBossSphericalMovementComponent SphericalMovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossAlignMovementCapability");

	UPROPERTY(DefaultComponent, Attach = Collision)
	UBoxComponent TriggerBox;



	UPROPERTY()
	UNiagaraSystem NiagaraSystem;

	AHazeActor Target;
	bool bActivated;
	float LifeTime = 15;
	float TimeToSelfDestruct;

	bool bHasBeenGrabbed;
	bool bHasBeenThrown;

	ASKylineSentryBoss Boss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		TimeToSelfDestruct = Time::GameTimeSeconds + LifeTime;

		//GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseBoxShape(TriggerBox);
		TraceSettings.IgnoreActor(this);

		FHitResultArray HitArray = TraceSettings.QueryTraceMulti(TriggerBox.WorldLocation, TriggerBox.WorldLocation + ActorForwardVector);

		for(FHitResult Hit : HitArray)
		{
			if(Hit.bBlockingHit)
			{

				if(Hit.Component == Boss.ShutterCollision)
				{
					Boss.Shutter.ActivateShutter();
					Print("!");
					Explode();
				}

				if(bHasBeenThrown)
					Explode();

				if(Hit.Actor != Game::Mio)
					return;

				Explode();

			}
		}

		if(bHasBeenGrabbed)
			return;

		if(TimeToSelfDestruct > Time::GameTimeSeconds)
			return;

		Explode();
	}



	void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents) override
	{
		Super::OnGrabbed(UserComponent, TargetComponent, OtherComponents);
		
		if(bHasBeenGrabbed)
			return;

		BlockCapabilities(n"AlignMovement", this);
		bHasBeenGrabbed = true;
	}

	void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent,
				  FHitResult HitResult, FVector Impulse) override
	{
		Super::OnThrown(UserComponent, TargetComponent, HitResult, Impulse);
		bHasBeenThrown = true;
	}

	void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraSystem, ActorLocation, ActorRotation);
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		OnSeekerDestroy.Broadcast(this);

	}
}