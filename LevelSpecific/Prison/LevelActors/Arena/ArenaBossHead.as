UCLASS(Abstract)
class AArenaBossHead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent LeftCableAttachComp;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent RightCableAttachComp;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent ButtonMashAttachComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	float MashProgress = 0.0;

	void Hacked()
	{
		BP_Hacked();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Hacked() {}

	UFUNCTION(BlueprintPure)
	float GetMashProgress()
	{
		return MashProgress;
	}

	UFUNCTION()
	void StartOverHeating()
	{
		BP_StartOverHeating();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartOverHeating() {}

	void TriggerIntermittentExplosion()
	{
		BP_TriggerIntermittentExplosion();
	}

	UFUNCTION(BlueprintEvent)
	void BP_TriggerIntermittentExplosion() {}

	void HeadPoppedOff()
	{
		BP_HeadPoppedOff();
	}

	UFUNCTION(BlueprintEvent)
	void BP_HeadPoppedOff() {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_ActivateLaserEyes() {}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void BP_DeactivateLaserEyes() {}
}