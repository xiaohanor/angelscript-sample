UCLASS(Abstract)
class UIslandRedBlueOverheat2DWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bOverheatBarVisible = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float OverheatAlpha = 0.0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsOverheated = false;

	// Since we are in fullscreen, both widgets will be added to one of the players so the player variable wont match.
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter ActualPlayerOwner;
}