class USkylineTorMineComponent : UActorComponent
{
	bool bGrabbed;
	bool bControlled;
	
	AHazeActor Grabber;

	bool bHasTargetLocation;
	float MoveSpeed;
	private FVector InternalTargetLocation;

	FVector GetTargetLocation() property
	{
		return InternalTargetLocation;
	}

	void MoveTowards(FVector Location, float Speed)
	{
		InternalTargetLocation = Location;
		bHasTargetLocation = true;
		MoveSpeed = Speed;
	}
}