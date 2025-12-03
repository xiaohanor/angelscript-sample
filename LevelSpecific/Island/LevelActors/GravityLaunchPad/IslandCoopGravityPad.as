class AIslandCoopGravityPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerBox;
	default PlayerBox.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent InteractionMesh;

	UPROPERTY(DefaultComponent, Attach = InteractionMesh)
	UIslandRedBlueImpactShieldResponseComponent ShieldComponent;
	
	UPROPERTY(EditAnywhere)
	EIslandRedBlueWeaponType BlockColor;

	AHazePlayerCharacter LastPlayerImpacter;

	AHazePlayerCharacter PlayerChar;

    UPROPERTY(EditAnywhere)
    float ForwardForce = 200;
    UPROPERTY(EditAnywhere)
    float UpForce = 2000.0;
	UPROPERTY(EditAnywhere)
    bool bUseTimer = true;
	UPROPERTY(EditAnywhere)
    float ActiveInterval = .2;
	float ActiveIntervalTimer = ActiveInterval;

	bool bIsActive;
	bool bMioOn;
	bool bZoeOn;
	float DelayUntilReactivation = .5;
	float MioDelay = DelayUntilReactivation;
	float ZoeDelay = DelayUntilReactivation;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerBox.OnComponentBeginOverlap.AddUFunction(this, n"ImpulseCollider");
		PlayerBox.OnComponentEndOverlap.AddUFunction(this, n"ImpulseColliderExit");
		ShieldComponent.OnImpactWhenShieldDestroyed.AddUFunction(this, n"HandleImpactShieldDestroyed");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActive)
			return;

		if (bUseTimer)
		{
			ActiveIntervalTimer = ActiveIntervalTimer - DeltaSeconds;
			if (ActiveIntervalTimer <= 0)
			{
				Deactivate();
			}
		}

		if (!bMioOn && !bZoeOn)
			return;

		if (bMioOn)
		{
			MioDelay = MioDelay - DeltaSeconds;
			if (MioDelay <= 0) {
				bMioOn = false;
				MioDelay = DelayUntilReactivation;
			}
		}

		if (bZoeOn)
		{
			ZoeDelay = ZoeDelay - DeltaSeconds;
			if (ZoeDelay <= 0) {
				bZoeOn = false;
				ZoeDelay = DelayUntilReactivation;
			}
		}

	}

	UFUNCTION()
	void HandleImpactShieldDestroyed(FIslandRedBlueImpactShieldResponseParams Data)
	{
		if (bIsActive)
		return;

		LastPlayerImpacter = Data.Player;
		bIsActive = true;
		BP_Activated();
	}

	UFUNCTION()
	private void ImpulseCollider(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{

		PlayerChar = Cast<AHazePlayerCharacter>(OtherActor);
		if (PlayerChar == Game::GetMio()) {
			if (bMioOn)
				return;
			bMioOn = true;
		}
		else
		{
			if (bZoeOn)
				return;
			bZoeOn = true;
		}
			
		
	}

	UFUNCTION()
	private void ImpulseColliderExit(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                 UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		PlayerChar = nullptr;
		Deactivate();
	}

	UFUNCTION()
	void LaunchPlayer(AHazePlayerCharacter ActivePlayer)
	{
		if (!bIsActive)
			return;

		if (ActivePlayer == nullptr)
			return;

		ActivePlayer.SetActorVelocity(FVector::ZeroVector);
		FVector Impulse;
		Impulse += ActivePlayer.ActorForwardVector * ForwardForce;
		Impulse += ActivePlayer.ActorUpVector * UpForce;
		ActivePlayer.AddMovementImpulse(Impulse);
		ActivePlayer.ResetAirJumpUsage();
		ActivePlayer.ResetAirDashUsage();

	}

	UFUNCTION(BlueprintCallable)
	void Deactivate()
	{
		ActiveIntervalTimer = ActiveInterval;
		bIsActive = false;
		bMioOn = false;
		MioDelay = DelayUntilReactivation;
		bZoeOn = false;
		ZoeDelay = DelayUntilReactivation;
		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate()
	{}

}