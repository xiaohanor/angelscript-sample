struct FTundraBigCrackBirdPlayerParams
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter Player;

	FTundraBigCrackBirdPlayerParams(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}

UCLASS(Abstract)
class UBigCrackBirdEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ABigCrackBird CrackBird;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrackBird = Cast<ABigCrackBird>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitWithLog() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitWall() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LiftFromNest(FTundraBigCrackBirdPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlaceInNest(FTundraBigCrackBirdPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CatapultLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CatapultLand() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStuck(FTundraBigCrackBirdPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerSquishedByEgg(FTundraBigCrackBirdPlayerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}
}