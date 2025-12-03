struct FOnQuickCoverButtonMash
{
	UPROPERTY()
	AHazePlayerCharacter PlayerMashing;
}

UCLASS(Abstract)
class USolarFlareVOQuickCoverEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerButtonMashing(FOnQuickCoverButtonMash Params)
	{
	}
};