class ASkylineFlyingCarEnemyShipEngine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASkylineFlyingCarEnemy EnemyShip;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;
	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComponent;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttacherOwnerComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeUserWidget> WarningWidgetClass;

	UHazeUserWidget WarningWidget;

	float CurrentDistanceToTarget = BIG_NUMBER; 

	float EngineCounter;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent WorldCollision;
	default WorldCollision.SetRelativeRotation(FRotator(90.0, 0.0, 0.0));
	default WorldCollision.CapsuleHalfHeight = 400.0;
	default WorldCollision.CapsuleRadius = 200.0;
	default WorldCollision.SetCollisionProfileName(n"BlockAllDynamic");
	default WorldCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EngineCounter=0;

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivate");

		HealthComponent.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		EnemyShip.OnEnemyEnabled.AddUFunction(this, n"HandleShipEnabled");

		

		AddActorDisable(this);
	
	}

	UFUNCTION()
	private void HandleShipEnabled()
	{
		RemoveActorDisable(this);
		WarningWidget = Game::Mio.AddWidget(WarningWidgetClass);
		WarningWidget.AttachWidgetToActor(this);
		WarningWidget.AttachWidgetToComponent(RifleTargetableComponent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
					
	}

	UFUNCTION()
	private void HandleActivate(AActor Caller)
	{
		EngineCounter++;
	}



	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                          EDamageType DamageType)
	{
		

		if (HealthComponent.IsDead())
		{
			InterfaceComp.TriggerActivate();

			if(EngineCounter==1)
			{
				EnemyShip.Explode();
			}

			Explode();
			
			
		}
		else
		{
			FFlyingCarEnemyDamageData DamageData;
			DamageData.DamageAmount = Damage;
			DamageData.RemainingHealth = HealthComponent.CurrentHealth;

			UFlyingCarEnemyEventHandler::Trigger_OnTakeDamage(this, DamageData);
		}
	}

	void Explode()
	{
			if(WarningWidget != nullptr)
		{
			Game::Mio.RemoveWidget(WarningWidget);
			WarningWidget = nullptr;
		}
		Niagara::SpawnOneShotNiagaraSystemAttached(ExplosionVFX, RifleTargetableComponent);
		AddActorDisable(this);
	}
};