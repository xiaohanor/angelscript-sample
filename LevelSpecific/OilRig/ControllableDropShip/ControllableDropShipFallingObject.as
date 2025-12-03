struct FControllableDropShipFallingObjectType
{
	UPROPERTY()
	UStaticMesh Mesh;

	UPROPERTY()
	float Scale = 4.0;

	UPROPERTY()
	FVector Offset = FVector(0.0, 0.0, -1600.0);
}

class AControllableDropShipFallingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ObjectRoot;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	UStaticMeshComponent ObjectMesh;

	UPROPERTY(DefaultComponent)
	UControllableDropShipFallingObjectComponent FallingObjectComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	float FallSpeed = 20000.0;
	float MinFallSpeed = 16000.0;
	float MaxFallSpeed = 22000.0;

	UPROPERTY(EditAnywhere)
	float FallDistance = 250000.0;

	UPROPERTY(EditAnywhere)
	float HorizontalDistanceMultiplier = 2.0;

	UPROPERTY(EditAnywhere)
	float RotationRate = 160.0;
	float MinRotationRate = 140.0;
	float MaxRotationRate = 200.0;

	float CurrentDistance = 0.0;

	bool bFalling = false;

	UPROPERTY(EditDefaultsOnly)
	TArray<FControllableDropShipFallingObjectType> ObjectTypes;

	UPROPERTY(EditAnywhere)
	int ObjectTypeIndex = -1;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		int Index = ObjectTypeIndex < 0 ? Math::RandRange(0, ObjectTypes.Num() - 1) : ObjectTypeIndex;
		FControllableDropShipFallingObjectType ObjectType = ObjectTypes[Index];
		ObjectMesh.SetStaticMesh(ObjectType.Mesh);
		ObjectMesh.SetRelativeScale3D(FVector(ObjectType.Scale));
		ObjectMesh.SetRelativeLocation(ObjectType.Offset);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ObjectRoot.SetRelativeRotation(FRotator(Math::RandRange(0.0, 360.0), Math::RandRange(0.0, 360.0), Math::RandRange(0.0, 360.0)));
		CurrentDistance = Math::RandRange(0.0, FallDistance);
		FallSpeed = Math::RandRange(MinFallSpeed, MaxFallSpeed);
		RotationRate = Math::RandRange(MinRotationRate, MaxRotationRate);

		ObjectMesh.SetRenderedForPlayer(Game::Zoe, false);
	}

	UFUNCTION()
	void StartFalling()
	{
		bFalling = true;
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bFalling)
			return;

		CurrentDistance += FallSpeed * DeltaTime;
		ObjectRoot.SetRelativeLocation(FVector(0.0, CurrentDistance * HorizontalDistanceMultiplier, -CurrentDistance));
		if (CurrentDistance >= FallDistance)
		{
			CurrentDistance = 0.0;
			ObjectRoot.SetRelativeLocation(FVector::ZeroVector);
		}

		ObjectRoot.AddLocalRotation(FRotator(RotationRate * 0.8 * DeltaTime, RotationRate * 0.4 * DeltaTime, RotationRate * DeltaTime));
	}

	void Crash()
	{
		BP_Crash();

		UControllableDropShipFallingObjectEventHandler::Trigger_DebrisImpact(this);			

		CurrentDistance = 0.0;
		ObjectRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Crash() {}
}

class AControllableDropShipFallingObjectManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(5.0);

	bool bActivated = false;

	UFUNCTION()
	void ActivateFallingObjects()
	{
		if (bActivated)
			return;

		bActivated = true;

		TArray<AControllableDropShipFallingObject> FallingObjects = TListedActors<AControllableDropShipFallingObject>().Array;
		for (AControllableDropShipFallingObject Object : FallingObjects)
		{
			Object.StartFalling();
		}
	}
}

class UControllableDropShipFallingObjectComponent : UActorComponent
{
	
}

#if EDITOR
class UControllableDropShipFallingObjectVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UControllableDropShipFallingObjectComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        AControllableDropShipFallingObject FallingObject = Cast<AControllableDropShipFallingObject>(Component.Owner);
        if (FallingObject == nullptr)
            return;

		DrawArrow(FallingObject.ActorLocation, FallingObject.ActorLocation - (FallingObject.ObjectRoot.UpVector * FallingObject.FallDistance), FLinearColor::Purple, 50.0, 200.0);
    }
}
#endif

UCLASS(Abstract)
class UControllableDropShipFallingObjectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void DebrisImpact() {}
}