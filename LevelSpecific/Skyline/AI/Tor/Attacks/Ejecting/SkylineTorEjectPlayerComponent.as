class USkylineTorEjectPlayerComponent : UActorComponent
{
	private bool bGrabbedInternal;
	private bool bEjectedInternal;
	private bool bCompletedInternal;
	AHazeActor Grabber;
	AActor CenterActor;
	UAnimSequence PlayerGrabbedAnim;

	bool GetbGrabbed() property
	{
		return bGrabbedInternal;
	}

	bool GetbEjected() property
	{
		return bEjectedInternal;
	}

	bool GetbCompleted() property
	{
		return bCompletedInternal;
	}

	void Grab(AHazeActor InGrabber)
	{
		Grabber = InGrabber;
		bGrabbedInternal = true;
		bEjectedInternal = false;
		bCompletedInternal = false;
	}

	void Eject()
	{
		bEjectedInternal = true;
		Release();
	}
	
	void Release()
	{
		bGrabbedInternal = false;
	}

	void Complete()
	{
		bCompletedInternal = true;
		bEjectedInternal = false;
	}
}