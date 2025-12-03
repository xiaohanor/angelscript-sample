class AJetskiClosingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor AlarmLight01;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor AlarmLight02;

	float MaxDistance;
	float MinDistance = 0.0;

	FVector DoorStartLoc = FVector::ZeroVector;
	FVector DoorEndLoc = FVector(0, 0, -2500);

	float PreviousAlpha = 0;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivateAlarmLight(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AHazePlayerCharacter ClosestPlayer = Game::GetClosestPlayer(ActorLocation);
		float Distance = (ClosestPlayer.ActorLocation - ActorLocation).Size2D();

		float Alpha = Math::GetMappedRangeValueClamped(FVector2D(MaxDistance, MinDistance), FVector2D(0, 1), Distance);

		if(Alpha < PreviousAlpha)
			Alpha = PreviousAlpha;

		PreviousAlpha = Alpha;

		MeshRoot.SetRelativeLocation(Math::Lerp(DoorStartLoc, DoorEndLoc, Alpha));
	}

	UFUNCTION()
	void ActivateClosingDoor()
	{
		AHazePlayerCharacter ClosestPlayer = Game::GetClosestPlayer(ActorLocation);
		MaxDistance = (ClosestPlayer.ActorLocation - ActorLocation).Size2D();

		SetActorTickEnabled(true);
		ActivateAlarmLight(true);
	}

	void ActivateAlarmLight(bool bShouldBeActive)
	{
		float PanningX = bShouldBeActive ? 1 : 0;
		FVector EmissiveTint = bShouldBeActive ? FVector(400, 0, 0) : FVector::ZeroVector;

		AlarmLight01.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveTint", EmissiveTint);
		AlarmLight01.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"PanningX", PanningX);
		AlarmLight02.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveTint", EmissiveTint);
		AlarmLight02.StaticMeshComponent.SetScalarParameterValueOnMaterialIndex(0, n"PanningX", PanningX);
	}
};