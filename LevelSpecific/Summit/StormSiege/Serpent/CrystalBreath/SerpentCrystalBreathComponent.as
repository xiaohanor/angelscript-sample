UCLASS(Abstract)
class USerpentCrystalBreathComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams EnterSequenceParams;
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams MainSequenceParams;
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams ExitSequenceParams;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams WaterfallEnterSequenceParams;
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams WaterfallMainSequenceParams;
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams WaterfallExitSequenceParams;

	UPROPERTY(EditDefaultsOnly)
	float DelayBeforeShooting = 1.0;

	UPROPERTY(EditDefaultsOnly)
	float WaterfallDelayBeforeShooting = 1.0;
};