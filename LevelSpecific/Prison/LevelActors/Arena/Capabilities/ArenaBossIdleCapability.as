class UArenaBossIdleCapability : UArenaBossBaseCapability
{
	default RequiredState = EArenaBossState::Idle;
	default bResetToIdleOnDeactivation = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);
	}
}