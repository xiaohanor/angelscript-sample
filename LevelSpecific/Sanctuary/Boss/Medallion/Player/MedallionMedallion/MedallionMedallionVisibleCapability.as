class UMedallionMedallionVisibleCapability : UHazeCapability
{
	AMedallionMedallionActor Medallion;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Medallion = Cast<AMedallionMedallionActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Medallion.VisibleInstigators.IsEmpty())
			return false;
		if (Medallion.MedallionState == EMedallionMedallionState::Hidden)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Medallion.VisibleInstigators.IsEmpty())
			return true;
		if (Medallion.MedallionState == EMedallionMedallionState::Hidden)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.RemoveActorVisualsBlock(Medallion.VisualsBlocker);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.AddActorVisualsBlock(Medallion.VisualsBlocker);
	}
};