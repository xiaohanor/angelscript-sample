class UMeltdownPhaseOneDropAttackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AMeltdownBossPhaseOne Rader;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rader = Cast<AMeltdownBossPhaseOne>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack == EMeltdownPhaseOneAttack::Drop)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::Drop && Rader.CurrentAttack != EMeltdownPhaseOneAttack::None)
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Rader.Mesh.CanRequestLocomotion())
			Rader.Mesh.RequestLocomotion(n"DropAttack", this);
	}
};