/**
 * A separate capability to handle when the strike pose widget should be shown
 */
class UCongaLineStrikePoseWidgetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CongaLine::Tags::CongaLine);
	default CapabilityTags.Add(CongaLine::Tags::CongaLineStrikePose);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ACongaLineManager Manager;
	UCongaLineStrikePoseComponent StrikePoseComp;

	int PoseMeasure = -1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = CongaLine::GetManager();
		StrikePoseComp = UCongaLineStrikePoseComponent::Get(Player);
		// = UPlayerTargetablesComponent::Get(Player);

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CongaLine::IsCongaLineActive())
			return false;

		// If it's not the first beat, don't allow starting!
		if(Manager.GetCurrentBeat(true) != 1)
			return false;

		if(StrikePoseComp.CurrentPose == ECongaLineStrikePose::None)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CongaLine::IsCongaLineActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StrikePoseComp.bActive = true;
		
		PoseMeasure = Manager.GetCurrentMeasure();
		//StrikePoseComp.SpawnWidget();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StrikePoseComp.bActive = false;

		//StrikePoseComp.RemoveWidget();
	}
};