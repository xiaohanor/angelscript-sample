
class ALightProjectileTargetActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.CollisionProfileName = n"EnemyCharacter";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	ULightProjectileTargetComponent TargetComponent;

	UPROPERTY(DefaultComponent)
	ULightProjectileResponseComponent ResponseComponent;
	
	UPROPERTY(EditAnywhere, Category = "Light")
	FVector Axis = FVector::RightVector;

	UPROPERTY(EditAnywhere, Category = "Light")
	float Speed = 2.0;

	UPROPERTY(EditAnywhere, Category = "Light")
	float Distance = 250.0;

	FHazeAcceleratedVector Offset;

	private FVector InitialLocation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Axis = Axis.GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialLocation = ActorLocation;

		ResponseComponent.OnHit.AddUFunction(this, n"HandleHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const FVector Movement = Axis * Math::Sin(Time::GameTimeSeconds * Speed) * Distance;
		Offset.SpringTo(FVector::ZeroVector, 100.0, 0.0, DeltaTime);
		ActorLocation = InitialLocation + Movement + Offset.Value;
	}

	UFUNCTION()
	private void HandleHit(FLightProjectileHitData HitData)
	{
		Offset.SnapTo(-HitData.Normal * 50.0);

		Debug::DrawDebugLine(
			HitData.Location,
			HitData.Location + HitData.Normal * 250.0,
			FLinearColor::Yellow,
			Duration = 5.0
		);
	}
}