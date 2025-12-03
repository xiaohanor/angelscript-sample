class ASanctuaryWeeperMagnifyingGlass : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent RotateRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Light1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Light2;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Light3;

	// UPROPERTY(DefaultComponent)
	// USanctuaryWeeperLightBirdResponseComponent ResponseComp;



	UPROPERTY(EditAnywhere)
	ASanctuaryWeeperLightBirdSocket Socket;

	UPROPERTY(EditAnywhere)
	UMaterialInstance LitMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInstance UnlitMaterial;

	bool bIsIlluminated;
	float LightBeamDuration = 1.5;
	float RechargeDuration = 2.5;

	float LightBeamTime;
	float RechargeTime;

	bool bIsRecharging;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// ResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		// ResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

		Socket.OnActivated.AddUFunction(this, n"OnActivated");
		Socket.OnDeactivated.AddUFunction(this, n"OnDeactivated");

		LightBeamTime = LightBeamDuration;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsRecharging)
		{
			RechargeTime -= DeltaSeconds;

			if(RechargeTime < RechargeDuration * 0.66 && Light3.GetMaterial(0) != LitMaterial)
				Light3.SetMaterial(0, LitMaterial);

			if(RechargeTime < RechargeDuration * 0.33 && Light2.GetMaterial(0) != LitMaterial)
				Light2.SetMaterial(0, LitMaterial);

			if(RechargeTime > 0)
				return;

			LightBeamTime = LightBeamDuration;
			bIsRecharging = false;
			Light1.SetMaterial(0, LitMaterial);
			// Light2.SetMaterial(0, LitMaterial);
			// Light3.SetMaterial(0, LitMaterial);
		}

		if(!bIsIlluminated)
			return;

		LightBeamTime -= DeltaSeconds;

		if(LightBeamTime < LightBeamDuration * 0.66 && Light1.GetMaterial(0) != UnlitMaterial)
			Light1.SetMaterial(0, UnlitMaterial);

		if(LightBeamTime < LightBeamDuration * 0.33 && Light2.GetMaterial(0) != UnlitMaterial)
			Light2.SetMaterial(0, UnlitMaterial);

		if(LightBeamTime <= 0)
		{
			bIsRecharging = true;
			RechargeTime = RechargeDuration;
			// Light1.SetMaterial(0, UnlitMaterial);
			// Light2.SetMaterial(0, UnlitMaterial);
			Light3.SetMaterial(0, UnlitMaterial);

			return;
		}

		// FVector Direction = (ActorLocation - LightBird.ActorLocation).SafeNormal;
		// float DotProduct = ActorForwardVector.DotProduct(Direction);
		
		// if(DotProduct < 0.5)
		// 	return;
		
		

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActor(this);

		auto HitResult = TraceSettings.QueryTraceSingle(MeshRoot.WorldLocation, MeshRoot.WorldLocation + MeshRoot.ForwardVector);
		Debug::DrawDebugLine(HitResult.TraceStart, HitResult.TraceStart + ActorForwardVector * 8000, FLinearColor::Yellow, 20, 0);

		if(HitResult.bBlockingHit)
		{
			AAISanctuaryWeeper2D Weeper = Cast<AAISanctuaryWeeper2D>(HitResult.Actor);
			if(Weeper == nullptr)
				return;

			Weeper.DestroyActor();
		}

	}

	UFUNCTION()
	private void OnActivated(ASanctuaryWeeperLightBird LightBird)
	{
		bIsIlluminated = true;
	}

	UFUNCTION()
	private void OnDeactivated(ASanctuaryWeeperLightBird LightBird)
	{
		bIsIlluminated = false;
	}

	// UFUNCTION()
	// private void OnIlluminated(ASanctuaryWeeperLightBird Bird)
	// {
	
	// 	bIsIlluminated = true;
	// 	LightBird = Bird;
	// }

	// UFUNCTION()
	// private void OnUnilluminated(ASanctuaryWeeperLightBird Bird)
	// {
	// 	bIsIlluminated = false;
	// }


};