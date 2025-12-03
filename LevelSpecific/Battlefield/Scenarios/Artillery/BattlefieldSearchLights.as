class ABattlefieldSearchLights : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LightRoot;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6.0));
#endif

	UPROPERTY(DefaultComponent, Attach = LightRoot)
	USpotLightComponent SpotLight;

	UPROPERTY(EditAnywhere)
	float TotalDistance = 30000.0;

	UPROPERTY(EditAnywhere)
	float StartDistance = 0.0;

	UPROPERTY(EditAnywhere)
	float SpeedMultiplier = 1.0;

	float CurrentDistance;

	FVector StartPos;
	FVector LookDir;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LookDir = ActorForwardVector.ConstrainToPlane(FVector::UpVector);
		StartPos = ActorLocation + LookDir * 20000.0;
		StartPos -= FVector::UpVector * 25000.0;
		CurrentDistance = StartDistance;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Multiplier = 1.0 + Math::Sin((Time::GameTimeSeconds * SpeedMultiplier) + ((StartDistance / TotalDistance) * 2.0));
		
		CurrentDistance = TotalDistance * Multiplier;
		FVector LookLoc = StartPos + LookDir * CurrentDistance;
		FVector Dir = (LookLoc - LightRoot.WorldLocation).GetSafeNormal();
		LightRoot.WorldRotation = FRotator::MakeFromX(Dir);

		// Debug::DrawDebugSphere(LookLoc, 800.0, 12, FLinearColor::Red, 80.0);
		// Debug::DrawDebugLine(ActorLocation, LookLoc, FLinearColor::Red, 250.0);
	}

	UFUNCTION()
	void StartSearchlight()
	{
		BP_SearchLightStarted();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SearchLightStarted() {}
}