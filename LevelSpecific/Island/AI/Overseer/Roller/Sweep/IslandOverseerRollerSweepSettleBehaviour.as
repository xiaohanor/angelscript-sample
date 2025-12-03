
class UIslandOverseerRollerSweepSettleBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerRollerSweepComponent SweepComp;

	FHazeAcceleratedVector AccSettle;
	FVector SettleLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		SweepComp = UIslandOverseerRollerSweepComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.RollerSweepSettleDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		SettleLocation = SweepComp.Spline.GetWorldLocationAtSplineDistance(SweepComp.Spline.SplineLength - 50);
		AccSettle.SnapTo(Owner.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(SweepComp.bInterrupted)
		{
			DeactivateBehaviour();
			return;
		}

		AccSettle.SpringTo(SettleLocation, 100, 0.25, DeltaTime);
		Owner.ActorLocation = AccSettle.Value;
	}
}