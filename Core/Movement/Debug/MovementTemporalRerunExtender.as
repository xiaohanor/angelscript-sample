#if EDITOR
/**
 * A debug struct for handling the temporal loggers rerun data
 */
struct FMovementTemporalRerunData
{
	int Frame = -1;
	UBaseMovementResolver Resolver = nullptr;
	UBaseMovementData Data = nullptr;
	TArray<UMovementResolverExtension> Extensions;
};
#endif

/** 
 * Makes if possible to rerun character movement frames
 */
class UMovementTemporalRerunExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Character Movement Rerun Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
#if EDITOR
		if(!TemporalLog.bPauseLogPruning)
			return false;
		auto MoveComp = Cast<UHazeMovementComponent>(Report.AssociatedObject);
		if(MoveComp == nullptr)
			return false;

		return true;
#else
		return false;
#endif
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{
		auto MoveComp = Cast<UHazeMovementComponent>(Report.AssociatedObject);
		if (MoveComp == nullptr)
			return;	

#if EDITOR
		auto MovementConfig = UMovementDebugConfig::Get();
		if(MovementConfig == nullptr)
			return;

		if(!MovementConfig.bEnableRerun)
			return;

		int CurrentFrame = Report.ReportedFrame;
		auto Section = Drawer.Begin();

		// RERUN
		if(!MoveComp.CanRerunMovement())
			return;

		if(Section.Button("Trigger Rerun"))
		{	
			auto TemporalTransform = UTemporalLogTransformLoggerComponent::Get(MoveComp.Owner);
			if(!devEnsure(TemporalTransform != nullptr, "A TemporalLogTransformLoggerComponent is required on the moving actor to allow rerunning movement!"))
				return;

			auto FrameData = MoveComp.BinaryFindIndex(CurrentFrame);
			if(ensure(FrameData.Frame >= 0, "Rerun data index not found"))
			{
				check(FrameData.Frame == CurrentFrame);

				if(!ensure(!MoveComp.IsPerformingDebugRerun(), "We are already performing a rerun!"))
					return;

				if(!ensure(FrameData.Data != nullptr))
					return;

				if(!ensure(FrameData.Data.bIsEditorRerunData))
					return;

				if(!ensure(FrameData.Data.EditorTemporalFrame == CurrentFrame))
					return;

				for(UMovementResolverExtension Extension : FrameData.Extensions)
				{
					if(!ensure(Extension.bIsEditorRerunExtension))
						return;

					if(!ensure(Extension.EditorTemporalFrame == CurrentFrame))
						return;
				}

				// Setup the rerun and perform the run again
				{
					FAngelscriptGameThreadScopeWorldContext ScopeWorldContext(MoveComp);

					MoveComp.DebugSetInRerun(this, true);

					FrameData.Resolver.Extensions = FrameData.Extensions;
					
					FrameData.Resolver.PrepareResolver(FrameData.Data);
					FrameData.Resolver.ResolveRerun();

					MoveComp.DebugSetInRerun(this, false);
				}
			}
		}
#endif
	}
};