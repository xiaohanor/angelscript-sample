class USkylineSentryDroneEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASkylineSentryDrone SentryDrone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SentryDrone = Cast<ASkylineSentryDrone>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FHitResult Hit) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Explode() { }
}