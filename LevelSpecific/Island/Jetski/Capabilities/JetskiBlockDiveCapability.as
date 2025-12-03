class UJetskiBlockDiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AJetski Jetski;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsWithinBlockDiveZone())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsWithinBlockDiveZone())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Jetski.BlockCapabilities(Jetski::Tags::JetskiDive, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Jetski.UnblockCapabilities(Jetski::Tags::JetskiDive, this);
	}

	bool IsWithinBlockDiveZone() const
	{
		const float DistanceAlongSpline = Jetski.GetDistanceAlongSpline();
		auto BlockDiveData = Jetski.JetskiSpline.Spline.FindPreviousComponentAlongSpline(UJetskiSplineDiveZoneComponent, false, DistanceAlongSpline);
		if(!BlockDiveData.IsSet())
			return false;

		auto BlockDiveComp = Cast<UJetskiSplineDiveZoneComponent>(BlockDiveData.Value.Component);
		if(BlockDiveComp.ZoneType != EJetskiSplineDiveZoneType::BlockDive)
			return false;

		return true;
	}
};