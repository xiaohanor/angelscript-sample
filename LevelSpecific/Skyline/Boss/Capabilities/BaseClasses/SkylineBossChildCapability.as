UCLASS(Abstract)
class USkylineBossChildCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(SkylineBossTags::SkylineBoss);

	ASkylineBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASkylineBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	void AlignWithHub(ASkylineBossSplineHub Hub, float DeltaTime)
	{
		check(HasControl());

		FVector FallTowardsDirection = -Hub.ActorRightVector;

		if(Boss.AnimData.FallDirection == ESkylineBossFallDirection::FromCenter)
			FallTowardsDirection = -Hub.ActorForwardVector;

		if(Boss.GetPhase() == ESkylineBossPhase::First)
			FallTowardsDirection = Hub.ActorForwardVector;

		FQuat TargetRotation = FQuat::MakeFromXZ(FallTowardsDirection, Hub.ActorUpVector);

		FVector TargetHorizontalLocation = Hub.ActorLocation + FVector::UpVector * Boss.Settings.BaseHeight;
		FVector HorizontalLocation = Math::VInterpConstantTo(Boss.ActorLocation, TargetHorizontalLocation, DeltaTime, 6000);
		FQuat Rotation = Math::QInterpConstantTo(Boss.ActorQuat, TargetRotation, DeltaTime, 1);

		Boss.SetActorLocationAndRotation(HorizontalLocation, Rotation);
	}

	void ApplyCrumbSyncedPosition()
	{
		check(!HasControl());

		const FHazeSyncedActorPosition& ActorPosition = Boss.SyncedActorPositionComp.GetPosition();

		Boss.SetActorLocationAndRotation(
			ActorPosition.WorldLocation,
			ActorPosition.WorldRotation
		);

		Boss.SetActorVelocity(ActorPosition.WorldVelocity);
	}

	void ApplyCrumbSyncedHeadPivotRotation()
	{
		check(!HasControl());
		
		Boss.HeadPivot.SetWorldRotation(Boss.SyncedHeadPivotRotationComp.Value);
	}
}