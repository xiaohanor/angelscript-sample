enum EGameShowArenaWallRunRotationFacingDirection
{
	Up,
	Right,
	Left
};

struct FGameShowArenaWallRunRotationParams
{
	FGameShowArenaWallRunRotationParams(EGameShowArenaWallRunRotationFacingDirection InDirection, float InDuration)
	{
		Direction = InDirection;
		Duration = InDuration;
	}
	EGameShowArenaWallRunRotationFacingDirection Direction;
	float Duration;
}

class AGameShowArenaWallRun : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseRailingRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRailingRoot)
	UStaticMeshComponent BaseRailing;

	UPROPERTY(DefaultComponent, Attach = BaseRailingRoot)
	USceneComponent RailingRoot;

	UPROPERTY(DefaultComponent, Attach = RailingRoot)
	UStaticMeshComponent RailingMesh;

	UPROPERTY(DefaultComponent, Attach = RailingRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGameShowArenaHeightAdjustableComponent HeightAdjustableComp;

	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UBoxComponent BoxCollision;
	default BoxCollision.AddTag(ComponentTags::WallRunnable);
	default BoxCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	FRotator PlatformUpFacingRotation = FRotator(0, 0, 0);
	FRotator PlatformRightFacingRotation = FRotator(0, 0, 90);
	FRotator PlatformLeftFacingRotation = FRotator(0, 0, -90);

	TArray<FGameShowArenaWallRunRotationParams> RotationParamsQueue;
	EGameShowArenaWallRunRotationFacingDirection CurrentFacingDirection = EGameShowArenaWallRunRotationFacingDirection::Up;
	int TargetRotationParamsIndex = 0;

	float MoveTimer = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MoveTimer += DeltaSeconds;
		auto TargetRotationParams = RotationParamsQueue[TargetRotationParamsIndex];
		FQuat StartRotation = GetRotationForDirection(CurrentFacingDirection).Quaternion();
		FQuat TargetRotation = GetRotationForDirection(TargetRotationParams.Direction).Quaternion();
		float Alpha = Math::Saturate(MoveTimer / TargetRotationParams.Duration);

		FQuat NewRotation = FQuat::Slerp(StartRotation, TargetRotation, Alpha);
		RailingRoot.SetRelativeRotation(NewRotation);

		if (MoveTimer >= TargetRotationParams.Duration)
		{
			MoveTimer = 0;
			CurrentFacingDirection = TargetRotationParams.Direction;
			TargetRotationParamsIndex++;
			if (TargetRotationParamsIndex < RotationParamsQueue.Num())
			{
				TargetRotationParams = RotationParamsQueue[TargetRotationParamsIndex];
			}
			else
			{
				SetActorTickEnabled(false);
				TargetRotationParamsIndex = 0;
				RotationParamsQueue.Reset();
			}
		}
	}

	FRotator GetRotationForDirection(EGameShowArenaWallRunRotationFacingDirection FacingDirection)
	{
		switch (FacingDirection)
		{
			case EGameShowArenaWallRunRotationFacingDirection::Up:
				return PlatformUpFacingRotation;
			case EGameShowArenaWallRunRotationFacingDirection::Right:
				return PlatformRightFacingRotation;
			case EGameShowArenaWallRunRotationFacingDirection::Left:
				return PlatformLeftFacingRotation;
			default:
				return FRotator::ZeroRotator;
		}
	}

	UFUNCTION(DevFunction)
	void StartRotatingToFacingDirection(EGameShowArenaWallRunRotationFacingDirection FacingDirection, float Duration)
	{
		if (FacingDirection == CurrentFacingDirection)
			return;

		switch (FacingDirection)
		{
			case EGameShowArenaWallRunRotationFacingDirection::Up:
				RotationParamsQueue.Add(FGameShowArenaWallRunRotationParams(EGameShowArenaWallRunRotationFacingDirection::Up, Duration));
				break;
			case EGameShowArenaWallRunRotationFacingDirection::Right:
				if (CurrentFacingDirection == EGameShowArenaWallRunRotationFacingDirection::Up)
					RotationParamsQueue.Add(FGameShowArenaWallRunRotationParams(EGameShowArenaWallRunRotationFacingDirection::Right, Duration));
				else
				{
					RotationParamsQueue.Add(FGameShowArenaWallRunRotationParams(EGameShowArenaWallRunRotationFacingDirection::Up, Duration * 0.5));
					RotationParamsQueue.Add(FGameShowArenaWallRunRotationParams(EGameShowArenaWallRunRotationFacingDirection::Right, Duration * 0.5));
				}
				break;
			case EGameShowArenaWallRunRotationFacingDirection::Left:
				if (CurrentFacingDirection == EGameShowArenaWallRunRotationFacingDirection::Up)
					RotationParamsQueue.Add(FGameShowArenaWallRunRotationParams(EGameShowArenaWallRunRotationFacingDirection::Left, Duration));
				else
				{
					RotationParamsQueue.Add(FGameShowArenaWallRunRotationParams(EGameShowArenaWallRunRotationFacingDirection::Up, Duration * 0.5));
					RotationParamsQueue.Add(FGameShowArenaWallRunRotationParams(EGameShowArenaWallRunRotationFacingDirection::Left, Duration * 0.5));
				}
				break;
		}

		SetActorTickEnabled(true);
	}
};