class USkylineTorCircleHoverBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Hover");
	USkylineTorHoverComponent HoverComp;
	USkylineTorSettings Settings;
	FHazeAcceleratedVector AccLocation;
	UHazeOffsetComponent OffsetComp;
	USkylineTorThrusterManagerComponent ThrusterManagerComp;
	ASplineActor SplineActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		OffsetComp = UHazeOffsetComponent::GetOrCreate(Owner);
		ThrusterManagerComp = USkylineTorThrusterManagerComponent::GetOrCreate(Owner);
		SplineActor = TListedActors<ASkylineTorReferenceManager>().Single.CircleMovementSplineActor;
		Settings = USkylineTorSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccLocation.SnapTo(Owner.ActorLocation);
		HoverComp.StartHover(this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HoverComp.ClearHover(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HoverComp.StartHover(this);
		DestinationComp.MoveAlongSpline(SplineActor.Spline, 0);
	}
}
