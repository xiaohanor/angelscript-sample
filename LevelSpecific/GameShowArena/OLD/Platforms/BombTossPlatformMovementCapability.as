class UBombTossPlatformMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	ABombToss_Platform Platform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ABombToss_Platform>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Platform.bShouldBeMoving)
			return false;

		if (Time::GameTimeSeconds < Platform.TimeWhenShouldStartMoving)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Platform.bShouldBeMoving)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Platform.ForceUpdateCollision();
		// Platform.TranslateComp.ApplyImpulse(Platform.TranslateComp.WorldLocation, Platform.PlatformMesh.UpVector * 100);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (Platform.ActorNameOrLabel.Contains("60"))
		// 	Print("Cool", 0);
		// check(!Name.ToString().Contains("233"));
		float MovementAlpha = Math::Saturate(ActiveDuration / Platform.LayoutMoveData.MoveDuration);
		FVector CurrentBaseRailingLoc = Math::Lerp(Platform.CurrentPositionValues.BaseRailingRootLoc, Platform.TargetPositionValues.BaseRailingRootLoc, Platform.WiggleCurve.GetFloatValue(MovementAlpha));
		FQuat CurrentBaseRailingRot = FQuat::Slerp(Platform.CurrentPositionValues.BaseRailingRootRot.Quaternion(), Platform.TargetPositionValues.BaseRailingRootRot.Quaternion(), MovementAlpha);
		FQuat CurrentPlatformMeshRootRot = FQuat::Slerp(Platform.CurrentPositionValues.PlatformMeshRootRot.Quaternion(), Platform.TargetPositionValues.PlatformMeshRootRot.Quaternion(), MovementAlpha);
		FQuat CurrentRailingRootRot = FQuat::Slerp(Platform.CurrentPositionValues.RailingRootRot.Quaternion(), Platform.TargetPositionValues.RailingRootRot.Quaternion(), MovementAlpha);

		Platform.BaseRailingRoot.SetRelativeLocation(CurrentBaseRailingLoc);
		Platform.BaseRailingRoot.SetRelativeRotation(CurrentBaseRailingRot);
		Platform.PlatformMeshRoot.SetRelativeRotation(CurrentPlatformMeshRootRot);
		Platform.RailingRoot.SetRelativeRotation(CurrentRailingRootRot);

		if (MovementAlpha >= 1.0)
		{
			Platform.bShouldBeMoving = false;
			Platform.CurrentPositionValues = Platform.TargetPositionValues;
		}
	}
};