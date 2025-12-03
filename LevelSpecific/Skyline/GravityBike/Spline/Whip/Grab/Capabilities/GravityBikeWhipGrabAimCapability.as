struct FGravityBikeWhipGrabWidgetData
{
	UGravityBikeWhipGrabWidget Widget;
	UCanvasPanelSlot WidgetSlot;
	UGravityBikeWhipGrabTargetComponent TargetComp;
	FHazeAcceleratedVector2D AccOffset;
};

class UGravityBikeWhipGrabAimCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhipAim);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;

	UGravityBikeWhipComponent WhipComp;
	UPlayerTargetablesComponent PlayerTargetables;

	TArray<FGravityBikeWhipGrabWidgetData> WidgetDatas;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
		PlayerTargetables = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WhipComp.HasGrabbedAnything())
			return false;

		if(WhipComp.GetWhipState() != EGravityBikeWhipState::None)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WhipComp.HasGrabbedAnything())
			return true;

		if(WhipComp.GetWhipState() != EGravityBikeWhipState::None)
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
		for(auto WidgetData : WidgetDatas)
		{
			WhipComp.GetScreenPlayer().RemoveWidget(WidgetData.Widget);
			WidgetData.Widget.RemoveFromParent();
		}

		WidgetDatas.Reset();
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<UGravityBikeWhipGrabTargetComponent> ValidGrabTargets = WhipComp.GetAllValidGrabTargets();

		while(WidgetDatas.Num() < ValidGrabTargets.Num())
		{
			AddWidget(ValidGrabTargets[WidgetDatas.Num()]);
		}

		TSet<int> AssignedIndices;
		for(int i = WidgetDatas.Num() - 1; i >= 0; i--)
		{
			FGravityBikeWhipGrabWidgetData& WidgetData = WidgetDatas[i];

			int FoundIndex = ValidGrabTargets.FindIndex(WidgetData.TargetComp);

			if(FoundIndex >= 0)
			{
				// We are still targeting this widgets target
				AssignedIndices.Add(FoundIndex);
				WidgetData.AccOffset.SnapTo(FVector2D::ZeroVector);
			}
			else
			{
				// The target this widget was targeting is no longer valid
				WidgetData.TargetComp = nullptr;

				// Try to find a new, unassigned target
				for(int j = 0; j < ValidGrabTargets.Num(); j++)
				{
					if(AssignedIndices.Contains(j))
						continue;

					WidgetData.TargetComp = ValidGrabTargets[j];
					AssignedIndices.Add(j);
					break;
				}

				// We found a new target, start moving towards that
				if(IsValid(WidgetData.TargetComp))
				{
					FVector2D OldLocation = WidgetData.Widget.GetScreenSpacePositionUV();
					FVector2D NewLocation = WorldLocationToScreenUV(WidgetData.TargetComp.WorldLocation);
					FVector2D Offset = OldLocation - NewLocation;

					WidgetData.AccOffset.SnapTo(FVector2D::ZeroVector);
					
					WidgetData.Widget.Show();
				}
			}

			if(IsValid(WidgetData.TargetComp))
			{
				FVector2D TargetUV = WorldLocationToScreenUV(WidgetData.TargetComp.WorldLocation);
				WidgetData.Widget.SetScreenSpacePositionUV(TargetUV + WidgetData.AccOffset.Value);
			}
			else
			{
				RemoveWidget(i);
			}
		}

		FTargetableOutlineSettings OutlineSettings;
		OutlineSettings.MaximumOutlinesVisible = 1;
		OutlineSettings.TargetableCategory = GravityBikeWhip::TargetableCategoryGrab;
		OutlineSettings.bShowVisibleTargets = true;
		PlayerTargetables.ShowOutlinesForTargetables(OutlineSettings);
	}

	private void AddWidget(UGravityBikeWhipGrabTargetComponent GrabTarget)
	{
		UGravityBikeWhipGrabWidget Widget = Cast<UGravityBikeWhipGrabWidget>(
			Widget::CreateWidget(WhipComp.ThrowCanvasWidget, WhipComp.GrabTargetWidgetClass)
		);

		devCheck(Widget != nullptr, f"No Widget assigned on throwable attached to actor {Owner.Name.ToString()}!");

		Widget.OverrideWidgetPlayer(WhipComp.GetScreenPlayer());
		auto WidgetSlot = Cast<UCanvasPanelSlot>(WhipComp.ThrowCanvasWidget.ThrowCanvas.AddChild(Widget));
		WidgetSlot.SetAutoSize(true);

		FGravityBikeWhipGrabWidgetData WidgetData;
		WidgetData.Widget = Widget;
		WidgetData.WidgetSlot = WidgetSlot;
		WidgetData.TargetComp = GrabTarget;
		WidgetData.AccOffset.SnapTo(FVector2D::ZeroVector);
		WidgetDatas.Add(WidgetData);

		Widget.Show();
	}

	private void RemoveWidget(int Index)
	{
		if(WidgetDatas[Index].Widget != nullptr)
		{
			WhipComp.GetScreenPlayer().RemoveWidget(WidgetDatas[Index].Widget);
			WidgetDatas[Index].Widget.RemoveFromParent();
		}

		WidgetDatas.RemoveAtSwap(Index);
	}

	private FVector2D WorldLocationToScreenUV(FVector WorldLocation) const
	{
		FVector2D ScreenUV;
		SceneView::ProjectWorldToViewpointRelativePosition(
			WhipComp.GetScreenPlayer(), WorldLocation, ScreenUV
		);
		return ScreenUV;
	}
}