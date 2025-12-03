UCLASS(Abstract)
class UIslandJetpackSidescrollerFuelWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFuelWidgetVisible = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float FuelAlpha = 0.0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHasRunOutOfFuel = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bJetpackIsActive = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsBoosting = false;

	// Since we are in fullscreen, both widgets will be added to one of the players so the player variable wont match.
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter ActualPlayerOwner;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UIslandJetpackSettings JetpackSettings;
}