class UMedallionMedallionOnChestSocketCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	AMedallionMedallionActor Medallion;
	AHazePlayerCharacter Player;
	FHazeAcceleratedVector AccRemoveActorOffsetLoc;
	FHazeAcceleratedQuat AccRemoveActorOffsetRot;
	FHazeAcceleratedVector AccRemoveComponentOffsetLoc;
	FHazeAcceleratedQuat AccRemoveComponentOffsetRot;

	const FVector TargetRelativeLoc = FVector(0.0, 0.0, 0.0);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Medallion = Cast<AMedallionMedallionActor>(Owner);
		Player = Game::GetPlayer(Medallion.TargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Medallion.MedallionState != EMedallionMedallionState::OnSocketChest)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Medallion.MedallionState != EMedallionMedallionState::OnSocketChest)
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
		Medallion.CinematicSkelMeshBase.ResetAllAnimation();
		Medallion.AttachToComponent(Player.Mesh, Medallion.ChestAttachSocket, EAttachmentRule::KeepWorld);
		if (Player.bIsControlledByCutscene)
		{
			AccRemoveActorOffsetLoc.SnapTo(TargetRelativeLoc);
			AccRemoveActorOffsetRot.SnapTo(GetTargetRot());
			AccRemoveComponentOffsetLoc.SnapTo(FVector());
			AccRemoveActorOffsetRot.SnapTo(FQuat());
		}
		else
		{
			AccRemoveActorOffsetLoc.SnapTo(Medallion.ActorRelativeLocation);
			AccRemoveActorOffsetRot.SnapTo(Medallion.ActorRelativeRotation.Quaternion());
			AccRemoveComponentOffsetLoc.SnapTo(Medallion.RemoveOffsetsBetweenStatesRoot.RelativeLocation);
			AccRemoveActorOffsetRot.SnapTo(Medallion.RemoveOffsetsBetweenStatesRoot.RelativeRotation.Quaternion());
		}
		Medallion.VisibleInstigators.Add(this);
		Medallion.OnSocketed.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Medallion.VisibleInstigators.Remove(this);
		Medallion.OnSocketedStop.Broadcast();
		Medallion.SetActorRelativeRotation(FQuat());
		Medallion.SetActorRelativeLocation(FVector());
		Medallion.RemoveOffsetsBetweenStatesRoot.SetRelativeLocation(FVector());
		Medallion.RemoveOffsetsBetweenStatesRoot.SetRelativeRotation(FRotator());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRemoveActorOffsetLoc.AccelerateTo(TargetRelativeLoc, 1.0, DeltaTime);
		AccRemoveActorOffsetRot.AccelerateTo(GetTargetRot(), 0.2, DeltaTime);
		Medallion.SetActorRelativeRotation(AccRemoveActorOffsetRot.Value);
		Medallion.SetActorRelativeLocation(AccRemoveActorOffsetLoc.Value);

		AccRemoveComponentOffsetLoc.AccelerateTo(FVector(), 1.0, DeltaTime);
		AccRemoveComponentOffsetRot.AccelerateTo(FQuat(), 1.0, DeltaTime);
		Medallion.RemoveOffsetsBetweenStatesRoot.SetRelativeLocation(AccRemoveComponentOffsetLoc.Value);
		Medallion.RemoveOffsetsBetweenStatesRoot.SetRelativeRotation(AccRemoveComponentOffsetRot.Value);
	}
};