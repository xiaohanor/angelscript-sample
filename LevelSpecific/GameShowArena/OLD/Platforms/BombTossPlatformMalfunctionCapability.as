class UBombTossPlatformMalfunctionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ABombToss_Platform Platform;

	TArray<EBombTossPlatformPosition> PlatformPositions;
	default PlatformPositions.Add(EBombTossPlatformPosition::Hidden);
	default PlatformPositions.Add(EBombTossPlatformPosition::WallUp);
	default PlatformPositions.Add(EBombTossPlatformPosition::DoubleWallRight);
	default PlatformPositions.Add(EBombTossPlatformPosition::InvertedWallDown);
	default PlatformPositions.Add(EBombTossPlatformPosition::TripleWallLeft);
	default PlatformPositions.Add(EBombTossPlatformPosition::FullTiltLeft);
	default PlatformPositions.Add(EBombTossPlatformPosition::TiltUp);
	default PlatformPositions.Add(EBombTossPlatformPosition::Raised);
	int CurrentPositionIndex = 0;

	// Duration to complete movement
	float LerpDuration = 0;

	// Duration that we move (movement can be interrupted)
	float ActualMoveDuration = 0;

	float CurrentMoveActiveDuration = 0;

	FBombTossPlatformPositionValues CurrentPositionValues;
	FBombTossPlatformPositionValues TargetPositionValues;

	FVector BaseRailingRootLoc;
	FQuat BaseRailingRootRot;
	FQuat PlatformMeshRootRot;
	FQuat RailingRootRot;

	AGameShowArenaPlatformManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<ABombToss_Platform>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Platform.bIsMalfunctioning)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Platform.bIsMalfunctioning)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Manager = GameShowArena::GetGameShowArenaPlatformManager();
		CurrentPositionIndex = Math::RandRange(0, PlatformPositions.Num() - 1);
		CurrentMoveActiveDuration = 0;
		CurrentPositionValues = Platform.CurrentPositionValues;
		TargetPositionValues = Manager.GetCorrespondingValuesToPosition(PlatformPositions[CurrentPositionIndex]);
		LerpDuration = Math::RandRange(1, 2);
		ActualMoveDuration = LerpDuration - Math::RandRange(0.2, 0.6);

		BaseRailingRootLoc = CurrentPositionValues.BaseRailingRootLoc;
		BaseRailingRootRot = CurrentPositionValues.BaseRailingRootRot.Quaternion();
		PlatformMeshRootRot = CurrentPositionValues.PlatformMeshRootRot.Quaternion();
		RailingRootRot = CurrentPositionValues.RailingRootRot.Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentMoveActiveDuration += DeltaTime;
		if (CurrentMoveActiveDuration >= ActualMoveDuration)
		{
			CurrentMoveActiveDuration = 0;
			CurrentPositionIndex += Math::RandRange(1, 4);
			if (CurrentPositionIndex >= PlatformPositions.Num())
				CurrentPositionIndex -= PlatformPositions.Num();

			TargetPositionValues = Manager.GetCorrespondingValuesToPosition(PlatformPositions[CurrentPositionIndex]);

			LerpDuration = Math::RandRange(0.75, 1.25);
			ActualMoveDuration = LerpDuration - Math::RandRange(0.2, 0.6);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(Platform.MalfunctionEffect, Platform.RailingRoot.WorldLocation, FRotator::ZeroRotator, FVector::OneVector * 10);
		}
		float MovementAlpha = Math::Saturate(CurrentMoveActiveDuration / LerpDuration);
		//Print(f"{MovementAlpha=}", 0);
		BaseRailingRootLoc = Math::Lerp(BaseRailingRootLoc, TargetPositionValues.BaseRailingRootLoc, MovementAlpha);
		BaseRailingRootRot = FQuat::Slerp(BaseRailingRootRot, TargetPositionValues.BaseRailingRootRot.Quaternion(), MovementAlpha);
		PlatformMeshRootRot = FQuat::Slerp(PlatformMeshRootRot, TargetPositionValues.PlatformMeshRootRot.Quaternion(), MovementAlpha);
		RailingRootRot = FQuat::Slerp(RailingRootRot, TargetPositionValues.RailingRootRot.Quaternion(), MovementAlpha);

		Platform.BaseRailingRoot.SetRelativeLocation(BaseRailingRootLoc);
		Platform.BaseRailingRoot.SetRelativeRotation(BaseRailingRootRot);
		Platform.PlatformMeshRoot.SetRelativeRotation(PlatformMeshRootRot);
		Platform.RailingRoot.SetRelativeRotation(RailingRootRot);
	}
};