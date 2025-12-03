struct FGameShowArenaBombDisposalLidLiftParams
{
	FGameShowArenaBombDisposalLidLiftParams(FVector InLidLocation, AHazePlayerCharacter Player)
	{
		LidLocation = InLidLocation;
		PlayerHoldingLid = Player;
	}

	UPROPERTY()
	FVector LidLocation;

	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingLid;
}

struct FGameShowArenaBombDisposalLidCloseParams
{
	FGameShowArenaBombDisposalLidCloseParams(FVector InLidLocation, AHazePlayerCharacter Player)
	{
		LidLocation = InLidLocation;
		PlayerHoldingLid = Player;
	}

	UPROPERTY()
	FVector LidLocation;

	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingLid;
}
struct FGameShowArenaBombDisposalBombDisposalStartedParams
{
	UPROPERTY()
	FVector LidLocation;
	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingLid;
	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingBomb;
}

struct FGameShowArenaBombDisposalBombDisposedParams
{
	UPROPERTY()
	FVector LidLocation;
	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingLid;
	UPROPERTY()
	AHazePlayerCharacter PlayerHoldingBomb;
}

UCLASS(Abstract)
class UGameShowArenaBombDisposalEffectHandler : UHazeEffectEventHandler
{
	/** Triggers when the player not holding a bomb lifts the lid. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidLiftStart(FGameShowArenaBombDisposalLidLiftParams Params) {}
	/** Triggers when the player not holding a bomb closes the lid without a bomb having been thrown in. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidCloseStart(FGameShowArenaBombDisposalLidCloseParams Params) {}

	/** Triggers when interaction is done and one player throws in bomb as the other closes the lid.  */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBombDisposalStarted(FGameShowArenaBombDisposalBombDisposalStartedParams Params) {}

	/** Triggers when bomb has been thrown in and lid has been closed. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBombDisposed(FGameShowArenaBombDisposalBombDisposedParams Params) {}
};