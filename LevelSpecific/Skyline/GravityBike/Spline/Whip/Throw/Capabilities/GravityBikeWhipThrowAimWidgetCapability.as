struct FGravityBikeWhipThrowAimWidgetActivateParams
{
	UGravityBikeWhipGrabTargetComponent MainGrabbed;
	UGravityBikeWhipThrowTargetComponent ThrowTarget;
}

class UGravityBikeWhipThrowAimWidgetCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 110;	// After aiming

	UGravityBikeWhipComponent WhipComp;

	UGravityBikeWhipGrabTargetComponent MainGrabbedComp;
	UGravityBikeWhipThrowWidget ThrowWidget;
	UGravityBikeWhipThrowTargetComponent PreviousTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeWhipThrowAimWidgetActivateParams& Params) const
	{
		if(!WhipComp.HasGrabbedAnything())
			return false;

		if(WhipComp.IsThrowing())
			return false;

		if(!WhipComp.HasThrowTarget())
			return false;

		Params.MainGrabbed = WhipComp.GetMainGrabbed();
		Params.ThrowTarget = WhipComp.GetThrowTarget();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsValid(MainGrabbedComp))
			return true;

		if(!WhipComp.HasGrabbedAnything())
			return true;

		if(!WhipComp.HasThrowTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeWhipThrowAimWidgetActivateParams Params)
	{
		MainGrabbedComp = Params.MainGrabbed;
		PreviousTarget = Params.ThrowTarget;

		CreateThrowWidget(Params.ThrowTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RemoveWidget();

		MainGrabbedComp = nullptr;
		PreviousTarget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto CurrentTarget = WhipComp.GetThrowTarget();

		if(CurrentTarget != PreviousTarget)
		{
			// Fade out the old widget, and create a new one
			RemoveWidget();
			CreateThrowWidget(CurrentTarget);
		}

		PreviousTarget = CurrentTarget;
	}

	private void CreateThrowWidget(UGravityBikeWhipThrowTargetComponent ThrowTarget)
	{
		if (ThrowWidget != nullptr)
			RemoveWidget();

		ThrowWidget = WhipComp.GetScreenPlayer().AddWidget(WhipComp.ThrowTargetWidgetClass, EHazeWidgetLayer::Crosshair);
		ThrowWidget.AttachWidgetToComponent(ThrowTarget);
	}

	private void RemoveWidget()
	{
		if(ThrowWidget == nullptr)
			return;

		WhipComp.GetScreenPlayer().RemoveWidget(ThrowWidget);
		ThrowWidget = nullptr;
	}
};