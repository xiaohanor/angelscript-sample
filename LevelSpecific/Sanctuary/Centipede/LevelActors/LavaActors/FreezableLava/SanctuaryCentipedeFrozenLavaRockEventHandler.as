UCLASS(Abstract)
class USanctuaryCentipedeFrozenLavaRockEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ASanctuaryCentipedeFrozenLavaRock Rock;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Rock = Cast<ASanctuaryCentipedeFrozenLavaRock>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFreeze()
	{
		DevPrintStringEvent("LavaRock","OnStartFreeze");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReFreeze()
	{
		DevPrintStringEvent("LavaRock","OnReFreeze");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolid()
	{
		DevPrintStringEvent("LavaRock","OnSolid");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMelt()
	{
		DevPrintStringEvent("LavaRock","OnStartMelt");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyMelted()
	{
		DevPrintStringEvent("LavaRock","OnFullyMelted");
	}
};

struct FSanctuaryFrozenLavaRockManagerEventParams
{
	FSanctuaryFrozenLavaRockManagerEventParams(ASanctuaryCentipedeFrozenLavaRock InRock)
	{
		Rock = InRock;
	}

	UPROPERTY(BlueprintReadOnly)
	ASanctuaryCentipedeFrozenLavaRock Rock;
}

UCLASS(Abstract)
class USanctuaryCentipedeFrozenLavaRockManagerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFreeze(FSanctuaryFrozenLavaRockManagerEventParams Params)
	{
		DevPrintStringEvent("LavaRock","OnStartFreeze");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReFreeze(FSanctuaryFrozenLavaRockManagerEventParams Params)
	{
		DevPrintStringEvent("LavaRock","OnReFreeze");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolid(FSanctuaryFrozenLavaRockManagerEventParams Params)
	{
		DevPrintStringEvent("LavaRock","OnSolid");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMelt(FSanctuaryFrozenLavaRockManagerEventParams Params)
	{
		DevPrintStringEvent("LavaRock","OnStartMelt");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyMelted(FSanctuaryFrozenLavaRockManagerEventParams Params)
	{
		DevPrintStringEvent("LavaRock","OnFullyMelted");
	}
};