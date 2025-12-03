class UPoolRingCourseManagerEventHandler : UHazeEffectEventHandler
{
	//Triggered when a ring is overlapped, Params will contain a reference to the RingInstance
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRingActivated(FPoolRingEventParams Params)
	{
	}

	//Triggered when course times out, Params will contain an array of all Active rings that will now reset
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCourseFailed(FPoolRingEventParams Params)
	{
	}

	//Triggered when course is Completed, Params will contain an array of all Active rings, but they will currently just wait for the reset
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCourseCompleted(FPoolRingEventParams Params)
	{
	}

	//Triggered when course is Reset after being completed, Params will contain an array of all Active rings that will now reset
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCourseReset(FPoolRingEventParams Params)
	{
	}
};

struct FPoolRingEventParams
{
	//Reference to the individual ring event is for
	UPROPERTY()
	APoolRingActor RingInstance;
	
	UPROPERTY()
	//Array of all currently active rings
	TArray<APoolRingActor> ActiveRings;
}