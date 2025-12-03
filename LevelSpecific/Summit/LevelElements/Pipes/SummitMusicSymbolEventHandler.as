struct FOnSummitSymbolLitParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Orientation;

	FOnSummitSymbolLitParams(FVector NewLoc, FRotator NewOrientation)
	{
		Location = NewLoc;
		Orientation = NewOrientation;
	}
}

UCLASS(Abstract)
class USummitMusicSymbolEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSymbolLit(FOnSummitSymbolLitParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSymbolUnlit(FOnSummitSymbolLitParams Params) {}
};