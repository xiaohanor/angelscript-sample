
class UAnimationTemporalLogExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Animation Temporal Log Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
	#if EDITOR
		return Cast<UHazeSkeletalMeshComponentBase>(Report.AssociatedObject) != nullptr;
	#else
		return false;
	#endif
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{
		UHazeSkeletalMeshComponentBase SkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(Report.AssociatedObject);
		if (SkelMeshComp == nullptr)
			return;

		FHazeImmediateSectionHandle Section = Drawer.Begin();
		FHazeImmediateHorizontalBoxHandle Box = Section.HorizontalBox();

		if (UHazeMeshPoseDebugComponent::Get(SkelMeshComp.Owner) == nullptr)
		{
			DrawAddMeshPoseDebugComponentButton(Box, Report, SkelMeshComp);
		}

		DrawTogglePhysicalAnimDebug(Box, Report, SkelMeshComp);
	}

	void DrawAddMeshPoseDebugComponentButton(FHazeImmediateHorizontalBoxHandle Box, FHazeTemporalLogReport Report, UHazeSkeletalMeshComponentBase SkelMeshComp) const
	{
		if(Box.Button("Add Mesh Pose Debug Component to Actor"))
		{
			UHazeMeshPoseDebugComponent::GetOrCreate(SkelMeshComp.Owner);
		}
	}

	void DrawTogglePhysicalAnimDebug(FHazeImmediateHorizontalBoxHandle Box, FHazeTemporalLogReport Report, UHazeSkeletalMeshComponentBase SkelMeshComp) const
	{
		if  (Box.Button("Draw PhysicalAnim"))
		{
#if EDITOR
			auto PhysicalAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(SkelMeshComp.Owner);
			const auto CurrentDebugState = PhysicalAnimComp.GetCurrentDebugState();

			EHazePhysicalAnimationDebugState NewState;
			switch (CurrentDebugState)
			{
				case EHazePhysicalAnimationDebugState::GhostAnimPose:
					NewState = EHazePhysicalAnimationDebugState::GhostPhysics;
					break;

				case EHazePhysicalAnimationDebugState::GhostPhysics:
					NewState = EHazePhysicalAnimationDebugState::NONE;
					break;

				default:
					NewState = EHazePhysicalAnimationDebugState::GhostAnimPose;
					break;
			}

			PhysicalAnimComp.SetCurrentDebugState(NewState);

#endif
		}
	}
}

