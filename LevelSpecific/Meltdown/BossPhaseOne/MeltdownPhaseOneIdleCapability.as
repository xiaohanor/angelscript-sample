class UMeltdownPhaseOneIdleCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	AMeltdownBossPhaseOne Rader;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseOne>(Owner);
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

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
		{
			if (Rader.IdleFeature.IsNone())
				Rader.Mesh.RequestLocomotion(n"MeltdownBossFloating", this);
			else
				Rader.Mesh.RequestLocomotion(Rader.IdleFeature, this);
		}
	}
};