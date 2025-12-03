
UCLASS(Abstract)
class ABuildingBlocks : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent GhostMesh;

	FVector StartLocation;
	FVector TargetLocation;
	FVector CurrentLocation;

	AActor StartLocationActor;
	bool bStartLocationSet = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bStartLocationSet == false)
		{
			if(StartLocationActor != nullptr)
			{
				SetActorLocation(StartLocationActor.GetActorLocation());
				bStartLocationSet = true;
			}
		}
	}

	UFUNCTION()
	void SetUp(AActor AttachTarget)
	{
		//AttachToActor(AttachTarget, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION()
	void PlaceBlock()
	{
		BlockPlacedBlueprint();
	}

	UFUNCTION(BlueprintEvent)
	void BlockPlacedBlueprint(){}
}

