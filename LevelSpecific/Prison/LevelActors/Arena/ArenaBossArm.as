UCLASS(Abstract)
class AArenaBossArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	UHazeSkeletalMeshComponentBase ArmMeshComp;

	UPROPERTY(DefaultComponent, Attach = ArmMeshComp, AttachSocket = "RightForeArm")
	USceneComponent SmashLocationComp;

	AArenaBoss ExecutionerActor;

	bool bRipping = false;
	bool bRaising = false;
	bool bSmashing = false;
	bool bLowering = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExecutionerActor = Cast<AArenaBoss>(AttachParentActor);
	}

	void SmashTriggered(float Height)
	{
		FVector SmashLoc = SmashLocationComp.WorldLocation;
		SmashLoc.Z = Height;

		BP_SmashTriggered(SmashLoc);
	}

	UFUNCTION(BlueprintEvent)
	void BP_SmashTriggered(FVector Location) {}
}