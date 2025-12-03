class ASummitObstaclePendulum : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;
	default Root.SetWorldScale3D(FVector(5.0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(EditAnywhere)
	TArray<AActor> AttachActors;

	UPROPERTY(EditAnywhere)
	float AngleSwing = 40.0;

	UPROPERTY(EditAnywhere)
	bool bStartNegative;

	FHazeAcceleratedRotator AccelRot;
	float MinAngle = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AActor Actor : AttachActors)
		{
			Actor.AttachToComponent(RotationRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		}

		AccelRot.SnapTo(ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float AngleMultiplier = Math::Sin(Time::GameTimeSeconds * 2.5);
		float AngleTarget = AngleSwing * AngleMultiplier;

		RotationRoot.RelativeRotation = FRotator(0.0, 0.0, AngleTarget);
	}
}