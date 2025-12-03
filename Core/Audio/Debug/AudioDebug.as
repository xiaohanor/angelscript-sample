
// NOTE: Any added types must be added to visualization enums!
// If you want to connect the enum to set a console var, see "SetConsoleCvar" below.
enum EHazeAudioDebugType
{
	// Shared
	Players,
	AudioComponents,
	SoundDefs,
	Zones,
	Spots,
	Splines,
	Delay,
	Gameplay,
	// Viewport only
	Events,
	Banks,
	Music,
	BusMixers,
	NodeProperties,
	Network,
	Movement,
	Proxy,
	Loudness,
	// Uniques
	Cutscenes,
	Effects,
	Performance,

	NumOfTypes
}

enum EDebugAudioWorldVisualization
{
	Players,
	AudioComponents,
	SoundDefs,
	Zones,
	Spots,
	Splines,
	Delay,
	Gameplay,

	Num
}

enum EDebugAudioViewportVisualization
{
	Players,
	AudioComponents,
	SoundDefs,
	Zones,
	Spots,
	Splines,
	Delay,
	Gameplay,
	Events,
	Banks,
	Music,
	BusMixers,
	NodeProperties,
	Network,
	Movement,
	Proxy,
	Loudness,
	Cutscenes,
	Effects,
	Performance,

	Num
}

// Shares the order of above, but might have some unique ones, such as RTPC.
enum EDebugAudioFilter
{
	// Shared
	Players,
	AudioComponents,
	SoundDefs,
	Zones,
	Spots,
	Splines,
	Delay,
	Gameplay,
	// Viewport only
	Events,
	Banks,
	Music,
	BusMixers,
	NodeProperties,
	Network,
	Movement,
	// Uniques
	Cutscenes,
	RTPCs,

	Num
}

enum EDebugAudioOutputBlock
{
	Remote,
	Control,
	None,

	Num,
}

// Remember which groups to show.
#if TEST

const FConsoleVariable CVar_AudioDebugPlayers("HazeAudio.DebugPlayers", 0);
const FConsoleVariable CVar_AudioDebugAudioComponents("HazeAudio.DebugAudioComponents", 0);
const FConsoleVariable CVar_AudioDebugSoundDefs("HazeAudio.DebugSoundDefs", 0);
const FConsoleVariable CVar_AudioDebugZones("HazeAudio.DebugZones", 0);
const FConsoleVariable CVar_AudioDebugSpots("HazeAudio.DebugSpots", 0);
const FConsoleVariable CVar_AudioDebugDelay("HazeAudio.DebugDelay", 0);
const FConsoleVariable CVar_AudioDebugGameplay("HazeAudio.DebugGameplay", 0);
// Viewport
const FConsoleVariable CVar_AudioDebugEvents("HazeAudio.DebugEvents", 0);
const FConsoleVariable CVar_AudioDebugBanks("HazeAudio.DebugBanks", 0);
const FConsoleVariable CVar_AudioDebugMusic("HazeAudio.DebugMusic", 0);
const FConsoleVariable CVar_AudioDebugBusMixers("HazeAudio.DebugBusMixers", 0);
const FConsoleVariable CVar_AudioDebugNodeProperties("HazeAudio.DebugNodeProperties", 0);
const FConsoleVariable CVar_AudioDebugNetwork("HazeAudio.DebugNetwork", 0);
const FConsoleVariable CVar_AudioDebugMovement("HazeAudio.DebugMovement", 0);
// Unique
const FConsoleVariable CVar_AudioDebugCutscenes("HazeAudio.DebugCutscenes", 0);

#endif

const FConsoleVariable CVar_AudioDebugWorldVisualizationFlags("HazeAudio.DebugWorldVisualizationFlags", 0);
const FConsoleVariable CVar_AudioDebugViewportVisualizationFlags("HazeAudio.DebugViewportVisualizationFlags", 0);

namespace AudioDebug
{
	bool IsEnabled(EHazeAudioDebugType DebugType)
	{
		#if TEST
		switch (DebugType)
		{
			case EHazeAudioDebugType::Players:
			return CVar_AudioDebugPlayers.GetInt() != 0;
			case EHazeAudioDebugType::AudioComponents:
			return CVar_AudioDebugAudioComponents.GetInt() != 0;
			case EHazeAudioDebugType::SoundDefs:
			return CVar_AudioDebugSoundDefs.GetInt() != 0;
			case EHazeAudioDebugType::Zones:
			return CVar_AudioDebugZones.GetInt() != 0;
			case EHazeAudioDebugType::Spots:
			return CVar_AudioDebugSpots.GetInt() != 0;
			case EHazeAudioDebugType::Gameplay:
			return CVar_AudioDebugGameplay.GetInt() != 0;
			case EHazeAudioDebugType::Delay:
			return CVar_AudioDebugDelay.GetInt() != 0;
			case EHazeAudioDebugType::Events:
			return CVar_AudioDebugEvents.GetInt() != 0;
			case EHazeAudioDebugType::Banks:
			return CVar_AudioDebugBanks.GetInt() != 0;
			case EHazeAudioDebugType::Music:
			return CVar_AudioDebugMusic.GetInt() != 0;
			case EHazeAudioDebugType::BusMixers:
			return CVar_AudioDebugBusMixers.GetInt() != 0;
			case EHazeAudioDebugType::NodeProperties:
			return CVar_AudioDebugNodeProperties.GetInt() != 0;
			case EHazeAudioDebugType::Network:
			return CVar_AudioDebugNetwork.GetInt() != 0;
			case EHazeAudioDebugType::Movement:
			return CVar_AudioDebugMovement.GetInt() != 0;
			case EHazeAudioDebugType::Cutscenes:
			return CVar_AudioDebugCutscenes.GetInt() != 0;
			default: break;
		}
		#endif

		return false;
	}

	bool IsEnabled(EDebugAudioWorldVisualization WorldDebug)
	{
		#if TEST
		return CVar_AudioDebugWorldVisualizationFlags.GetInt() & (1 << uint(WorldDebug)) != 0;
		#else
		return false;
		#endif
	}

	bool IsEnabled(EDebugAudioViewportVisualization ViewportDebug)
	{
		#if TEST
		return CVar_AudioDebugViewportVisualizationFlags.GetInt() & (1 << uint(ViewportDebug)) != 0;
		#else
		return false;
		#endif
	}

	int GetWorldFlags()
	{
		return CVar_AudioDebugWorldVisualizationFlags.GetInt();
	}

	int GetViewFlags()
	{
		return CVar_AudioDebugViewportVisualizationFlags.GetInt();
	}

	UFUNCTION(BlueprintPure, Meta = (DevelopmentOnly))
	bool IsAnyDebugFlagSet()
	{
		#if TEST
		return GetWorldFlags() != 0 || GetViewFlags() != 0;
		#else
		return false;
		#endif
	}

	void SetConsoleCvar(EHazeAudioDebugType DebugType, bool bEnable)
	{
		#if TEST
		auto Value = bEnable ? 1 : 0;
		switch (DebugType)
		{
			case EHazeAudioDebugType::Players:
			Console::SetConsoleVariableInt("HazeAudio.DebugPlayers", Value, "", true);
			break;
			case EHazeAudioDebugType::AudioComponents:
			Console::SetConsoleVariableInt("HazeAudio.DebugAudioComponents", Value, "", true);
			break;
			case EHazeAudioDebugType::SoundDefs:
			Console::SetConsoleVariableInt("HazeAudio.DebugSoundDefs", Value, "", true);
			break;
			case EHazeAudioDebugType::Spots:
			Console::SetConsoleVariableInt("HazeAudio.DebugSpots", Value, "", bOverrideValueSetByConsole = true);
			break;
			case EHazeAudioDebugType::Zones:
			Console::SetConsoleVariableInt("HazeAudio.DebugZones", Value, "", true);
			break;
			case EHazeAudioDebugType::Delay:
			Console::SetConsoleVariableInt("HazeAudio.DebugDelay", Value, "", true);
			break;
			case EHazeAudioDebugType::Gameplay:
			Console::SetConsoleVariableInt("HazeAudio.DebugGameplay", Value, "", true);
			break;
			case EHazeAudioDebugType::Events:
			Console::SetConsoleVariableInt("HazeAudio.DebugEvents", Value, "", true);
			break;
			case EHazeAudioDebugType::Banks:
			Console::SetConsoleVariableInt("HazeAudio.DebugBanks", Value, "", true);
			break;
			case EHazeAudioDebugType::Music:
			Console::SetConsoleVariableInt("HazeAudio.DebugMusic", Value, "", true);
			break;
			case EHazeAudioDebugType::BusMixers:
			Console::SetConsoleVariableInt("HazeAudio.DebugBusMixers", Value, "", true);
			break;
			case EHazeAudioDebugType::NodeProperties:
			Console::SetConsoleVariableInt("HazeAudio.DebugNodeProperties", Value, "", true);
			break;
			case EHazeAudioDebugType::Network:
			Console::SetConsoleVariableInt("HazeAudio.DebugNetwork", Value, "", true);
			break;
			case EHazeAudioDebugType::Cutscenes:
			Console::SetConsoleVariableInt("HazeAudio.DebugCutscenes", Value, "", true);
			break;
			default: break;
		}
		#endif
	}

	int ToggleBit(const int& Current, const int& BitIndex, bool bSetConsoleVar)
	{
		int CurrentBits = Current;

		if (Current & (1 << uint(BitIndex)) != 0)
		{
			CurrentBits = int(uint(CurrentBits) & ~uint(1 << uint(BitIndex)));

			if (bSetConsoleVar)
				SetConsoleCvar(EHazeAudioDebugType(BitIndex), false);
		}
		else
		{
			CurrentBits = int(uint(CurrentBits) | uint(1 << uint(BitIndex)));
		}

		return CurrentBits;
	}

	int ToggleDebugging(EDebugAudioWorldVisualization VisualizationType)
	{
		int32 Current = ToggleBit(
			CVar_AudioDebugWorldVisualizationFlags.GetInt(),
			int(VisualizationType),
			true);

		Console::SetConsoleVariableInt("HazeAudio.DebugWorldVisualizationFlags", Current, "", true);
		return Current;
	}

	int ToggleDebugging(EDebugAudioViewportVisualization VisualizationType)
	{
		int32 Current = ToggleBit(
			CVar_AudioDebugViewportVisualizationFlags.GetInt(),
			int(VisualizationType),
			true);

		Console::SetConsoleVariableInt("HazeAudio.DebugViewportVisualizationFlags", Current, "", true);
		return Current;
	}

	void ResetConsoleVars()
	{
		Console::SetConsoleVariableInt("HazeAudio.DebugWorldVisualizationFlags", 0, "", true);
		Console::SetConsoleVariableInt("HazeAudio.DebugViewportVisualizationFlags", 0, "", true);

		for (int i = 0; i < int(EHazeAudioDebugType::NumOfTypes); ++i)
		{
			bool bEnabled = AudioDebug::IsEnabled(EHazeAudioDebugType(i));
			// Can only turn on, not off.
			if (!bEnabled)
				continue;

			SetConsoleCvar(EHazeAudioDebugType(i), false);
		}
	}

	// Check if anything has been turned on from console
	void CheckConsoleVars()
	{
		for (int i = 0; i < int(EHazeAudioDebugType::NumOfTypes); ++i)
		{
			bool bShouldBeEnabled = AudioDebug::IsEnabled(EHazeAudioDebugType(i));
			// Can only turn on, not off.
			if (!bShouldBeEnabled)
				continue;

			if (i < int(EDebugAudioWorldVisualization::Num))
			{
				bool bIsEnabled = CVar_AudioDebugWorldVisualizationFlags.GetInt() & (1 << uint(i)) != 0;
				if (bShouldBeEnabled != bIsEnabled)
					ToggleDebugging(EDebugAudioWorldVisualization(i));
			}

			if (i < int(EDebugAudioViewportVisualization::Num))
			{
				bool bIsEnabled = CVar_AudioDebugViewportVisualizationFlags.GetInt() & (1 << uint(i)) != 0;
				if (bShouldBeEnabled != bIsEnabled)
					ToggleDebugging(EDebugAudioViewportVisualization(i));
			}

		}
	}

	FString GetActorLabel(AActor Actor)
	{
		#if EDITOR
		return Actor.GetActorLabel();
		#else
		return Actor.GetName().ToString();
		#endif
	}
}
