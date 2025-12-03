class ASoftSplitTurtlePlatforms : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = SciFiFallHeight)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = MeshComp_Scifi)
	UStaticMeshComponent SpinningSection;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UFauxPhysicsTranslateComponent SciFiFallHeight;

	UPROPERTY(DefaultComponent, Attach = MeshComp_Scifi)
	UFauxPhysicsWeightComponent SciFiWeight;

	UPROPERTY(DefaultComponent, Attach = ConeRotate)
	UStaticMeshComponent MeshComp_Fantasy;

	UPROPERTY(DefaultComponent, Attach = FallHeight)
	UFauxPhysicsConeRotateComponent ConeRotate;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsTranslateComponent FallHeight;

	UPROPERTY(DefaultComponent, Attach = MeshComp_Fantasy)
	UFauxPhysicsWeightComponent FantasyWeight;
	
	UPROPERTY(DefaultComponent, Attach = MeshComp_Scifi)
	UDeathTriggerComponent KillTrigger;
	default KillTrigger.bKillsMio = true;
	default KillTrigger.bKillsZoe = false;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeight;

	float Bounce;

	bool bShouldApplyForce;

	float BounceTime;

	float StartBounce;

	float Speed = -150;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		FallHeight.OnConstraintHit.AddUFunction(this, n"HitBottom");

		Timer::SetTimer(this, n"Kill", 22);
	}

	UFUNCTION()
	private void Kill()
	{
		USoftSplitTurtlePlatformEventHandler::Trigger_TurtleKill(this);
		DestroyActor();
	}

	UFUNCTION()
	private void HitBottom(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		bShouldApplyForce = true;
		BounceTime = 0.6;
		
		if (HitStrength > 1000)
			USoftSplitTurtlePlatformEventHandler::Trigger_TurtleDrop(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShouldApplyForce)
		{
			BounceTime += DeltaSeconds;
			StartBounce += DeltaSeconds;

				if(StartBounce >= 0.5 && Bounce > 0.0)
					Bounce -= DeltaSeconds * 0.1;
				else if (StartBounce < 0.5)
					Bounce += DeltaSeconds * 8.0;
				

			Bounce = Math::Clamp(Bounce, 0 , 1);

			FVector relaivelocationBounce = FVector(0,0,250 + ((Math::Sin(BounceTime * 4) * 100) - 75) * Math::EaseIn(0,1,Bounce, 2));	

			MeshComp_Fantasy.SetRelativeLocation(relaivelocationBounce);

		}

		SpinningSection.AddLocalRotation(FRotator(0,50,0) * DeltaSeconds);

		AddActorLocalOffset(FVector::ForwardVector * Speed * DeltaSeconds);
	}
};