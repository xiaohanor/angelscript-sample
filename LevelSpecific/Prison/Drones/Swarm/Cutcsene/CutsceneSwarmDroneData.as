enum ECutsceneSwarmDroneMode
{
	Recording,
	Playback
}

struct FCutsceneSwarmBotData
{
	FHazeAcceleratedQuat AcceleratedRelativeRotation;

	FTransform OriginalRelativeTransform;
	FTransform RelativeTransform;

	FHazeSwarmBotAnimData AnimData;

	bool bRetracedInnerLayer;

	FCutsceneSwarmBotData(int _Id)
	{
		AnimData.BotIndex = _Id;
		bRetracedInnerLayer = Id >= SwarmDrone::TotalBotCount - SwarmDrone::RetractedInnerLayerBotCount;
	}

	// Blended constructor
	FCutsceneSwarmBotData(FCutsceneSwarmBotData A, FCutsceneSwarmBotData B, float Alpha)
	{
		AcceleratedRelativeRotation.SnapTo(FQuat::FastLerp(A.AcceleratedRelativeRotation.Value, B.AcceleratedRelativeRotation.Value, Alpha).GetNormalized());

		OriginalRelativeTransform = CutsceneSwarmDrone::Lerp(A.OriginalRelativeTransform, B.OriginalRelativeTransform, Alpha);
		RelativeTransform = CutsceneSwarmDrone::Lerp(A.RelativeTransform, B.RelativeTransform, Alpha);

		AnimData = CutsceneSwarmDrone::Lerp(A.AnimData, B.AnimData, Alpha);

		// Both should be identical
		bRetracedInnerLayer = A.bRetracedInnerLayer && B.bRetracedInnerLayer;
	}

	int GetId() const property
	{
		return AnimData.BotIndex;
	}

	FTransform GetWorldTransform() const property
	{
		return AnimData.Transform;
	}
}

struct FCutsceneSwarmDroneTickInfo
{
	float DeltaTime;
	float TimeFromSectionStart;

	FCutsceneSwarmDroneTickInfo(FHazeSequencerRecordParams SequencerTick)
	{
		DeltaTime = SequencerTick.DeltaTime;
		TimeFromSectionStart = SequencerTick.TimeFromSectionStart;
	}
}

struct FCutsceneSwarmDroneFrame
{
	FCutsceneSwarmDroneTickInfo TickInfo;

	TArray<FCutsceneSwarmBotData> SwarmBots;

	FTransform WorldMeshTransform;

	uint Frame = 0;

	FCutsceneSwarmDroneFrame(uint InFrame)
	{
		Frame = InFrame;
	}

	FCutsceneSwarmDroneFrame(uint InFrame, FHazeSequencerRecordParams SequencerTick)
	{
		Frame = InFrame;
		TickInfo = FCutsceneSwarmDroneTickInfo(SequencerTick);
	}

	// Blended constructor
	FCutsceneSwarmDroneFrame(FCutsceneSwarmDroneFrame A, FCutsceneSwarmDroneFrame B, float Alpha)
	{
		// Assuming both containers are eating their veggies
		for (int i = 0; i < A.SwarmBots.Num() && i < B.SwarmBots.Num(); i++)
			SwarmBots.Add(FCutsceneSwarmBotData(A.SwarmBots[i], B.SwarmBots[i], Alpha));

		WorldMeshTransform = CutsceneSwarmDrone::Lerp(A.WorldMeshTransform, B.WorldMeshTransform, Alpha);
	}

	void RecordActorInfo(FTransform MeshTransform)
	{
		WorldMeshTransform = MeshTransform;
	}

	void RecordBotInfo(const TArray<FCutsceneSwarmBotData> SwarmBotsData)
	{
		SwarmBots = SwarmBotsData;
	}

	void LoadFrame(ACutsceneSwarmDrone SwarmDrone) const
	{
		SwarmDrone.SwarmGroupMeshComponent.SetWorldRotation(WorldMeshTransform.Rotator());
		SwarmDrone.SwarmBots = SwarmBots;
	}
}

struct FCutsceneSwarmDroneMoveData
{
	float DeltaTime;
}

namespace CutsceneSwarmDrone
{
	FTransform Lerp(FTransform A, FTransform B, float Alpha)
	{
		return FTransform(FQuat::FastLerp(A.Rotation, B.Rotation, Alpha).GetNormalized(), Math::Lerp(A.Location, B.Location, Alpha), Math::Lerp(A.Scale3D, B.Scale3D, Alpha));
	}

	FHazeSwarmBotAnimData Lerp(FHazeSwarmBotAnimData A, FHazeSwarmBotAnimData B, float Alpha)
	{
		FHazeSwarmBotAnimData AnimData;
		AnimData.AnimState = A.AnimState;
		AnimData.BotIndex = A.BotIndex;
		AnimData.PlayRate = Math::Lerp(A.PlayRate, B.PlayRate, Alpha);
		AnimData.Transform = Lerp(A.Transform, B.Transform, Alpha);

		return AnimData;
	}
}