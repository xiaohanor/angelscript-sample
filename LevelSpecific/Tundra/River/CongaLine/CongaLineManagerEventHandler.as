struct FCongaTileLightUpEventParams
{
	UPROPERTY()
	ACongaGlowingTile Tile;
}

struct FCongaLowerWallEventParams
{
	UPROPERTY()
	EMonkeyCongaWallIdentifier Wall;
}

struct FCongaLineDancerGainedEventData
{
	UPROPERTY()
	UCongaLineDancerComponent DancerComp;

	UPROPERTY()
	int NewMonkeyCount;

	UPROPERTY()
	AHazePlayerCharacter Player;
};

struct FCongaLinePlayerLostDancersEventData
{
	UPROPERTY()
	int LostMonkeyCount;

	UPROPERTY()
	int NewMonkeyCount;

	UPROPERTY()
	AHazePlayerCharacter Player;
};


UCLASS(Abstract)
class UCongaLineManagerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDancerGained(FCongaLineDancerGainedEventData EventData)
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDancersLost(FCongaLinePlayerLostDancersEventData EventData)
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TileLightUp(FCongaTileLightUpEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TileUnlit(FCongaTileLightUpEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RowLit()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RowUnlit()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LowerWall(FCongaLowerWallEventParams Params)
	{
	}
};