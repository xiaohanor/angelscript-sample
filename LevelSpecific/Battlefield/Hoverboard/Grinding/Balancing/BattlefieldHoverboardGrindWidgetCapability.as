
class UBattlefieldHoverboardGrindWidgetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);
	default DebugCategory = BattlefieldHoverboardDebugCategory::Hoverboard;

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UBattlefieldHoverboardGrindingComponent GrindComp;
	UBattlefieldHoverboardComponent HoverboardComp;

	UBattlefieldHoverboardGrindingSettings GrindSettings;

	UBattlefieldHoverboardGrindWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		
		GrindSettings = UBattlefieldHoverboardGrindingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HoverboardComp.IsOn())
			return false;

		if(!GrindComp.bIsOnGrind)
			return false;

		if(!GrindComp.CurrentGrindSplineComp.bEnableBalancingWhileOnGrind)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HoverboardComp.IsOn())
			return true;

		if(!GrindComp.bIsOnGrind)
			return true;

		if(!GrindComp.CurrentGrindSplineComp.bEnableBalancingWhileOnGrind)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Widget = Player.AddWidget(GrindSettings.GrindWidgetClass);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// if(Widget != nullptr)
		// {
		// 	Player.RemoveWidget(Widget);
		// 	Widget = nullptr;
		// }
	}
};