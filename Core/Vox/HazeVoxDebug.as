
namespace VoxCVar
{
	const FConsoleVariable HazeVoxDisablePlayOnce("HazeVox.DisablePlayOnce", 0);
	const FConsoleVariable HazeVoxDisableCooldown("HazeVox.DisableCooldown", 0);
	const FConsoleVariable HazeVoxAutoResetTriggers("HazeVox.AutoResetTriggers", 0);
	const FConsoleVariable HazeVoxShowViewportTimeline("HazeVox.ShowViewportTimeline", 0);
}

UCLASS(Config = EditorPerProjectUserSettings)
class UHazeVoxDebugConfig
{
	UPROPERTY(Config)
	bool bTrackPlayingEvents = false;

	UPROPERTY(Config)
	bool bShowTriggerVisualizers = false;

	UPROPERTY(Config)
	bool bRotateTriggerVisualizers = false;

	UPROPERTY(Config)
	bool bShowPlayerDistances = false;
}

struct FVoxDebugVoiceLine
{
	int Index;
	FString AssetName;
	FString State;
	FLinearColor Color;
	FString ActorName;
	FName CharacterName;
	FLinearColor CharacterColor;
}

struct FVoxDebugRuntimeAsset
{
	int DebugTriggerId;
	FString Name;
	FString State;
	FLinearColor Color;
	TArray<FVoxDebugVoiceLine> VoiceLines;
}

struct FVoxDebugLane
{
	EHazeVoxLaneName LaneName;
	TArray<FVoxDebugRuntimeAsset> Assets;
	TArray<FVoxDebugRuntimeAsset> TailingOutAssets;
}

struct FVoxDevTimelineValue
{
	int DebugTriggerId = -1;
	FLinearColor Color;

	FString DisplayText;
	int VoiceLineIndex;
	FString TooltipText;

	bool DrawTogetherWith(const FVoxDevTimelineValue& Other) const
	{
		return DebugTriggerId == Other.DebugTriggerId && Color == Other.Color;
	}
};

struct FVoxDevTimelineSection
{
	FVoxDevTimelineValue Value;
	EVoxDevTimelineSectionMode SectionMode = EVoxDevTimelineSectionMode::Colored;

	int StartFrame = -1;
	int EndFrame = -1;

	float StartTime = -1;
	float EndTime = -1;
};

struct FVoxDevTimelineLaneSlot
{
	TArray<FVoxDevTimelineSection> Sections;

	int StartFrame = -1;
	int EndFrame = -1;

	void AddValue(int Frame, float GameTime, FVoxDevTimelineValue Value)
	{
		EndFrame = Frame;

		if (Sections.Num() != 0 && Sections.Last().Value.DrawTogetherWith(Value))
		{
			if (Sections.Last().EndFrame == Frame - 1)
			{
				Sections.Last().EndFrame = Frame;
				Sections.Last().EndTime = GameTime;
				return;
			}
		}

		FVoxDevTimelineSection NewSection;
		NewSection.StartFrame = Frame;
		NewSection.EndFrame = Frame;
		NewSection.StartTime = GameTime;
		NewSection.EndTime = GameTime;
		NewSection.Value = Value;
		Sections.Add(NewSection);
	};
};

struct FVoxDevTimelineLane
{
	FString Name;
	EHazeVoxLaneName LaneName;

	TArray<FVoxDevTimelineLaneSlot> Slots;
};

namespace VoxHelpers
{
	FString BuildLaneDebugName(EHazeVoxLaneName LaneName)
	{
		switch (LaneName)
		{
			case EHazeVoxLaneName::First:
				return "FirstLane";
			case EHazeVoxLaneName::Second:
				return "SecondLane";
			case EHazeVoxLaneName::Third:
				return "ThirdLane";
			case EHazeVoxLaneName::Generics:
				return "Generics";
			case EHazeVoxLaneName::EnemyCombat:
				return "EnemyCombat";
			case EHazeVoxLaneName::Efforts:
				return "EffortLane";
		}
	}
}

namespace VoxDebug
{
	void TemporalLogEvent(FString Path, FString Event)
	{
#if TEST
		TEMPORAL_LOG(Path).Event(Event);
		TEMPORAL_LOG("Vox/Summary").Event(f"[{Path.RightChop(4)}] {Event}");
#endif
	}

	void TelemetryVoxAsset(FName EventName, UHazeVoxAsset VoxAsset)
	{
#if TEST
		FString Dummy;
		VoxDebug::TelemetryVoxAsset(EventName, VoxAsset, Dummy);
#endif
	}

	void TelemetryVoxAsset(FName EventName, UHazeVoxAsset VoxAsset, FString TelemetryData, bool bForceEfforts = false)
	{
#if TEST
		if (!IsValid(VoxAsset))
			return;

		// No telemetry for efforts unless forced
		if (bForceEfforts == false && VoxAsset.Lane == EHazeVoxLaneName::Efforts)
		{
			return;
		}

		// Telemetry commented out, we don't want it sent to EA
		// const FString EventData = TelemetryData.IsEmpty() ? f"{VoxAsset.Name}" : f"{VoxAsset.Name};{TelemetryData}";
		// Telemetry::TriggerGameEventWithData(nullptr, EventName, EventData);
		// Log(n"VoxTelemetry", f"{EventName} - {EventData}");
#endif
	}

	bool IsVoDesigner()
	{
#if EDITOR
		return VoxEditor::IsVoDesigner();
#else
		return false;
#endif
	}
}
