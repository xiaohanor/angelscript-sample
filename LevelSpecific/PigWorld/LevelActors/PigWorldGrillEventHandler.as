struct FPigWorldGrillParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


UCLASS(Abstract)
class UPigWorldGrillEventHandler : UHazeEffectEventHandler
{

	AHazePlayerCharacter AHazePlayerCharacter;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TurnOnGrill(FPigWorldGrillParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrillingEntered(FPigWorldGrillParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrillingPerfect(FPigWorldGrillParams Params) {}
};