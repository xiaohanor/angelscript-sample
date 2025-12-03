asset SanctuaryBossHydraSettings of USanctuaryBossHydraSettings
{
}

enum ESanctuaryBossHydraAttackType
{
	None,
	Smash,
	FireBall,
	FireBreath
}

enum ESanctuaryBossHydraIdentifier
{
	BottomLeft = 0,
	BottomCenter = 1,
	BottomRight = 2,
	TopLeft = 3,
	TopRight = 4,
	MAX = 5 // TODO: Rename to Any, kind of valid for automatic pick
}

enum ESanctuaryHydraBossPhase
{
	Traversal,
	Skydive,
	Platforms
}

class ASanctuaryBossHydraHead : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadPivot;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuaryBossHydraCompoundCapability");

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	ULocomotionFeatureHydraBoss LocomotionFeature;
	
#if EDITOR
	UPROPERTY(DefaultComponent)
	USanctuaryBossHydraEditorComponent EditorComp;
#endif

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hydra")
	ESanctuaryBossHydraIdentifier Identifier;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hydra")
	ESanctuaryHydraBossPhase Phase;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hydra")
	USanctuaryBossHydraSettings Settings = SanctuaryBossHydraSettings;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Hydra")
	FSanctuaryBossHydraAnimationData AnimationData;

	ASanctuaryBossHydraBase HydraBase;
	FTransform RelativeHeadTransform;
	FHazeRuntimeSpline RuntimeSpline;
	FHazeAcceleratedVector AcceleratedLocation;
	FHazeAcceleratedQuat AcceleratedQuat;
	float HeadLength;

	FVector FireBreathStartLocation;
	FVector FireBreathEndLocation;

	FVector TargetLocation;
	USanctuaryBossHydraAttackData AttackData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplySettings(Settings, this);

		HydraBase = Cast<ASanctuaryBossHydraBase>(AttachParentActor);
		RelativeHeadTransform = HeadPivot.RelativeTransform;
		AcceleratedLocation.SnapTo(HeadPivot.WorldLocation);
		AcceleratedQuat.SnapTo(HeadPivot.WorldRotation.Quaternion());
		AnimationData.Phase = Phase;

		if (SkeletalMesh != nullptr && SkeletalMesh.SkeletalMeshAsset != nullptr)
			HeadLength = SkeletalMesh.GetDistanceBetweenBones(n"Head", n"Orbicularis");
	}

	void UpdateMeshSpline()
	{
		RuntimeSpline = FHazeRuntimeSpline();
		RuntimeSpline.AddPoint(Root.WorldLocation);
		RuntimeSpline.AddPoint(HeadPivot.WorldLocation);

		TArray<FVector> UpDirections;
		UpDirections.Add(-Root.ForwardVector);
		UpDirections.Add(HeadPivot.UpVector);
		RuntimeSpline.UpDirections = UpDirections;
		
		RuntimeSpline.SetCustomEnterTangentPoint(Root.WorldLocation - Root.UpVector);
		RuntimeSpline.SetCustomExitTangentPoint(HeadPivot.WorldLocation + HeadPivot.ForwardVector);
	}

	USanctuaryBossHydraAttackData ConsumeAttackData()
	{
		auto ConsumedAttackData = AttackData;
		AttackData = nullptr;
		return ConsumedAttackData;
	}

	bool HasAttackData() const
	{
		if (AttackData == nullptr)
			return false;
		if (!AttackData.IsValid())
			return false;

		return true;
	}

	FTransform GetIdleTransform() const
	{
		FTransform WorldTransform = HeadTransform;
		FVector IdleLocation = WorldTransform.Location;
		FQuat IdleRotation = WorldTransform.Rotation;

		if (!Settings.bDisableCodeHeadOffset)
		{
			float LocationOffsetScale = 1.0;
			float RotationOffsetScale = 1.0;

			// if (TargetPlatform != nullptr)
			{
				LocationOffsetScale = 0.35;
				RotationOffsetScale = 0.2;
				IdleRotation = (TargetLocation - WorldTransform.Location).ToOrientationQuat();
			}

			float UniqueNumber = PI / (int(Identifier) + 1);

			FVector LocationOffset = FVector(
				Math::Cos(UniqueNumber + Time::GameTimeSeconds * 0.25) * 1000.0 * LocationOffsetScale,
				0.0,
				Math::Sin(UniqueNumber - Time::GameTimeSeconds) * 500.0 * LocationOffsetScale
			);

			FQuat RotationOffset = FRotator(
				Math::Cos(UniqueNumber + Time::GameTimeSeconds) * 5.0 * RotationOffsetScale,
				Math::Sin(UniqueNumber - Time::GameTimeSeconds * 0.65) * 10.0 * RotationOffsetScale,
				Math::Sin(UniqueNumber + Time::GameTimeSeconds * 0.5) * 10.0 * RotationOffsetScale,
			).Quaternion();

			IdleRotation *= RotationOffset.Inverse();
			IdleLocation += LocationOffset;
		}

		return FTransform(
			IdleRotation,
			IdleLocation
		);
	}

	FTransform GetHeadTransform() const property
	{
		return RelativeHeadTransform * Root.WorldTransform;
	}

	FTransform GetBaseTransform() const property
	{
		if (Root.AttachParent != nullptr)
			return Root.AttachParent.WorldTransform;

		return Root.WorldTransform;
	}

	bool IsHeadCenter() const
	{
		return Identifier == ESanctuaryBossHydraIdentifier::BottomCenter;
	}

	bool IsHeadLeft() const
	{
		return Identifier == ESanctuaryBossHydraIdentifier::BottomLeft || Identifier == ESanctuaryBossHydraIdentifier::TopLeft;
	}

	bool IsHeadRight() const
	{
		return Identifier == ESanctuaryBossHydraIdentifier::BottomRight || Identifier == ESanctuaryBossHydraIdentifier::TopRight;
	}

	UFUNCTION(DevFunction)
	void EnqueueSmash()
	{
		float ClosestDistance = MAX_flt;
		AHazePlayerCharacter ClosestPlayer = nullptr;
		USceneComponent PlatformComponent = nullptr;
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			float DistanceSqr = Player.ActorCenterLocation.DistSquared(HeadPivot.WorldLocation);
			if (ClosestPlayer == nullptr || DistanceSqr < ClosestDistance)
			{
				auto MoveComp = UHazeMovementComponent::Get(Player);
				auto GroundImpact = MoveComp.GetGroundContact();

				USceneComponent TargetComponent = nullptr;
				if (GroundImpact.Actor != nullptr)
					TargetComponent = USanctuaryBossHydraPlatformComponent::Get(GroundImpact.Actor);
				if (TargetComponent == nullptr)
					TargetComponent = GroundImpact.Component;

				if (TargetComponent != nullptr)
				{
					ClosestPlayer = Player;
					PlatformComponent = TargetComponent;
				}
			}
		}

		if (ClosestPlayer == nullptr || PlatformComponent == nullptr)
			return;

		HydraBase.TriggerSmash(PlatformComponent.WorldLocation, PlatformComponent, Identifier = Identifier);
	}

	UFUNCTION(DevFunction)
	void EnqueueFireBreath()
	{
		float ClosestDistance = MAX_flt;
		AHazePlayerCharacter ClosestPlayer = nullptr;
		USceneComponent PlatformComponent = nullptr;
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			float DistanceSqr = Player.ActorCenterLocation.DistSquared(HeadPivot.WorldLocation);
			if (ClosestPlayer == nullptr || DistanceSqr < ClosestDistance)
			{
				auto MoveComp = UHazeMovementComponent::Get(Player);
				auto GroundImpact = MoveComp.GetGroundContact();

				USceneComponent TargetComponent = nullptr;
				if (GroundImpact.Actor != nullptr)
					TargetComponent = USanctuaryBossHydraPlatformComponent::Get(GroundImpact.Actor);
				if (TargetComponent == nullptr)
					TargetComponent = GroundImpact.Component;

				if (TargetComponent != nullptr)
				{
					ClosestPlayer = Player;
					PlatformComponent = TargetComponent;
				}
			}
		}

		if (ClosestPlayer == nullptr || PlatformComponent == nullptr)
			return;

		// This all just simulates what we did before using splines, since we don't have any splines
		//  available to us when using the dev function, testing use so don't matter how ugly it is :^)
		FVector ToBase = (PlatformComponent.WorldLocation - BaseTransform.Location);
		FVector ToBaseConstrained = ToBase.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		float OffsetDistance = HeadLength + 500.0;
		FVector HeadLocation = PlatformComponent.WorldLocation - (ToBaseConstrained * OffsetDistance);

		float SweepAngle = 60.0;
		FVector LeftForward = ToBaseConstrained.RotateAngleAxis(-SweepAngle * 0.5, FVector::UpVector);
		FVector RightForward = ToBaseConstrained.RotateAngleAxis(SweepAngle * 0.5, FVector::UpVector);

		FHazeRuntimeSpline HeadSpline;
		HeadSpline.AddPoint(HeadLocation);

		FHazeRuntimeSpline TargetSpline;
		TargetSpline.AddPoint(HeadLocation + LeftForward * OffsetDistance);
		TargetSpline.AddPoint(HeadLocation + RightForward * OffsetDistance);

		HydraBase.TriggerFireBreath(HeadSpline, TargetSpline, PlatformComponent, bInfiniteHeight = true, Identifier = Identifier);
	}
}