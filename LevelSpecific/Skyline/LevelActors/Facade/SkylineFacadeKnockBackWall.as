class ASkylineFacadeKnockBackWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent)
	UArrowComponent KnockbackDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"HandleBoxOverlap");
	}

	UFUNCTION()
	private void HandleBoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                              const FHitResult&in SweepResult)
	{

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player==nullptr)
			return;

		Player.SetActorVelocity(FVector(0.0,0.0,0.0));
		Player.ApplyKnockdown(KnockbackDirection.ForwardVector * 1500.0, 3.0);
		Player.DamagePlayerHealth(0.1);
		
		
		
	}
};