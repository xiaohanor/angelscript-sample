enum ERaftPaddleAnimationState
{
	LeftSideIdle,
	LeftSidePaddle,
	RightSideIdle,
	RightSidePaddle,
};

UCLASS(Abstract)
class UPaddleRaftPlayerComponent : UActorComponent
{
	APaddleRaft PaddleRaft;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect CollisionFF;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CollisionCameraShake;

	int NumQueuedFakePaddleStrokes = 0;
	float TimeBetweenFakePaddleStrokes = 0;
};