class AFireworksRocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireworkTrail;
	default FireworkTrail.SetAutoActivate(false);

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UForceFeedbackEffect LaunchForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect ExplodeForceFeedback;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	AHazePlayerCharacter OwningPlayer;

	AMoonMarketHidingGhost Cody;

	float LifeTime = 2.0;
	float MoveSpeed = 4000.0;

	FVector LaunchDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		Cody = TListedActors<AMoonMarketHidingGhost>().Single;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += LaunchDirection * MoveSpeed * DeltaSeconds;
		LifeTime -= DeltaSeconds;

		FVector ToCody = Cody.ActorLocation - ActorLocation;
		if(ToCody.SizeSquared() < 2000 * 2000 && LaunchDirection.DotProduct(ToCody.GetSafeNormal()) > 0.96)
		{
			Cody.LastFireworkTime = Time::GameTimeSeconds;
		}

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(OwningPlayer);
		TraceSettings.IgnoreActor(this);

		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * 100.0);

		if (Hit.bBlockingHit || LifeTime <= 0.0)
		{
			if(Cast<AMoonMarketFollowBalloon>(Hit.Actor) != nullptr)
			{
				Cast<AMoonMarketFollowBalloon>(Hit.Actor).Pop(OwningPlayer);
			}
			else
			{
				UFireworksRocketEffectHandler::Trigger_OnRocketExplode(this, FMoonMarketFireworkRocketParams(ActorLocation, Hit.bBlockingHit));
			
				ForceFeedback::PlayWorldForceFeedback(ExplodeForceFeedback, ActorLocation, true, this, 800, 5000, 4, 10);
				Game::Mio.PlayForceFeedback(LaunchForceFeedback, false, true, this);
				Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 800.0, 5000.0);
				Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 800.0, 5000.0);
				MeshComp.SetVisibility(false);
				FireworkTrail.Deactivate();
				SetActorTickEnabled(false);

				FHazeTraceDebugSettings Debug;
				Debug.Duration = 10.0;
				FHazeTraceSettings ImpactTraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				ImpactTraceSettings.UseSphereShape(250.0);
				// ImpactTraceSettings.DebugDraw(Debug);
				ImpactTraceSettings.IgnoreActor(this);	
				FHitResultArray SphereHits = ImpactTraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + ActorForwardVector * 100.0);
				
				for (FHitResult SphereHit : SphereHits)
				{
					if (SphereHit.bBlockingHit)
					{
						if(SphereHit.Actor == nullptr)
							continue;
						
						auto ResponseComp = UFireworksResponseComponent::Get(SphereHit.Actor);
						if (ResponseComp != nullptr)
						{
							ResponseComp.ActivateFireworksResponse(this, SphereHit.ImpactPoint, OwningPlayer);
						}
						else	
						{
							AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(SphereHit.Actor);
							if (Player != nullptr)
							{
								auto ShapeHolder = UMoonMarketShapeshiftComponent::Get(Player).ShapeshiftShape;
								
								if(ShapeHolder == nullptr || ShapeHolder.CurrentShape == nullptr || UFireworksResponseComponent::Get(ShapeHolder.CurrentShape) == nullptr)
								{
									FVector Direction = (Player.ActorCenterLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
									Player.KillPlayer(FPlayerDeathDamageParams(Direction, 10.0), DeathEffect);
								}
								else if(UFireworksResponseComponent::Get(ShapeHolder.CurrentShape) != nullptr)
								{
									UFireworksResponseComponent::Get(ShapeHolder.CurrentShape).ActivateFireworksResponse(this, SphereHit.ImpactPoint, OwningPlayer);
								}
							}
						}
					}
				}

				Timer::SetTimer(this, n"DestroyFirework", 1.5);
			}
		}

		UFireworksRocketEffectHandler::Trigger_UpdateRocketLocationMoved(this, FMoonMarketFireworkRocketParams(ActorLocation, false));
	}

	void LaunchFirework(FVector Direction)
	{
		UFireworksRocketEffectHandler::Trigger_OnLaunched(this, FMoonMarketInteractingPlayerEventParams(OwningPlayer));
		LaunchDirection = Direction;
		OwningPlayer.PlayForceFeedback(LaunchForceFeedback, false, true, this);
		SetActorTickEnabled(true);
		FireworkTrail.Activate();
	}

	UFUNCTION()
	void DestroyFirework()
	{
		DestroyActor();
	}
};