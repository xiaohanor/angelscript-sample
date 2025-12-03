class UAdultDragonChaseStrafeComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ChaseCameraShake;

	FVector ForwardDirection;
	bool bCanChaseStrafe;
	bool bShouldExitStrafe;
}