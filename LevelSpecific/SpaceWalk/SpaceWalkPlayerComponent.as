class USpaceWalkPlayerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<ASpaceWalkHookActor> HookClass;
	UPROPERTY()
	TSubclassOf<UTargetableWidget> HookPointWidget;
	UPROPERTY(EditAnywhere)
	TSubclassOf<ASpaceWalkDebrisKillActor> DebrisKillActorClass;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect HookAttachFF;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect HookLetGoFF;

	ASpaceWalkHookActor Hook;

	FName GetHookLaunchSocket() const
	{
		if (bLaunchedFromLeftHand)
			return n"LeftAttach";
		else
			return n"RightAttach";
	}

	TInstigated<FVector> AdjustAcceleration;

	USpaceWalkHookPointComponent TargetHookPoint;
	bool bHasHookLaunched = false;
	bool bHasHookAttached = false;
	bool bHookForceRelease = false;
	bool bIsHookReturning = false;
	bool bLaunchedFromLeftHand = false;
	bool bIsThrusting = false;
	float HookLaunchYaw = 0.0;
};