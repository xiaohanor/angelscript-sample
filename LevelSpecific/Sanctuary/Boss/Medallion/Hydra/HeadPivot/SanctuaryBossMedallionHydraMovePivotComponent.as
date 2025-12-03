enum EMedallionHydraMovePivotPriority
{
	Lowest,
	Low,
	Medium,
	High,
	VeryHigh,
	VeryVeryHigh
}

struct FSanctuaryBossMedallionHydraMovePivotRequest
{
	access AccessVIP = private, USanctuaryBossMedallionHydraMovePivotCapability, USanctuaryBossMedallionHydraMovePivotComponent;
	access : AccessVIP FInstigator Instigator;
	access : AccessVIP float AddedTimestamp = 0.0;
	access : AccessVIP int NumActivations = 0;

	EMedallionHydraMovePivotPriority Priority;
	USceneComponent SceneComponentToFollow;
	float BlendInDuration = 1.0;
	bool bSnapFirstTime = false;
	bool bSnapOnExit = false;

	int opCmp(const FSanctuaryBossMedallionHydraMovePivotRequest& Other) const
	{
		if (Priority < Other.Priority)
			return -1;
		else if (Priority > Other.Priority)
			return 1;
		if (AddedTimestamp < Other.AddedTimestamp)
			return 1;
		return -1;
	}
}

class USanctuaryBossMedallionHydraMovePivotComponent : UActorComponent
{
	access CapabilityAccess = private, USanctuaryBossMedallionHydraMovePivotCapability;
	access : CapabilityAccess TArray<FSanctuaryBossMedallionHydraMovePivotRequest> MovePivotRequests;
	private ASanctuaryBossMedallionHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
	}

	void ApplyHeadPivot(FInstigator Instigator, USceneComponent SceneComponentToFollow, EMedallionHydraMovePivotPriority Priority, float BlendInDuration, bool bSnapFirstTime = false, bool bSnapOnExit = false)
	{
		if (!devEnsure(!Contains(Instigator), "Instigator " + Instigator + " is already applying head pivot!"))
			return;

		FSanctuaryBossMedallionHydraMovePivotRequest Request;
		Request.Instigator = Instigator;
		Request.Priority = Priority;
		Request.SceneComponentToFollow = SceneComponentToFollow;
		Request.BlendInDuration = BlendInDuration;
		Request.AddedTimestamp = Time::GameTimeSeconds;
		Request.bSnapFirstTime = bSnapFirstTime;
		Request.bSnapOnExit = bSnapOnExit;
		MovePivotRequests.Add(Request);

		MovePivotRequests.Sort(true);
	}

	void Clear(FInstigator Instigator)
	{
		int IndexToRemove = -1;
		for (int iRequest = 0; iRequest < MovePivotRequests.Num(); ++iRequest)
		{
			FSanctuaryBossMedallionHydraMovePivotRequest Request = MovePivotRequests[iRequest];
			if (Request.Instigator == Instigator)
				IndexToRemove = iRequest;
		}

		if (IndexToRemove >= 0)
			MovePivotRequests.RemoveAt(IndexToRemove);
	}

	private FSanctuaryBossMedallionHydraMovePivotRequest GetRequest(FInstigator Instigator) const
	{
		for (auto Request : MovePivotRequests)
		{
			if (Instigator == Request.Instigator)
				return Request;
		}
		return FSanctuaryBossMedallionHydraMovePivotRequest();
	}

	bool Contains(FInstigator Instigator) const
	{
		return GetRequest(Instigator).Instigator != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		for (int iRequest = 0; iRequest < MovePivotRequests.Num(); iRequest++)
		{
			FString Category = "Num " + iRequest + " ";
			FSanctuaryBossMedallionHydraMovePivotRequest Request = MovePivotRequests[iRequest];
			FString HeadReqCat = "Head Requesters";
			TEMPORAL_LOG(Hydra, HeadReqCat).Value(Category + "Instigator", Request.Instigator);
			TEMPORAL_LOG(Hydra, HeadReqCat).Value(Category + "AddedTimestamp", Request.AddedTimestamp);
			TEMPORAL_LOG(Hydra, HeadReqCat).Value(Category + "Priority", Request.Priority);
			TEMPORAL_LOG(Hydra, HeadReqCat).Value(Category + "GetName", Request.SceneComponentToFollow.Owner.GetName());
			TEMPORAL_LOG(Hydra, HeadReqCat).Value(Category + "BlendInDuration", Request.BlendInDuration);
			TEMPORAL_LOG(Hydra, HeadReqCat).Value(Category + "SnapFirstTime", Request.bSnapFirstTime);
			TEMPORAL_LOG(Hydra, HeadReqCat).Value(Category + "NumActivations", Request.NumActivations);
		}
#endif
	}
};