class ASummitPlatformMechanismAlpha : AHazeActor
{
UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetEndLoc;
	UPROPERTY(DefaultComponent, Attach = TargetEndLoc)
	UBillboardComponent EndVisual;
	default EndVisual.SetWorldScale3D(FVector(3.0));

	FVector StartLocation;

	UPROPERTY(EditAnywhere)
	APulleyInteraction PulleyAlpha;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = MeshRoot.RelativeLocation;

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.RelativeLocation = Math::Lerp(StartLocation, TargetEndLoc.RelativeLocation,PulleyAlpha.PullAlpha);
	//	MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetEndLoc.RelativeLocation, DeltaTime, ForwardSpeed);

	//	Print("" + PullProgress, 5.0);

		float Dist = (MeshRoot.RelativeLocation - TargetEndLoc.RelativeLocation).Size(); 
	}

};