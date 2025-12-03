
struct FSanctuaryBossMedallionHydraMoveActorRequest
{
	access AccessVIP = private, USanctuaryBossMedallionHydraMoveActorCapability, USanctuaryBossMedallionHydraMoveActorComponent;
	access : AccessVIP FInstigator Instigator;
	access : AccessVIP float AddedTimestamp = 0.0;
	access : AccessVIP int NumActivations = 0;

	EMedallionHydraMovePivotPriority Priority;
	USceneComponent ComponentToFollow;
	float BlendInDuration = 1.0;
	bool bSnapFirstTime = false;
	bool bSnapOnExit = false;

	int opCmp(const FSanctuaryBossMedallionHydraMoveActorRequest& Other) const
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

class USanctuaryBossMedallionHydraMoveActorComponent : UActorComponent
{
	access CapabilityAccess = private, USanctuaryBossMedallionHydraMoveActorCapability;
	access : CapabilityAccess TArray<FSanctuaryBossMedallionHydraMoveActorRequest> MoveActorRequests;
	private ASanctuaryBossMedallionHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
	}

	void ApplyTransform(FInstigator Instigator, USceneComponent ComponentToFollow, EMedallionHydraMovePivotPriority Priority, float BlendInDuration, bool bSnapFirstTime = false, bool bSnapOnExit = false)
	{
		if (!devEnsure(!Contains(Instigator), "Instigator " + Instigator + " is already applying actor pivot!"))
			return;

		FSanctuaryBossMedallionHydraMoveActorRequest Request;
		Request.Instigator = Instigator;
		Request.Priority = Priority;
		Request.ComponentToFollow = ComponentToFollow;
		Request.BlendInDuration = BlendInDuration;
		Request.AddedTimestamp = Time::GameTimeSeconds;
		Request.bSnapFirstTime = bSnapFirstTime;
		Request.bSnapOnExit = bSnapOnExit;
		MoveActorRequests.Add(Request);
		MoveActorRequests.Sort(true);
	}

	void Clear(FInstigator Instigator)
	{
		int IndexToRemove = -1;
		for (int iRequest = 0; iRequest < MoveActorRequests.Num(); ++iRequest)
		{
			FSanctuaryBossMedallionHydraMoveActorRequest Request = MoveActorRequests[iRequest];
			if (Request.Instigator == Instigator)
				IndexToRemove = iRequest;
		}

		if (IndexToRemove >= 0)
			MoveActorRequests.RemoveAt(IndexToRemove);
	}

	private FSanctuaryBossMedallionHydraMoveActorRequest GetRequest(FInstigator Instigator) const
	{
		for (auto Request : MoveActorRequests)
		{
			if (Instigator == Request.Instigator)
				return Request;
		}
		return FSanctuaryBossMedallionHydraMoveActorRequest();
	}

	bool Contains(FInstigator Instigator) const
	{
		return GetRequest(Instigator).Instigator != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		for (int iRequest = 0; iRequest < MoveActorRequests.Num(); iRequest++)
		{
			FString Category = "Num " + iRequest + " ";
			FSanctuaryBossMedallionHydraMoveActorRequest Request = MoveActorRequests[iRequest];
			FString ActorReqCat = "Root Requesters";
			TEMPORAL_LOG(Hydra, ActorReqCat).Value(Category + "Instigator", Request.Instigator);
			TEMPORAL_LOG(Hydra, ActorReqCat).Value(Category + "AddedTimestamp", Request.AddedTimestamp);
			TEMPORAL_LOG(Hydra, ActorReqCat).Value(Category + "Priority", Request.Priority);
			TEMPORAL_LOG(Hydra, ActorReqCat).Value(Category + "GetName", Request.ComponentToFollow.Owner.GetName());
			TEMPORAL_LOG(Hydra, ActorReqCat).Value(Category + "BlendInDuration", Request.BlendInDuration);
			TEMPORAL_LOG(Hydra, ActorReqCat).Value(Category + "SnapFirstTime", Request.bSnapFirstTime);
			TEMPORAL_LOG(Hydra, ActorReqCat).Value(Category + "NumActivations", Request.NumActivations);
		}
#endif
	}
};