class AQuarryCatapultProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	AQuarryCatapult Catapult;
	
	float Gravity;

	FVector Velocity;


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Velocity -= FVector(0.0, 0.0, Gravity * DeltaSeconds);
		ActorLocation += Velocity * DeltaSeconds;
	}

	UFUNCTION()
	private void OnComponentHit(UPrimitiveComponent HitComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, FVector NormalImpulse, const FHitResult&in Hit)
	{

		MeshComp.SetHiddenInGame(true);
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
	
}