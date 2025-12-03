class AQuarryCrane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(EditAnywhere)
	ASummitRollingWheel RollingWheel;

	UPROPERTY(EditAnywhere)
	bool bWheelShouldAttach;

	UPROPERTY(EditAnywhere)
	AActor ClimableWall;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 40.0;

	FHazeAcceleratedFloat AccelYawAmount;
	float YawTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");
		AccelYawAmount.SnapTo(0.0);

		if (ClimableWall != nullptr)
			ClimableWall.AttachToComponent(Root, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		
		if (RollingWheel != nullptr && bWheelShouldAttach)
			RollingWheel.AttachToComponent(Root, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION()
	private void OnWheelRolled(float Amount)
	{
		if (Amount > 0.0)
			YawTarget = RotationSpeed;
		else if (Amount < 0.0)
			YawTarget = -RotationSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AccelYawAmount.AccelerateTo(YawTarget * 0.5, 3.0, DeltaTime);
		AddActorWorldRotation(FRotator(0.0, AccelYawAmount.Value * DeltaTime, 0.0));
		YawTarget = 0.0;
	}
}