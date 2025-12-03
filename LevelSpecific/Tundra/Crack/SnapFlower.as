struct FSnapFlowerAnimData
{
	TOptional<uint> FrameOfSnap;
	TOptional<uint> FrameOfInteract;

	bool ShouldSnap() const
	{
		if(!FrameOfSnap.IsSet())
			return false;

		return Time::FrameNumber - FrameOfSnap.Value <= 1;
	}

	bool ShouldInteract() const
	{
		if(!FrameOfInteract.IsSet())
			return false;
	
		return Time::FrameNumber - FrameOfInteract.Value <= 1;
	}
}

UCLASS(Abstract)
class ASnapFlower : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY()
	UForceFeedbackEffect SnapForceFeedback;
	
	UPROPERTY()
	UForceFeedbackEffect InteractForceFeedback;

	FSnapFlowerAnimData AnimData;

	UFUNCTION()
	void TriggerSnap()
	{
		AnimData.FrameOfSnap = Time::FrameNumber;
		USnapFlowerEffectHandler::Trigger_OnSnapClose(this);
		ForceFeedback::PlayWorldForceFeedback(SnapForceFeedback, ActorLocation, true, this, 300, 1500);
	}

	UFUNCTION()
	void TriggerInteract()
	{
		AnimData.FrameOfInteract = Time::FrameNumber;
		USnapFlowerEffectHandler::Trigger_OnReactToFloatingPole(this);
		ForceFeedback::PlayWorldForceFeedback(InteractForceFeedback, ActorLocation, true, this, 300, 1500);
	}
}