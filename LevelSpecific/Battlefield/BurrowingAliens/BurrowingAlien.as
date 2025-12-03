event void FOnBurrowingAlienActivated();

class ABurrowingAlien : AHazeActor
{
	UPROPERTY()
	FOnBurrowingAlienActivated OnBurrowingAlienActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AlienBurrowerRoot;

	UPROPERTY(DefaultComponent, Attach = AlienBurrowerRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = AlienBurrowerRoot)
	UStaticMeshComponent DrillMeshComp;

	UPROPERTY(DefaultComponent, Attach = AlienBurrowerRoot)
	UDeathTriggerComponent DeathComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BurrowingAlienCapability");

	UPROPERTY(EditAnywhere)
	ABakedDestructionActor GlacierBlock;

	FVector EndLoc;

	UPROPERTY(EditAnywhere)
	float ActivateDistance = 12000.0;
	
	float ZOffset = -5000.0;
	float ZSpeed = 5000.0;
	float KillDistance = 1400.0;

	bool bActive;

	FVector BurrowEffectLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EndLoc = AlienBurrowerRoot.WorldLocation;
		BurrowEffectLoc = EndLoc;
		AlienBurrowerRoot.WorldLocation += AlienBurrowerRoot.UpVector * ZOffset;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DrillMeshComp.AddLocalRotation(FRotator(0.0, 360 * DeltaSeconds, 0.0));
	}

	UFUNCTION()
	void ActivateAlienBurrower()
	{
		bActive = true;

		if (GlacierBlock != nullptr)
			GlacierBlock.StartDestructible();
		
		FBurrowingAlienOnActivatedParams Params;
		Params.Location = BurrowEffectLoc;
		UBurrowingAlienEffectHandler::Trigger_OnBurrowActivated(this, Params);
		SetActorTickEnabled(true);
		OnBurrowingAlienActivated.Broadcast();
	}

	bool CanActivate()
	{
		if (!bActive)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (GetDistanceTo(Player) < ActivateDistance)
					return true;
			}
		}

		return false;
	}
}