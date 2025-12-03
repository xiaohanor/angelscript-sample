class ASanctuaryWeeperSlingShot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent RotateRoot;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent MeshRoot;


	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USphereComponent ExplodeCollision;	

	UPROPERTY(EditAnywhere)
	ASanctuaryWeeperLightBirdSocket Socket;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionNiagara;



	bool bIsLaunched;
	float LaunchSpeed = 2000;
	FVector Velocity;
	
	float MaxDistance = 4500;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Socket.OnActivated.AddUFunction(this, n"OnActivated");
		// Socket.OnDeactivated.AddUFunction(this, n"OnDeactivated");

		DarkPortalResponseComp.OnReleased.AddUFunction(this, n"OnReleased");
		DarkPortalResponseComp.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		
		Socket.AttachToComponent(MeshRoot);
	}



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsLaunched)
			return;

		MeshRoot.AddWorldOffset(Velocity * DeltaSeconds);

		float Distance = (ActorLocation - MeshRoot.WorldLocation).Size();

		if(Distance >= MaxDistance)
		{
			Return();
		}
	}


	UFUNCTION()
	private void OnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		// MeshRoot.WorldRotation = Portal.ActorRotation;
		// Debug::DrawDebugLine(Portal.ActorLocation, Portal.ActorForwardVector * 100, FLinearColor::Red, 10, 3);

		MeshRoot.MaxX = 0;
	}

	UFUNCTION()
	private void OnReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bIsLaunched = true;
		Velocity = ActorForwardVector * LaunchSpeed;
		MeshRoot.MaxX = 10000;
	}

	UFUNCTION()
	private void OnActivated(ASanctuaryWeeperLightBird LightBird)
	{
		if(!bIsLaunched)
			return;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		TraceSettings.UseSphereShape(ExplodeCollision);
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActor(this);

		auto HitResultArray = TraceSettings.QueryTraceMulti(MeshRoot.WorldLocation, MeshRoot.WorldLocation + MeshRoot.ForwardVector);

		for(FHitResult Hit : HitResultArray)
		{
			if(Hit.bBlockingHit)
			{
				AAISanctuaryWeeper2D Weeper = Cast<AAISanctuaryWeeper2D>(Hit.Actor);
				if(Weeper != nullptr)
				{
					Weeper.HealthComp.TakeDamage(Weeper.HealthComp.MaxHealth, EDamageType::Explosion, this);
				}

			}
		}
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionNiagara, MeshRoot.WorldLocation);
		

		Return();
	}

	void Return()
	{
		bIsLaunched = false;
		MeshRoot.WorldLocation = ActorLocation;
	}
	// UFUNCTION()
	// private void OnDeactivated(ASanctuaryWeeperLightBird LightBird)
	// {
	// }

	


};