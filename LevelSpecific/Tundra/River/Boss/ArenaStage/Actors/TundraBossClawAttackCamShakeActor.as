class ATundraBossClawAttackCamShakeActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMovableCameraShakeComponent MovableCameraShakeComponent;

	void SetClawAttackCamShakeActive(bool bActive)
	{
		if(bActive)
			MovableCameraShakeComponent.ActivateMovableCameraShake();
		else
			MovableCameraShakeComponent.DeactivateMovableCameraShake();
	}
};