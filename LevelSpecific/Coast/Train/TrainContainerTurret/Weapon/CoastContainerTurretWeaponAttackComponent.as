class UCoastContainerTurretWeaponAttackComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> WallImpactCameraShake;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> PlayerImpactCameraShake;
	UPROPERTY()
	UForceFeedbackEffect WallImpactForceFeedback;
	UPROPERTY()
	UForceFeedbackEffect PlayerImpactForceFeedback;
	UPROPERTY()
	TSubclassOf<UHazeUserWidget> PlayerImpactWidget;
}