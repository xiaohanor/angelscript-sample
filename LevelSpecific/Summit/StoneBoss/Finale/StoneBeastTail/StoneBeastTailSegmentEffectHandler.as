struct FStoneBeastTailSegmentStartMovingUpParams
{
	UPROPERTY()
	AHazeActor TailSegment;
}

struct FStoneBeastTailSegmentStartMovingDownParams
{
	UPROPERTY()
	AHazeActor TailSegment;
}

struct FStoneBeastTailSegmentMoveUpdateParams
{
	UPROPERTY()
	AHazeActor TailSegment;
	UPROPERTY()
	float MoveSpeedAlpha;
	UPROPERTY()
	float VerticalSpeed;
	UPROPERTY()
	float VerticalSpeedDirection;
}

UCLASS(Abstract)
class UStoneBeastTailSegmentEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTailSegmentStartMovingUp(FStoneBeastTailSegmentStartMovingUpParams MovingUpParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTailSegmentMoveUpdate(FStoneBeastTailSegmentMoveUpdateParams MoveUpdateParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTailSegmentStartMovingDown(FStoneBeastTailSegmentStartMovingDownParams MovingDownParams)
	{
	}
};