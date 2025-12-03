struct FGameShowPlatformGroup
{
	EBombTossPlatformPosition StartPosition;
	EBombTossPlatformPosition TargetPosition;

	FBombTossPlatformPositionValues StartPositionValues;
	FBombTossPlatformPositionValues TargetPositionValues;

	FGameShowPlatformGroup(EBombTossPlatformPosition InStartPosition, EBombTossPlatformPosition InTargetPosition, FBombTossPlatformPositionValues InStartPositionValues, FBombTossPlatformPositionValues InTargetPositionValues)
	{
		StartPosition = InStartPosition;
		TargetPosition = InTargetPosition;
		StartPositionValues = InStartPositionValues;
		TargetPositionValues = InTargetPositionValues;
	}
	TArray<ABombToss_Platform> Platforms;
}

class UGameShowArenaPlatformManagerMovingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	AGameShowArenaPlatformManager Manager;

	TArray<FGameShowPlatformGroup> PlatformGroups;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AGameShowArenaPlatformManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Manager.bIsMovingPlatforms)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Manager.PlatformMoveDuration)
			return true;

		return false;
	}

	void AddPlatformToGroup(ABombToss_Platform Platform, EBombTossPlatformPosition StartPosition, EBombTossPlatformPosition TargetPosition)
	{
		for (int i = 0; i < PlatformGroups.Num(); i++)
		{
			if (PlatformGroups[i].StartPosition == StartPosition && PlatformGroups[i].TargetPosition == TargetPosition)
			{
				PlatformGroups[i].Platforms.Add(Platform);
				return;
			}
		}

		FGameShowPlatformGroup NewGroup = FGameShowPlatformGroup(StartPosition, TargetPosition, Manager.GetCorrespondingValuesToPosition(StartPosition), Manager.GetCorrespondingValuesToPosition(TargetPosition));
		NewGroup.Platforms.Add(Platform);
		PlatformGroups.Add(NewGroup);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// for (auto Entry : Manager.PlatformLayoutsDataAsset.Layouts[Manager.NewLayoutName].PositionsByGuid)
		// {
		// 	if (!Manager.AllPlatformsByGuid.Contains(Entry.Key))
		// 		continue;

		// 	auto Platform = Manager.AllPlatformsByGuid[Entry.Key];
		// 	EBombTossPlatformPosition StartPosition = Platform.CurrentPosition;
		// 	EBombTossPlatformPosition TargetPosition = Entry.Value;
		// 	if (StartPosition == TargetPosition)
		// 		continue;
			
		// 	AddPlatformToGroup(Platform, StartPosition, TargetPosition);
		// }

		// for (auto Group : PlatformGroups)
		// {
		// 	Print(f"Group: {Group.StartPosition :n} {Group.TargetPosition :n} Num: {Group.Platforms.Num()}", 5);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.bIsMovingPlatforms = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / Manager.PlatformMoveDuration);
		for (auto Group : PlatformGroups)
		{
			FVector CurrentBaseRailingLoc = Math::Lerp(Group.StartPositionValues.BaseRailingRootLoc, Group.TargetPositionValues.BaseRailingRootLoc, Alpha);
			FQuat CurrentBaseRailingRot = FQuat::Slerp(Group.StartPositionValues.BaseRailingRootRot.Quaternion(), Group.TargetPositionValues.BaseRailingRootRot.Quaternion(), Alpha);
			FQuat CurrentPlatformMeshRootRot = FQuat::Slerp(Group.StartPositionValues.PlatformMeshRootRot.Quaternion(), Group.TargetPositionValues.PlatformMeshRootRot.Quaternion(), Alpha);
			FQuat CurrentRailingRootRot = FQuat::Slerp(Group.StartPositionValues.RailingRootRot.Quaternion(), Group.TargetPositionValues.RailingRootRot.Quaternion(), Alpha);
			for (auto Platform : Group.Platforms)
			{
				Platform.BaseRailingRoot.SetRelativeLocation(CurrentBaseRailingLoc);
				Platform.BaseRailingRoot.SetRelativeRotation(CurrentBaseRailingRot);
				Platform.PlatformMeshRoot.SetRelativeRotation(CurrentPlatformMeshRootRot);
				Platform.RailingRoot.SetRelativeRotation(CurrentRailingRootRot);
			}
		}
	}
};