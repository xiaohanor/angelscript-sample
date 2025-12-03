UCLASS(Abstract)
class ASkylineBossProjectile : AHazeActor
{
	default InitialLifeSpan = 10.0;

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 50.0;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.GenerateOverlapEvents = false;

	UPROPERTY(EditDefaultsOnly)
	bool bUseLineTrace = false;

	FVector Velocity;

	UPROPERTY(EditDefaultsOnly)
	FVector Gravity = FVector::UpVector * -980.0;

	float Drag = 1.0;

	AHazeActor Target;

	TArray<AActor> ActorsToIgnore;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	void Move(FVector DeltaMove)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActors(ActorsToIgnore);
		Trace.IgnoreActor(this);

		if (!bUseLineTrace)
			Trace.UseSphereShape(Collision.GetScaledSphereRadius());

		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if (HitResult.bBlockingHit)
			HandleImpact(HitResult);
		else
			ActorLocation += DeltaMove;
	}

	void HandleImpact(FHitResult HitResult)
	{
		BP_OnImpact(HitResult);
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpact(FHitResult HitResult)
	{

	}
}