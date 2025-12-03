UCLASS(Abstract)
class ATrashCompactorGarbageTruckTrash : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TrashRoot;

	bool bFalling = false;

	FHazeAcceleratedFloat AccFallSpeed;
	float TargetFallSpeed = 2600.0;
	float MinFallSpeed = 1000.0;
	float MaxFallSpeed = 2200.0;

	AGarbageTruck OwningTruck;

	UFUNCTION()
	void StartFalling(AGarbageTruck Truck)
	{
		OwningTruck = Truck;
		TargetFallSpeed = Math::RandRange(MinFallSpeed, MaxFallSpeed);
		bFalling = true;

		SetActorEnableCollision(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bFalling)
			return;

		AccFallSpeed.AccelerateTo(TargetFallSpeed, 0.8, DeltaTime);
		FVector DeltaMove = -FVector::UpVector * AccFallSpeed.Value * DeltaTime;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnorePlayers();
		TraceSettings.IgnoreActor(OwningTruck);
		TraceSettings.IgnoreActor(this);
		TraceSettings.UseSphereShape(50.0);
		
		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation - DeltaMove);

		if (Hit.bBlockingHit)
		{
			Impact();
		}

		SetActorLocation(ActorLocation + DeltaMove);
		AddActorLocalRotation(FRotator(45.0 * DeltaTime, 60.0 * DeltaTime, 20.0 * DeltaTime));
	}

	void Impact()
	{
		AddActorDisable(this);
		bFalling = false;
		BP_Impact();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact() {}
}