class UIslandPipeSlideCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 2;

	UCameraUserComponent CameraUser;
	UIslandPipeSlideComponent PipeSlideComponent;
	UIslandPipeSlideComposableSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUser = UCameraUserComponent::Get(Player);
		PipeSlideComponent = UIslandPipeSlideComponent::Get(Player);
		Settings = UIslandPipeSlideComposableSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PipeSlideComponent.bIsPipeSliding)
			return false;

		if(PipeSlideComponent.ActiveSpline == nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PipeSlideComponent.bIsPipeSliding)
			return true;

		if(PipeSlideComponent.ActiveSpline == nullptr)
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
		FSplinePosition SplinePos = PipeSlideComponent.ActiveSpline.GetClosestSplinePositionToWorldLocation(Player.GetActorLocation());
		CameraUser.SetDesiredRotation(SplinePos.WorldForwardVector.ToOrientationRotator(), this);
	}
};