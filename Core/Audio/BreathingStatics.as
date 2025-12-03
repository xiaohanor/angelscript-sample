USTRUCT()
struct FBreathingTagData
{
	UPROPERTY(Category = Inhale)
	UHazeAudioEvent ClosedMouthInhaleEvent;

	UPROPERTY(Category = Inhale)
	UHazeAudioEvent OpenMouthInhaleEvent;

	UPROPERTY(Category = Inhale, meta=(UIMin = -10.0, UIMax = 0.0, Delta = 0.1, ForceUnits = "Seconds"))
	float RandomOffsetMin = 0.0;

	UPROPERTY(Category = Inhale, meta=(UIMin = 0, UIMax = 10.0, Delta = 0.1, ForceUnits = "Seconds"))
	float RandomOffsetMax = 0.0;

	UPROPERTY(Category = Exhale)
	UHazeAudioEvent ClosedMouthExhaleEvent;

	UPROPERTY(Category = Exhale)
	UHazeAudioEvent OpenMouthExhaleEvent;	
}

namespace Breathing
{
}