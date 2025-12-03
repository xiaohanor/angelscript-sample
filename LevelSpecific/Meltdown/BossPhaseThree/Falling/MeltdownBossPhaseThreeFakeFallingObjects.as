class AMeltdownBossPhaseThreeFakeFallingObjects : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent Collision;

	float PitchRot;
	float YawRot;
	float RollRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");

		PitchRot = Math::RandRange(10.0, 50.0);
		YawRot = Math::RandRange(10.0, 50.0);
		RollRot = Math::RandRange(10.0, 50.0);
	}

	// UFUNCTION()
	// private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	//                        UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	//                        const FHitResult&in SweepResult)
	// {
	// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

	// 	if(Player != nullptr)
	// 	Player.DamagePlayerHealth(0.5);
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(PitchRot,YawRot,RollRot) * DeltaSeconds);
		AddActorWorldOffset(FVector::UpVector * 4500.0 * DeltaSeconds);
	}

};