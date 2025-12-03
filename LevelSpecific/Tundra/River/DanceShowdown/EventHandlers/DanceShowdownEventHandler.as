struct FDanceShowdownNewPoseEvent
{
	UPROPERTY()
	EDanceShowdownPose Pose;
}

struct FDanceShowdownSequenceSucceededEvent
{
	UPROPERTY()
	int SequencesCompleted;
}

struct FDanceShowdownLastBeatEvent
{
	UPROPERTY()
	int Stage;
}

UCLASS(Abstract)
class UDanceShowdownEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnVFXAnticipation() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLastBeat(FDanceShowdownLastBeatEvent EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPoseUpdated(FDanceShowdownNewPoseEvent EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSequenceSucceeded(FDanceShowdownSequenceSucceededEvent EventData) {}
};