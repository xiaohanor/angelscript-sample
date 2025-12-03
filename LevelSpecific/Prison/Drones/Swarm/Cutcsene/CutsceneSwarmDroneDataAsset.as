class UCutsceneSwarmDroneDataAsset : UDataAsset
{
	UFUNCTION(CallInEditor)
	void Flush()
	{
		Reset();
	}

	UFUNCTION(CallInEditor)
	void Make_50_Frames()
	{
		for (int i = 0; i < 50; i++)
		{
			for (int j = 0; j < SwarmDrone::TotalBotCount; j++)
				BotTransforms.Add(FTransform3f());

			TimeFromStartSectionMap.Add(0);
			SwarmGroupMeshRotations.Add(FRotator3f());
		}

		Frames = uint(TimeFromStartSectionMap.Num());
	}

	// Contains relative bot transforms
	// { B0 frames, B1 frames, B2 frames,... }
	UPROPERTY(NotVisible, BlueprintHidden)
	private TArray<FTransform3f> BotTransforms;

	// Relative rotations for swarm drone mesh
	UPROPERTY(NotVisible, BlueprintHidden)
	private TArray<FRotator3f> SwarmGroupMeshRotations;

	// { TimeFromSectionStart }
	UPROPERTY(NotVisible, BlueprintHidden)
	private TArray<float> TimeFromStartSectionMap;

	UPROPERTY(VisibleInstanceOnly, BlueprintHidden)
	uint Frames = 0;

	void Reset()
	{
		BotTransforms.Empty();
		SwarmGroupMeshRotations.Empty();
		TimeFromStartSectionMap.Empty();

		Frames = 0;

		MarkPackageDirty();
	}

	void WriteFrame(const FCutsceneSwarmDroneFrame& Frame)
	{
		// Transforms
		{
			// Mesh rotation
			{
				FRotator3f MeshRotation(Frame.WorldMeshTransform.Rotator());
				SwarmGroupMeshRotations.Add(MeshRotation);
			}

			// Bots
			{
				for (int i = 0; i < SwarmDrone::TotalBotCount; i++)
				{
					auto SwarmBotInfo = Frame.SwarmBots[i];
					BotTransforms.Add(FTransform3f(SwarmBotInfo.RelativeTransform));
				}
			}
		}

		// Sequencer tick info
		{
			TimeFromStartSectionMap.Add(Frame.TickInfo.TimeFromSectionStart);
		}

		Frames++;

		// MarkPackageDirty();
	}

	void WriteFrame_Light(const TArray<FCutsceneSwarmBotData>& SwarmBots, const FRotator3f& MeshRotation, float TimeFromSectionStart)
	{
		SwarmGroupMeshRotations.Add(MeshRotation);

		// Bots
		for (auto SwarmBot : SwarmBots)
		{
			FTransform3f Transform = FTransform3f(SwarmBot.RelativeTransform);
			BotTransforms.Add(Transform);
		}

		TimeFromStartSectionMap.Add(TimeFromSectionStart);

		Frames++;
	}

	private FCutsceneSwarmDroneFrame MakeFrameFromIndex(uint Index)
	{
		FCutsceneSwarmDroneFrame Frame(Index);

		// Mesh rotation
		{
			Frame.WorldMeshTransform.SetRotation(FRotator(SwarmGroupMeshRotations[Index]));
		}

		// Bot stuff (😏)
		for (int BotIndex = 0; BotIndex < SwarmDrone::TotalBotCount; BotIndex++)
		{
			FCutsceneSwarmBotData SwarmBotData(BotIndex);

			uint MapIndex = Index * uint(SwarmDrone::TotalBotCount) + uint(BotIndex);
			SwarmBotData.RelativeTransform = FTransform(BotTransforms[MapIndex]);
			Frame.SwarmBots.Add(SwarmBotData);
		}

		// Tick info stuff
		{
			Frame.TickInfo.TimeFromSectionStart = TimeFromStartSectionMap[Index];
		}

		return Frame;
	}

	FCutsceneSwarmDroneFrame GetFrameAtTime(float Time)
	{
		if (TimeFromStartSectionMap.Num() <= 2)
			return FCutsceneSwarmDroneFrame();

		// Eman TODO: Gross... at least make binary search instead
		for (uint i = uint(TimeFromStartSectionMap.Num() - 2); i >= 0; i--)
		{
			float TimeFromSectionStart = TimeFromStartSectionMap[i];
			if (TimeFromSectionStart > Time)
				continue;

			// Get frames
			FCutsceneSwarmDroneFrame FrameA = MakeFrameFromIndex(i);
			FCutsceneSwarmDroneFrame FrameB = MakeFrameFromIndex(i + 1);

			// Get alpha
			const float Divisor = Math::Max(FrameB.TickInfo.TimeFromSectionStart - FrameA.TickInfo.TimeFromSectionStart, SMALL_NUMBER);
			const float Alpha = Math::Saturate((Time - FrameA.TickInfo.TimeFromSectionStart) / Divisor);

			// Create blend
			return FCutsceneSwarmDroneFrame(FrameA, FrameB, Alpha);
		}

		return FCutsceneSwarmDroneFrame();
	}
}