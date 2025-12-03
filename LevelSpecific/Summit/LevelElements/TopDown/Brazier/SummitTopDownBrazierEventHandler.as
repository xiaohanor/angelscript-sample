struct FSummitTopDownBrazierOnHitByAcidParams
{
	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	float AlphaToCompletion;

	UPROPERTY()
	bool bIsAlreadyActive;
}

UCLASS(Abstract)
class USummitTopDownBrazierEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWingsStartedMovingOut()
	{	
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWingsFinishedMovingOut()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWingsStartedMovingBack()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWingsFinishedMovingBack()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByAcid(FSummitTopDownBrazierOnHitByAcidParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinished()
	{		
	}
};