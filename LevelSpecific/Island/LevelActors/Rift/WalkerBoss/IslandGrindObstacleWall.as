event void FIslandGrindObstacleWallSignature();

class AIslandGrindObstacleWall : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent DeathCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;
	
	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditAnywhere)
	AIslandGrindObstacleListener ListenerRef;

	UPROPERTY()
	float Damage = 1.0;

	bool bCanKillPlayer = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");

		if (ListenerRef != nullptr)
			ListenerRef.OnCompleted.AddUFunction(this, n"HandleCompleted");

	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (!bCanKillPlayer)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Player.DamagePlayerHealth(Damage);

	}

	UFUNCTION()
	void HandleCompleted()
	{
		bCanKillPlayer = false;
		BP_OnDeactivated();
		ListenerRef.ForceActivateLights();
	}


	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated() {}

}
