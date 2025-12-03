class UCoastPoltroonAttackComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> PlayerImpactCameraShake;
	UPROPERTY()
	UForceFeedbackEffect PlayerImpactForceFeedback;
	UPROPERTY()
	TSubclassOf<UHazeUserWidget> PlayerImpactWidget;
}