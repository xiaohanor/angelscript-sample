class UOilRigSlidePlayerTimeDilationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	float CurrentTimeDilation = 1.0;
	float SlowDownSpeed = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{

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
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearActorTimeDilation(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, 0.1, DeltaTime, SlowDownSpeed);
		Player.SetActorTimeDilation(CurrentTimeDilation, this);
	}
}