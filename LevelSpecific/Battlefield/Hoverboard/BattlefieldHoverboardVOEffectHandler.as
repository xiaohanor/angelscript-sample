struct FBattlefieldHoverboardVOParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FBattlefieldHoverboardVOParams(AHazePlayerCharacter CurrentPlayer)
	{
		Player = CurrentPlayer;
	}
}

UCLASS(Abstract)
class UBattlefieldHoverboardVOEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBattlefieldTotalScore25k(FBattlefieldHoverboardVOParams Params) {Print("TOTAL SCORE REACHED 25k");}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBattlefieldTotalScore50k(FBattlefieldHoverboardVOParams Params) {Print("TOTAL SCORE REACHED 50k");}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBattlefieldTotalScore75k(FBattlefieldHoverboardVOParams Params) {Print("TOTAL SCORE REACHED 75k");}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBattlefieldTotalScore100k(FBattlefieldHoverboardVOParams Params) {Print("TOTAL SCORE REACHED 100k");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBattlefieldCombo5k(FBattlefieldHoverboardVOParams Params) {Print("COMBO WOOO 5k");}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBattlefieldCombo10k(FBattlefieldHoverboardVOParams Params) {Print("COMBO WOOO 10k");}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBattlefieldCombo20k(FBattlefieldHoverboardVOParams Params) {Print("COMBO WOOO 20k");}
};