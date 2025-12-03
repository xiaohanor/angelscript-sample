class UMedallionMedallionOnHighfiveSocketCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	AMedallionMedallionActor Medallion;
	AHazePlayerCharacter Player;
	FHazeAcceleratedVector AccRemoveOffsetLoc;
	FHazeAcceleratedQuat AccRemoveOffsetRot;

	const FVector TargetRelativeLoc = FVector(0.0, 0.0, 0.0);
	const FQuat ZoeTargetRelativeRot = FQuat::MakeFromYZ(-FVector::ForwardVector, -FVector::RightVector);
	const FQuat MioTargetRelativeRot = FQuat::MakeFromYZ(FVector::ForwardVector, FVector::RightVector);

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Medallion = Cast<AMedallionMedallionActor>(Owner);
		Player = Game::GetPlayer(Medallion.TargetPlayer);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Medallion.MedallionState != EMedallionMedallionState::OnSocketHighfive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Medallion.MedallionState != EMedallionMedallionState::OnSocketHighfive)
			return true;
		return false;
	}

	FQuat GetTargetRot() const
	{
		return FQuat();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Player.IsMio())
			Medallion.AttachToComponent(Player.Mesh, Medallion.MioHighfiveAttachSocket, EAttachmentRule::SnapToTarget);
		else
			Medallion.AttachToComponent(Player.Mesh, Medallion.ZoeHighfiveAttachSocket, EAttachmentRule::SnapToTarget);

		if (Player.bIsControlledByCutscene)
		{
			AccRemoveOffsetLoc.SnapTo(TargetRelativeLoc);
			AccRemoveOffsetRot.SnapTo(GetTargetRot());
		}
		else
		{
			AccRemoveOffsetLoc.SnapTo(Medallion.RemoveOffsetsBetweenStatesRoot.RelativeLocation);
			AccRemoveOffsetRot.SnapTo(Medallion.RemoveOffsetsBetweenStatesRoot.RelativeRotation.Quaternion());
		}
		Medallion.VisibleInstigators.Add(this);
		Medallion.OnSocketed.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Medallion.VisibleInstigators.Remove(this);
		Medallion.OnSocketedStop.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRemoveOffsetLoc.AccelerateTo(TargetRelativeLoc, 1.0, DeltaTime);
		AccRemoveOffsetRot.AccelerateTo(GetTargetRot(), 0.2, DeltaTime);
		Medallion.RemoveOffsetsBetweenStatesRoot.SetRelativeRotation(AccRemoveOffsetRot.Value);
		Medallion.RemoveOffsetsBetweenStatesRoot.SetRelativeLocation(AccRemoveOffsetLoc.Value);
		if (SanctuaryMedallionHydraDevToggles::Draw::Amulet.IsEnabled())
			Debug::DrawDebugCoordinateSystem(Medallion.MedallionRoot.WorldLocation, Medallion.MedallionRoot.WorldRotation, 50, 1.0);
	}
};