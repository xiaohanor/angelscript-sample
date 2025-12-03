event void FSandSharkTrapGateOperatorSignature();

class ASandSharkTrapGateOperator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent MainMesh;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent RopeMesh;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent LeftHandleMesh;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent RightHandleMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDesertCrankInteractionComponent LeftInteractionComp;
	default LeftInteractionComp.bIsRightSideCrank = false;
	default LeftInteractionComp.RelativeLocation = FVector(-58, -118, 0);

	UPROPERTY(DefaultComponent, Attach = Root)
	UDesertCrankInteractionComponent RightInteractionComp;
	default RightInteractionComp.bIsRightSideCrank = true;
	default RightInteractionComp.RelativeLocation = FVector(-58, 118, 0);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
}