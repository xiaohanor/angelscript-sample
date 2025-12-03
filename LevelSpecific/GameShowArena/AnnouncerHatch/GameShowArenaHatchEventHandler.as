struct FGameShowArenaHatchHolderParams
{
	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingHatch;
}

struct FGameShowArenaHatchBombHolderParams
{
	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingBomb;
}
struct FGameShowArenaHatchBothPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingBomb;

	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingHatch;
}

UCLASS(Abstract)
class UGameShowArenaHatchEventHandler : UHazeEffectEventHandler
{

};