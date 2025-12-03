event void FSkylineBallBossLaserResponse(bool bOverlap);

class USkylineBallBossLaserResponseComponent : UBoxComponent
{
	UPROPERTY(EditAnywhere)
	FSkylineBallBossLaserResponse OnLaserOverlap;
	
	UPROPERTY(EditAnywhere)
	bool bAutoDestroy = true;

	UPROPERTY(EditAnywhere)
	float DestroyDelay = 1.0;

    UFUNCTION()
    void LaserOverlap(bool bOverlap)
    {
		OnLaserOverlap.Broadcast(bOverlap);
		if (bOverlap)
		{
			if (bAutoDestroy && DestroyDelay > KINDA_SMALL_NUMBER)
				Timer::SetTimer(this, n"Destroy", DestroyDelay);
			else if (bAutoDestroy && DestroyDelay < KINDA_SMALL_NUMBER && DestroyDelay > -KINDA_SMALL_NUMBER)
				Destroy();
		}
    }

	UFUNCTION()
	private void Destroy()
	{
		Owner.SetAutoDestroyWhenFinished(true);
	}
}