
UCLASS(Abstract)
class AGravityDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UBoxComponent Trigger;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent VFXSpawnLocation;

	UPROPERTY()	
	UNiagaraSystem DestructionVFX;

	UPROPERTY(EditAnywhere)
	TArray<AGravityDebris> LinkedPlatforms;

	UPROPERTY(EditAnywhere)
	float TimerUntilDestroyedFast = 6.0;
	UPROPERTY(EditAnywhere)
	float TimerUntilDestroyedSlow = 9.0;
	UPROPERTY(EditAnywhere)
	bool bTriggerAutoDestruction = true;
	bool bMioTriggerd = false;
	bool bZoeTriggerd = false;
	bool bDestructionTriggerd = false;
	bool bDestructionStarted = false;
	bool bExplosionsStarted = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMioTriggerd == true && bZoeTriggerd == true)
		{
			TimerUntilDestroyedFast -= DeltaSeconds;
			if(TimerUntilDestroyedFast <= 0)
			{
				bDestructionStarted = true;
			}
		}
		if(bMioTriggerd == true || bZoeTriggerd == true)
		{
			TimerUntilDestroyedSlow -= DeltaSeconds;
			if(TimerUntilDestroyedSlow <= 0)
			{
				bDestructionStarted = true;
			}
		}
		if(bDestructionStarted)
		{	
			if(bExplosionsStarted)
				return;
			
			StartDestruction();
		}
	}

	UFUNCTION()
	void EnableGravityDebris()
	{
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void OnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
	{
		if(bTriggerAutoDestruction == false)
			return;

		if(Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			if(OtherActor == Game::GetMio())
			{
				bMioTriggerd = true;
			}
			else
			{
				bZoeTriggerd = true;
			}
		}
	}
	UFUNCTION()
	void StartDestruction()
	{
		bExplosionsStarted = true;
		ActivateVFX();
		Timer::SetTimer(this, n"InstantlyDestroy", 3.0);
	}

	UFUNCTION()
	void InstantlyDestroy()
	{
		if(bDestructionTriggerd == true)
			return;

		bDestructionTriggerd = true;
		for (AGravityDebris GravityDebris : LinkedPlatforms)
		{
			if(GravityDebris != nullptr)
				GravityDebris.StartDestruction();
		}

		DestroyActor();
	}

	UFUNCTION()
	void ActivateVFX()
	{
		Timer::SetTimer(this, n"ActivateVFX", 1.0);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DestructionVFX, VFXSpawnLocation.GetWorldLocation(), VFXSpawnLocation.GetWorldRotation());
	}
}
