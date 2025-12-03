enum ESummitRaftHitStaggerSide
{
	Left,
	Right,
	Front,
	Back,
}

struct FSummitRaftHitStaggerData
{
	UPROPERTY()
	ESummitRaftHitStaggerSide HitSide;
	UPROPERTY()
	bool bSmallHit;

	bool bOverriddenPreviousData;
	FVector HitNormal;
	FVector ReflectedVelocity;
	FVector ImpactPoint;
}

class USummitRaftPlayerStaggerComponent : UActorComponent
{
	access ReadOnly = private, * (readonly);
	access:ReadOnly TOptional<FSummitRaftHitStaggerData> StaggerData;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!StaggerData.IsSet())
			return;
		
		TEMPORAL_LOG(this)
			.Value("StaggerData;HitSide", StaggerData.Value.HitSide)
			.Value("StaggerData;bSmallHit", StaggerData.Value.bSmallHit)
			.Value("StaggerData;bOverriddenPreviousData", StaggerData.Value.bOverriddenPreviousData);
	}

	void ResetStaggerData()
	{
		StaggerData.Reset();
	}

	void ClearOverrideFlag()
	{
		if (StaggerData.IsSet())
			StaggerData.Value.bOverriddenPreviousData = false;
	}

	void ApplyStaggerData(FSummitRaftHitStaggerData Data)
	{
		bool bWasAlreadySet = StaggerData.IsSet();
		StaggerData = Data;
		StaggerData.Value.bOverriddenPreviousData = bWasAlreadySet;
	}
};