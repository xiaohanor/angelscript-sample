
class ABigCrackBirdNest : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent RootComp;
	default RootComp.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UBillboardComponent NavPoint;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BirdLandPoint;

	UPROPERTY(DefaultComponent)
	UBillboardComponent HoverPoint;

	UPROPERTY(DefaultComponent)
    UBigCrackBirdNestInteractionComponent Interaction;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	bool bUseNavPoint = false;

	ABigCrackBird Bird;

	float DistToPickupBird = 350;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector NavPointLoc = NavPoint.WorldLocation;
		NavPoint.SetAbsolute(true, true, true);
		NavPoint.SetWorldLocation(NavPointLoc);


		FVector LandPointLoc = BirdLandPoint.WorldLocation;
		BirdLandPoint.SetAbsolute(true, true, true);
		BirdLandPoint.SetWorldLocation(LandPointLoc);

		FVector HoverPointLoc = HoverPoint.WorldLocation;
		HoverPoint.SetAbsolute(true, true, true);
		HoverPoint.SetWorldLocation(HoverPointLoc);
	}
}