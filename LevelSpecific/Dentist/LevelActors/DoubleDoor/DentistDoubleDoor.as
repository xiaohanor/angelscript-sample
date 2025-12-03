event void FDentistDoubleDoorOpenedSignature();

UCLASS(Abstract)
class ADentistDoubleDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp2;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditInstanceOnly)
	ADentistDoubleDoorButton Button1;

	UPROPERTY(EditInstanceOnly)
	ADentistDoubleDoorButton Button2;

	UPROPERTY()
	FDentistDoubleDoorOpenedSignature OnDoubleDoorOpened;

	bool bOpened = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Button1.OnButtonActivated.AddUFunction(this, n"HandleButtonActivated");
		Button2.OnButtonActivated.AddUFunction(this, n"HandleButtonActivated");
	}

	UFUNCTION()
	private void HandleButtonActivated()
	{
		if(HasControl())
		{
			if (Button1.bActivated && Button2.bActivated)
				CrumbOpenDoor();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOpenDoor()
	{
		if (bOpened)
			return;

		bOpened = true;
		OnDoubleDoorOpened.Broadcast();
		RotateComp1.ConstrainAngleMin = -100.0;
		RotateComp2.ConstrainAngleMin = -100.0;
		Timer::ClearTimer(Button1, n"Deactivate");
		Timer::ClearTimer(Button2, n"Deactivate");
		Button1.bPermaActivated = true;
		Button2.bPermaActivated = true;

		BP_Audio_OnOpened();
	}

	/**
	 * AUDIO
	 */

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnOpened() {}
};