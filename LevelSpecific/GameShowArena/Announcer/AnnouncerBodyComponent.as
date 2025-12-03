struct FGameShowAnnouncerPistonExtensionData
{
	float LowerPistonExtension;
	float UpperPistonExtension;
}

class UGameShowArenaAnnouncerBodyComponent : UActorComponent
{
	AGameShowArenaAnnouncer Announcer;

	FHazeAcceleratedVector AccArm13ControlLocation;
	FHazeAcceleratedRotator AccHeadControlRotation;
	FHazeAcceleratedFloat AccLowerExtend;
	FHazeAcceleratedFloat AccUpperExtend;
	FHazeAcceleratedFloat AccBaseRotation;
	FHazeAcceleratedRotator AccBodyRotation;
	FHazeAcceleratedVector AccArm8ControlLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Announcer = Cast<AGameShowArenaAnnouncer>(Owner);
	}

	FTransform GetArm1Transform() const property
	{
		return Announcer.SkeletalMeshComp.GetBoneTransform(n"Arm1");
	}
	FTransform GetArm3Transform() const property
	{
		return Announcer.SkeletalMeshComp.GetBoneTransform(n"Arm3");
	}
	FTransform GetArm7Transform() const property
	{
		return Announcer.SkeletalMeshComp.GetBoneTransform(n"Arm7");
	}
	FTransform GetArm8Transform() const property
	{
		return Announcer.SkeletalMeshComp.GetBoneTransform(n"Arm8");
	}
	FTransform GetArm12Transform() const property
	{
		return Announcer.SkeletalMeshComp.GetBoneTransform(n"Arm12");
	}
	FTransform GetArm13Transform() const property
	{
		return Announcer.SkeletalMeshComp.GetBoneTransform(n"Arm13");
	}

	void CopyValuesFromAnnouncer()
	{
		AccBaseRotation.SnapTo(Announcer.BaseTwist);
		AccLowerExtend.SnapTo(Announcer.LowerPistonExtend);
		AccUpperExtend.SnapTo(Announcer.UpperPistonExtend);
		AccBodyRotation.SnapTo(Math::RotatorFromAxisAndAngle(FVector::UpVector, Announcer.BodyRotation));
		AccHeadControlRotation.SnapTo(Announcer.IKArm13Ctrl.Rotator());
		AccArm13ControlLocation.SnapTo(Announcer.IKArm13Ctrl.Location);
		AccArm8ControlLocation.SnapTo(Announcer.IKArm8CtrlLocation);
	}

	FVector GetDesiredArm8Location(AHazeActor Target)
	{
		FTransform Arm3World = Arm3Transform;
		FTransform Arm7World = Arm7Transform;
		FVector ToTarget = (Target.ActorLocation - Arm3World.Location).GetSafeNormal().VectorPlaneProject(-Announcer.ActorUpVector);

		float ForwardDist = (Arm3World.Location - Target.ActorLocation).DotProduct(Arm3World.Rotation.ForwardVector);
		float MaxOffset = 3000;
		float Arm7Offset = Math::GetMappedRangeValueClamped(FVector2D(0, MaxOffset), FVector2D(-MaxOffset, MaxOffset), ForwardDist);
		FVector Arm7MidPoint = Arm7World.Location + ToTarget * Arm7Offset;
		return Arm7World.InverseTransformPositionNoScale(Arm7MidPoint);
	}

	float GetDesiredAngleToTarget(AHazeActor Target)
	{
		FVector BaseToTarget = (Target.ActorLocation - Announcer.ActorLocation).GetSafeNormal();
		FVector ProjectedBaseToTarget = BaseToTarget.VectorPlaneProject(-Announcer.ActorUpVector);
		float Angle = -Announcer.ActorForwardVector.GetAngleDegreesTo(ProjectedBaseToTarget);
		return Angle;
	}

	FRotator GetDesiredBodyRotationToTarget(AHazeActor Target)
	{
		FTransform WorldArm8 = Arm8Transform;
		FVector BodyToTarget = (Target.ActorLocation - WorldArm8.Location).VectorPlaneProject(WorldArm8.Rotation.UpVector);

		float Dot = (WorldArm8.Rotation.RightVector).DotProduct(BodyToTarget.GetSafeNormal2D());
		float Deg = (-WorldArm8.Rotation.ForwardVector).GetAngleDegreesTo(BodyToTarget);

		if (Dot > 0)
			Deg = 360 - Deg;

		return Math::RotatorFromAxisAndAngle(FVector::UpVector, Deg);
	}

	FTransform GetDesiredHeadTransform(AHazeActor Target)
	{
		FTransform WorldArm12 = Arm12Transform;
		FVector BaseToTarget = (Target.ActorLocation - Announcer.ActorLocation).GetSafeNormal();

		FVector MidPoint = Target.ActorLocation - (BaseToTarget * 2500);
		FVector TargetControlLocation = WorldArm12.InverseTransformPositionNoScale(MidPoint);

		FVector ToTarget = (Target.ActorLocation - WorldArm12.Location).GetSafeNormal();
		FVector DesiredLookDir = ToTarget;
		FVector LookDir = WorldArm12.InverseTransformVectorNoScale(DesiredLookDir);
		float ConeHalfAngleRadians = PI * 0.45;
		FVector ConeDirection = WorldArm12.InverseTransformVectorNoScale(WorldArm12.Rotation.UpVector);
		LookDir = LookDir.ConstrainToCone(ConeDirection, ConeHalfAngleRadians);
		FRotator Rotation = FRotator::MakeFromZX(LookDir, FVector::DownVector);
		Rotation.Pitch = Math::ClampAngle(Rotation.Pitch, -85, 85);
		return FTransform(Rotation, TargetControlLocation);
	}

	FGameShowAnnouncerPistonExtensionData GetDesiredPistonExtensions(AHazeActor Target, float DistanceNoise)
	{
		FVector TargetLocation = Target.ActorLocation;

		float Dist = Math::Abs(TargetLocation.Z - Announcer.ActorLocation.Z);
		float DesiredLower = Math::GetMappedRangeValueClamped(FVector2D(6500, 10000), Announcer.LowerPistonRange, Dist + DistanceNoise);
		float DesiredUpper = Math::GetMappedRangeValueClamped(FVector2D(6500, 10000), Announcer.UpperPistonRange, Dist + DistanceNoise);
		FGameShowAnnouncerPistonExtensionData Data;
		Data.LowerPistonExtension = DesiredLower;
		Data.UpperPistonExtension = DesiredUpper;
		return Data;
	}

};