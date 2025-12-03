class UMedallionMedallionCutsceneVisibleCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	AMedallionMedallionActor Medallion;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Medallion = Cast<AMedallionMedallionActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Medallion.MedallionState != EMedallionMedallionState::CutsceneControlled)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Medallion.MedallionState != EMedallionMedallionState::CutsceneControlled)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Medallion.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Medallion.VisibleInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Medallion.VisibleInstigators.Remove(this);
	}
};