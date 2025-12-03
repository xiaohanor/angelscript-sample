class AFlameAttackPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndPoint;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent StartVisual;
	default StartVisual.SetWorldScale3D(FVector(10.0));

	UPROPERTY(DefaultComponent, Attach = EndPoint)
	UBillboardComponent EndVisual;
	default EndVisual.SetWorldScale3D(FVector(10.0));
#endif	

	FVector FlamePoint;

	float Speed = 5500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FlamePoint = ActorLocation;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FlamePoint = Math::VInterpConstantTo(FlamePoint, EndPoint.WorldLocation, DeltaSeconds, Speed);
		// Debug::DrawDebugSphere(FlamePoint, 200.0, LineColor = FLinearColor::Red);
		// PrintToScreen("FlamePoint: " + FlamePoint);
		// PrintToScreen("WorldLocation: " + EndPoint.WorldLocation);
	}

	void ActivateFlameAttack()
	{
		FlamePoint = ActorLocation;
		SetActorTickEnabled(true);
	}

	void DeactivateFlameAttack()
	{
		SetActorTickEnabled(false);
	}

	float GetAlphaProgress()
	{
		float TotalDist = (ActorLocation - EndPoint.WorldLocation).Size();
		float CurrentDist = (FlamePoint - EndPoint.WorldLocation).Size();
		return 1.0 - (CurrentDist / TotalDist);
	}

	bool ReachedEndPoint()
	{
		return (FlamePoint - EndPoint.WorldLocation).Size() < 5.0;
	}
}