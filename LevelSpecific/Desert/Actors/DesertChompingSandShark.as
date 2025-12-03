class ADesertChompingSandShark : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SharkRoot;

	UPROPERTY(DefaultComponent, Attach = SharkRoot)
	UHazeSkeletalMeshComponentBase SharkSkelMesh;
	default SharkSkelMesh.bOverrideMinLod = true;
	default SharkSkelMesh.MinLodModel = 3;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ChompAnim;

	float TimeOffset = 0.0;
	float Yaw = 0.0;
	float RotationSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = ChompAnim;
		AnimParams.StartTime = Math::RandRange(0.0, ChompAnim.PlayLength);
		AnimParams.PlayRate = Math::RandRange(0.85, 1.15);
		AnimParams.BlendTime = 0.0;
		AnimParams.bLoop = true;
		SharkSkelMesh.PlaySlotAnimation(AnimParams);

		TimeOffset = Math::RandRange(0.0, 2.0);
		Yaw = Math::RandRange(0.0, 360.0);
		RotationSpeed = Math::RandRange(120.0, 180.0);
		RotationSpeed = Math::RandBool() ? RotationSpeed : -RotationSpeed;

		SetActorRotation(FRotator(0.0, Math::RandRange(0.0, 360.0), 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Time = Time::GetGameTimeSeconds() + TimeOffset;
		float Pitch = Math::Sin(Time * 4.0) * 10.0;
		float Roll = Math::Sin(Time * 3.0) * 5.0;
		Yaw += RotationSpeed * DeltaTime;
		Yaw = Math::Wrap(Yaw, 0.0, 360.0);
		SharkRoot.SetRelativeRotation(FRotator(Pitch, Yaw, Roll));

		float X = Math::Sin(Time * 5.0) * 30.0;
		float Y = Math::Sin(Time * 4.0) * 60.0;
		float Z = Math::Sin(Time * 6.0) * 50.0;
		SharkRoot.SetRelativeLocation(FVector(X, Y, Z));
	}
}