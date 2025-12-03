/**
 * A debug struct for handling the temporal loggers rerun data
 */
struct FTemporalLogTransformArrayData
{
	int64 Frame = -1;
	TArray<FTemporalLogTransformComponentData> ComponentTransforms;
};

struct FTemporalLogTransformComponentData
{
	USceneComponent Component;
	const USceneComponent AttachParent;
	FTransform ComponentTransform = FTransform::Identity;
	FTransform AttachParentTransform = FTransform::Identity;
	bool bWasAttachedToOtherActor = false;

	bool bAbsoluteLocation = false;
	bool bAbsoluteRotation = false;
	bool bAbsoluteScale = false;

	bool HasAbsoluteFields() const
	{
		return bAbsoluteLocation || bAbsoluteRotation || bAbsoluteScale;
	}
};

/** 
 * A component that handles external moving collision so we can rerun frames against them to 
 * Attach it to a scene component to transform that component back to where it was
 * the frame it was logged
 */
UCLASS(HideCategories = "Rendering Cooking Activation ComponentTick Physics Lod Collision")
class UTemporalLogTransformLoggerComponent : UHazeTemporalLogScrubbableComponent
{
	default bIsEditorOnly = true;

#if EDITOR
	private TArray<FTemporalLogTransformArrayData> TemporalFrames;
	private FTemporalLogTransformArrayData OriginalTransforms;
	private FTemporalLogTransformArrayData ActiveRerunFrame;

	private bool bHasBeenInitialized = false;
	private int MaxFrameCount = 0;
	private int LoggedFrameCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		auto TemporalLog =  UHazeTemporalLog::Get();
		if(TemporalLog == nullptr)
			return;

		FTemporalLogTransformArrayData TemporalFrameState;
		TemporalFrameState.Frame = TemporalLog.CurrentLogFrameNumber;
		if(TemporalFrameState.Frame < 0)
			return;

		GetComponentTransforms(TemporalFrameState.ComponentTransforms);

		int Index = LoggedFrameCount % MaxFrameCount;
		if (Index < TemporalFrames.Num())
			TemporalFrames[Index] = TemporalFrameState;	
		else
			TemporalFrames.Add(TemporalFrameState);

		LoggedFrameCount += 1;
	}

	void Initialize(int MaxFrames = -1)
	{
		if(bHasBeenInitialized)
			return;

		bHasBeenInitialized = true;
		MaxFrameCount = MaxFrames > 0 ? MaxFrames : 100000;
		LoggedFrameCount = 0;
		TemporalFrames.Empty(MaxFrameCount);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogScrubbedToFrame(UHazeTemporalLog Log, int LogFrameNumber)
	{
		if(OriginalTransforms.Frame == -1)
		{
			OriginalTransforms.Frame = Time::FrameNumber;
	 		GetComponentTransforms(OriginalTransforms.ComponentTransforms);
		}

		if(ActiveRerunFrame.Frame != LogFrameNumber && LogFrameNumber >= 0)
		{
			ApplyTemporalFrameInternal(LogFrameNumber);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogStopScrubbing(UHazeTemporalLog Log)
	{
		ResetTransformInternal();
	}

	void GetComponentTransforms(TArray<FTemporalLogTransformComponentData>&out OutOriginalTransforms) const
	{
		TArray<USceneComponent> AllSceneComponents;
		GetOwner().GetComponentsByClass(AllSceneComponents);

		// Remove all invalid or static components
		for(int i = AllSceneComponents.Num() - 1; i >= 0; i--)
		{
			if(AllSceneComponents[i] == nullptr)
			{
				AllSceneComponents.RemoveAtSwap(i);
				continue;
			}

			if(AllSceneComponents[i].Mobility != EComponentMobility::Movable)
			{
				AllSceneComponents.RemoveAtSwap(i);
				continue;
			}
		}

		OutOriginalTransforms.Reset(AllSceneComponents.Num());
		for(auto Comp : AllSceneComponents)
		{
			FTemporalLogTransformComponentData CurrentTransform;
			CurrentTransform.Component = Comp;

			// Always store our relative transform
			CurrentTransform.ComponentTransform = Comp.RelativeTransform;

			if (Comp.AttachParent == nullptr)
			{
				// We are not attached to anything, use AttachParentTransform as WorldTransform
				CurrentTransform.AttachParent = nullptr;
				CurrentTransform.AttachParentTransform = Comp.GetWorldTransform();
			}
			else
			{
				// We are attached to a component, store that components world transform
				CurrentTransform.AttachParent = Comp.AttachParent;
				CurrentTransform.AttachParentTransform = Comp.AttachParent.GetWorldTransform();
			}

			// If this component is attached to another actor, we need to store that
			if(Comp.AttachParent != nullptr && Comp.AttachParent.Owner != Owner)
			{
				CurrentTransform.bWasAttachedToOtherActor = true;		
			}

			// Store if the component transform was absolute
			CurrentTransform.bAbsoluteLocation = Comp.bAbsoluteLocation;
			CurrentTransform.bAbsoluteRotation = Comp.bAbsoluteRotation;
			CurrentTransform.bAbsoluteScale = Comp.bAbsoluteScale;

			// Absolute fields are stored in ComponentTransform
			if(Comp.bAbsoluteLocation)
				CurrentTransform.ComponentTransform.SetLocation(Comp.WorldLocation);
			if(Comp.bAbsoluteRotation)
				CurrentTransform.ComponentTransform.SetRotation(Comp.ComponentQuat);
			if(Comp.bAbsoluteScale)
				CurrentTransform.ComponentTransform.SetScale3D(Comp.WorldScale);
		
			OutOriginalTransforms.Add(CurrentTransform);
		}
	}

	protected void ApplyTemporalFrameInternal(int TemporalLogFrame)
	{
		// Store all the original transforms
		if(OriginalTransforms.Frame == -1)
		{
			OriginalTransforms.Frame = Time::FrameNumber;
			GetComponentTransforms(OriginalTransforms.ComponentTransforms);
		}

		// Find the stored data
		ActiveRerunFrame = BinaryFindIndex(TemporalLogFrame);
		if(ActiveRerunFrame.Frame <= 0)
			return;

		// Apply the frame
		ApplyComponentTransforms(ActiveRerunFrame.ComponentTransforms);
	}

	
	// Reset all the temporary data back to the original transforms
	protected void ResetTransformInternal()
	{
		if(OriginalTransforms.Frame == -1)
			return;

		if(OriginalTransforms.ComponentTransforms.Num() == 0)
			return;

		ApplyComponentTransforms(OriginalTransforms.ComponentTransforms);
		ActiveRerunFrame = FTemporalLogTransformArrayData();
		OriginalTransforms = FTemporalLogTransformArrayData();
	}

	protected void ApplyComponentTransforms(TArray<FTemporalLogTransformComponentData> ComponentTransforms)
	{
		for(const FTemporalLogTransformComponentData& It : ComponentTransforms)
		{
			if(It.Component == nullptr)
				continue;

			// Set if we were absolute or not
			It.Component.SetAbsolute(It.bAbsoluteLocation, It.bAbsoluteRotation, It.bAbsoluteScale);

			if(It.bWasAttachedToOtherActor)
			{	
				if(It.Component.AttachParent == It.AttachParent)
				{
					// If we are still attached to the other actor, we just apply the relative position
					It.Component.SetRelativeTransform(It.ComponentTransform);
				}
				else
				{
					// We where attached to something that we are not attached to anymore
					// so we use the world location of that
					FTransform NewTransform = It.AttachParentTransform;
					NewTransform.AddToTranslation(It.ComponentTransform.Location);
					NewTransform.SetRotation(NewTransform.Rotation * It.ComponentTransform.Rotation);
					It.Component.SetWorldTransform(NewTransform);
				}
			}
			else
			{
				if(It.Component.AttachParent == It.AttachParent)
				{
					// We are still attached to the same component, apply relative transform
					It.Component.SetRelativeTransform(It.ComponentTransform);
				}
				else if(It.AttachParent != nullptr)
				{
					// We were attached, but are attached to something else now, put us where we would have been
					It.Component.SetWorldTransform(It.AttachParentTransform * It.ComponentTransform);
				}
				else
				{
					// We were not attached, which means that AttachParentTransform is our world transform
					It.Component.SetWorldTransform(It.AttachParentTransform);
				}
			}

			// If the component is marked as absolute, force set the absolute values
			if(It.HasAbsoluteFields())
			{
				FTransform WorldTransform = It.Component.WorldTransform;

				// If we were absolute, then ComponentTransform will hold the absolute value
				if(It.bAbsoluteLocation)
					WorldTransform.SetLocation(It.ComponentTransform.Location);
				if(It.bAbsoluteRotation)
					WorldTransform.SetRotation(It.ComponentTransform.Rotation);
				if(It.bAbsoluteScale)
					WorldTransform.SetScale3D(It.ComponentTransform.Scale3D);

				It.Component.SetWorldTransform(WorldTransform);
			}
		}
	}

	protected FTemporalLogTransformArrayData BinaryFindIndex(int FrameNumberToFind) const
	{
		int IndexOffset = LoggedFrameCount % MaxFrameCount;

		int StartAbsIndex = Math::Max(0, LoggedFrameCount - MaxFrameCount);
		int EndAbsIndex = LoggedFrameCount - 1;

		while (EndAbsIndex >= StartAbsIndex) 
		{
			const int MiddleAbsIndex = StartAbsIndex + Math::IntegerDivisionTrunc((EndAbsIndex - StartAbsIndex), 2); 
			const int MiddleRealIndex = Math::WrapIndex(IndexOffset - (LoggedFrameCount - MiddleAbsIndex), 0, MaxFrameCount);

			const FTemporalLogTransformArrayData& FrameData = TemporalFrames[MiddleRealIndex];
	
			if (FrameData.Frame == FrameNumberToFind)
			 	return TemporalFrames[MiddleRealIndex];
			
			if(FrameData.Frame < FrameNumberToFind)
				StartAbsIndex = MiddleAbsIndex + 1;
			else
				EndAbsIndex = MiddleAbsIndex - 1;
		}
		return FTemporalLogTransformArrayData();
	}
#endif
}