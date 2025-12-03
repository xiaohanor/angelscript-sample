class ASnakeHook : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HookPivot;

	UPROPERTY(DefaultComponent, Attach = HookPivot)
	USphereComponent HookTrigger;

	UPROPERTY(DefaultComponent, Attach = HookPivot)
	UStaticMeshComponent HookMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RopePivot;

	UPROPERTY(DefaultComponent, Attach = RopePivot)
	UStaticMeshComponent RopeMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ChainAttachLocation;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor ElevatorMeshActor;
	
	FVector ActorStartLocation;

	float Length = 0;
	float LiftHeight = 0;
	float StartLength = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLength = (HookMesh.WorldLocation - ChainAttachLocation.WorldLocation).Size();
		HookTrigger.OnComponentBeginOverlap.AddUFunction(this, n"HandleHookBeginOverlap");
		ActorStartLocation = ElevatorMeshActor.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RopeMesh.WorldScale3D = FVector(0.2, 0.2, (HookMesh.WorldLocation - ChainAttachLocation.WorldLocation).Size() * 0.01);
		RopeMesh.WorldLocation = HookPivot.WorldLocation;
		RopePivot.WorldRotation = (HookPivot.WorldLocation - ChainAttachLocation.WorldLocation).Rotation();
	}

	UFUNCTION()
	private void HandleHookBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		ALightSeeker LightWorm = Cast<ALightSeeker>(OtherActor);

		if (IsValid(LightWorm))
		{
			if (OtherComp.HasTag(n"Hookable"))
			{
				HookPivot.AttachToComponent(LightWorm.SkeletalMesh, n"Head", EAttachmentRule::KeepWorld);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Length = (HookMesh.WorldLocation - ChainAttachLocation.WorldLocation).Size();

		//LiftHeight = Math::Max(0.0, Length - StartLength);
		LiftHeight = Length - StartLength;
		
		PrintToScreen("LiftHeight" + Length);

		RopeMesh.WorldScale3D = FVector(0.2, 0.2, Length * 0.01);
		RopeMesh.WorldLocation = HookPivot.WorldLocation;
		RopePivot.WorldRotation = (HookPivot.WorldLocation - ChainAttachLocation.WorldLocation).Rotation();

		ElevatorMeshActor.SetActorLocation(ActorStartLocation + FVector::UpVector * LiftHeight * 0.5);
	}
};