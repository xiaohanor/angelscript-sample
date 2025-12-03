class ADragonRunTailDragon : ADragonRunPlayerDragon
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	UAnimSequence SmashModeAnim;

	UPROPERTY()
	UAnimSequence Gliding;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UAdultDragonTailSmashModeSettings Settings;

	float SmashTime;
	float SmashDuration = 3.0;

	bool bRunAttack;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Settings = UAdultDragonTailSmashModeSettings::GetSettings(Game::Zoe);
		OnDragonRunActivateAttack.AddUFunction(this, n"OnDragonRunActivateAttack");
		PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Gliding);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if (!bRunAttack)
			return;

		HandleImpacts();

		if (Time::GameTimeSeconds > SmashTime)
		{
			bRunAttack = false;
			PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Gliding);
		}
	}

	UFUNCTION()
	private void OnDragonRunActivateAttack(AActor Target)
	{
		PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), SmashModeAnim);
		SmashTime = Time::GameTimeSeconds + SmashDuration;
		bRunAttack = true;
	}	

	void HandleImpacts()
	{
		FHazeTraceDebugSettings TraceDebug;
		TraceDebug.Thickness = 2.0;
		TraceDebug.TraceColor = FLinearColor::Red;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		TraceSettings.UseSphereShape(500.0);
		TraceSettings.IgnoreActor(this);
		TraceSettings.IgnoreActor(OtherDragon);
		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);
		TraceSettings.DebugDraw(TraceDebug);

		FHitResultArray Hits = TraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + ActorForwardVector * 1.0);

		for (FHitResult Hit : Hits)
		{
			if (Hit.bBlockingHit)
			{
				FTailSmashModeHitParams HitParams;
				HitParams.HitComponent = Hit.Component;
				HitParams.ImpactLocation = Hit.ImpactPoint;
				HitParams.FlyingDirection = ActorForwardVector;
				HitParams.DamageDealt = Settings.ImpactDamage;

				if(HitParams.HitComponent == nullptr)
					return;

				auto ReponseComp = UAdultDragonTailSmashModeResponseComponent::Get(HitParams.HitComponent.Owner);
				
				if(ReponseComp != nullptr)
					CrumbSendHit(HitParams, ReponseComp);
			}
		}
	}

	void CrumbSendHit(FTailSmashModeHitParams Params, UAdultDragonTailSmashModeResponseComponent HitComp)
	{
		HitComp.ActivateSmashModeHit(Params);
		Game::Mio.PlayWorldCameraShake(ImpactCameraShake, this, ActorLocation, 1500.0, 8000.0);
		Game::Zoe.PlayWorldCameraShake(ImpactCameraShake, this, ActorLocation, 1500.0, 8000.0);
	}
}