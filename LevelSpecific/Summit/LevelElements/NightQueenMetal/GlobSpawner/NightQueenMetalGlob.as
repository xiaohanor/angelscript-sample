event void FOnNightQueenGlobDestroyed(ANightQueenMetalGlob Glob);

class ANightQueenMetalGlob : ANightQueenMetal
{
	FOnNightQueenGlobDestroyed OnNightQueenGlobDestroyed;

	UPROPERTY(Category = "Settings")
	float Gravity = 1000.0;

	UPROPERTY(Category = "Settings")
	float GravityAcceleration = 4000.0;

	UPROPERTY(Category = "Settings")
	float LifeTime = 5.0;

	float EndLifeTime;

	FVector VerticalVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		EndLifeTime = Time::GameTimeSeconds + LifeTime;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		VerticalVelocity -= FVector(0.0, 0.0, Gravity * DeltaTime);
		VerticalVelocity = VerticalVelocity.GetClampedToSize(0.0, GravityAcceleration);
		ActorLocation += VerticalVelocity * DeltaTime;

		OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");

		FHazeTraceDebugSettings Debug;
		Debug.TraceColor = FLinearColor::Red;
		Debug.Thickness = 5.0;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseSphereShape(230.0);
		TraceSettings.IgnoreActor(this);
		TraceSettings.DebugDraw(Debug);
		FHitResult Hit;

		Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + -FVector::UpVector);

		if (Hit.bBlockingHit)
		{
			ATeenDragon TeenDragon = Cast<ATeenDragon>(Hit.Actor);
			
			if (TeenDragon != nullptr)
				OnNightQueenGlobDestroyed.Broadcast(this);
		}

		if (Time::GameTimeSeconds > EndLifeTime)
				OnNightQueenGlobDestroyed.Broadcast(this);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		OnNightQueenGlobDestroyed.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		SetMeltedMaterials(0.0);
		SetDissolveMaterials(0.0);
	}
}