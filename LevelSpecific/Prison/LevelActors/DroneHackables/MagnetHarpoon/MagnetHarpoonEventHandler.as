struct FMagnetHarpoonOnHitAttachEventData
{
	UPROPERTY(BlueprintReadOnly)
	AActor HitActor;

	UPROPERTY(BlueprintReadOnly)
	FVector AttachLocation;
};

UCLASS(Abstract)
class UMagnetHarpoonEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AMagnetHarpoon MagnetHarpoon;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetHarpoon = Cast<AMagnetHarpoon>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartHack()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopHack()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch()
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRetract()
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyRetracted()
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitAttach(FMagnetHarpoonOnHitAttachEventData EventData)
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitFail()
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetach()
	{
	}
};