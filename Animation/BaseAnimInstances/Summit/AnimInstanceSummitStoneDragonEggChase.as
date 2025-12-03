
class UAnimInstanceSummitStoneDragonEggChase : UHazeAnimInstanceBase
{

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ChaseStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData GroundMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData GroundShoot;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FlyToMountain;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData MountainMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData MountainShoot;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData FlyOffMountain;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData WallRun;

	ASummitEggStoneBeast EggBeast;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESummitEggBeastState EggBeastState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsShooting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HeadShootRotation;

	AActor Target;
	float TimeToUpdateTarget = 0;
	FHazeAcceleratedFloat HeadYawRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		EggBeast = Cast<ASummitEggStoneBeast>(HazeOwningActor);
		TimeToUpdateTarget = 0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (EggBeast == nullptr)
			return;

		EggBeastState = EggBeast.GetState();

		if (CheckValueChangedAndSetBool(bIsShooting, EggBeast.GetActionState() == ESummitEggBeastActionState::Shooting, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			HeadYawRotation.SnapTo(0);
		}

		if (bIsShooting)
		{
			TimeToUpdateTarget -= DeltaTime;
			if (TimeToUpdateTarget < 0 || Target == nullptr)
				UpdateAimTarget();

			HeadYawRotation.AccelerateTo(GetShootTargetRotation(), 1, DeltaTime);
			HeadShootRotation.Yaw = HeadYawRotation.Value;
		}
	}

	float GetShootTargetRotation()
	{
		if (Target != nullptr)
		{
			const FVector HeadLocation = OwningComponent.GetSocketLocation(n"Head");
			const FTransform AlignTransform = OwningComponent.GetSocketTransform(n"Align");

			return FRotator::MakeFromXZ(AlignTransform.InverseTransformVectorNoScale(Target.ActorLocation - HeadLocation), FVector::UpVector).Yaw;
		}
		return 0;
	}

	void UpdateAimTarget()
	{
		float MioSplineDist = EggBeast.PlayerPositionSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorCenterLocation);
		float ZoeSplineDist = EggBeast.PlayerPositionSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorCenterLocation);
		if (MioSplineDist < ZoeSplineDist && EggBeast.IsPlayerValid(Game::Mio))
			Target = Game::Mio;
		else if (EggBeast.IsPlayerValid(Game::Zoe))
			Target = Game::Zoe;

		TimeToUpdateTarget = 1;
	}
}