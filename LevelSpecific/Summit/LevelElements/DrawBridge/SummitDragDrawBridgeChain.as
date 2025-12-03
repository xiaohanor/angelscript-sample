class ASummitDragDrawBridgeChain : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 45000.0;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ASummitDragDrawBridgeChainLink> LinkClass;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitDragDrawBridgePulley Pulley;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ChainMoveTotal = 8000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LinkScale = 1.0;

	UPROPERTY(NotVisible, BlueprintHidden)
	TArray<ASummitDragDrawBridgeChainLink> Links;

	float PreviousPulleyAlpha;
	float SpawnRemainingChainDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Pulley != nullptr) 
			PreviousPulleyAlpha = Pulley.PulleyAlpha;

		if(Links.Num() == 0)
			InitializeLinks();

		for(auto Link : Links)
		{
			auto SplinePos = Spline.GetClosestSplinePositionToWorldLocation(Link.ActorLocation);
			Link.SplinePos = SplinePos;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Pulley == nullptr)
			return;

		for(auto Player : Game::Players)
		{
			if(!Pulley.IsInteracting[Player])
				return;
		}

		float PulleyAlpha = Pulley.PulleyAlpha;
		float DeltaAlpha = PulleyAlpha - PreviousPulleyAlpha;

		if(DeltaAlpha == 0)
			return;

		TEMPORAL_LOG(this)
			.Value("Pulley Alpha", PulleyAlpha)
			.Value("Previous Pulley Alpha", PreviousPulleyAlpha)
			.Value("Delta Alpha", DeltaAlpha)
			.Value("Move this frame", DeltaAlpha * ChainMoveTotal)
		;

		for(auto Link : Links)
		{
			float RemainingSplineDistance = 0.0;
			bool bReachedEnd = !Link.SplinePos.Move(-DeltaAlpha * ChainMoveTotal, RemainingSplineDistance);
			if(bReachedEnd)
				Link.SplinePos = Spline.GetSplinePositionAtSplineDistance(RemainingSplineDistance + SpawnRemainingChainDistance * 0.5);
			Link.ActorLocation = Link.SplinePos.WorldLocation;

			TEMPORAL_LOG(this)
				.Sphere(f"{Link}: SplinePos", Link.SplinePos.WorldLocation, 50, FLinearColor::LucBlue, 5)
			;
		}

		PreviousPulleyAlpha = Pulley.PulleyAlpha;
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void CreateLinks()
	{
		InitializeLinks();
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void RemoveAllLinks()
	{
		if(Links.IsEmpty())
			return;

		for(int i = Links.Num() - 1; i >= 0; i--)
		{
			auto Link = Links[i];
			Links.RemoveAt(i);
			Link.DestroyActor();
		}
	}

	void InitializeLinks()
	{
		RemoveAllLinks();

		float LinkLength = LinkClass.DefaultObject.LinkLength * LinkScale;
		FSplinePosition SplinePos = Spline.GetSplinePositionAtSplineDistance(0);
		
		SplinePos.Move(LinkLength * 0.5);
		auto InitialLink = CreateLink(SplinePos);
		Links.Add(InitialLink);
		for(float Distance = SplinePos.CurrentSplineDistance; Distance < Spline.SplineLength; Distance += LinkLength)
		{
			float RemainingSplineDistance = Spline.SplineLength - SplinePos.CurrentSplineDistance;
			if(RemainingSplineDistance < LinkLength)
			{
				SpawnRemainingChainDistance = RemainingSplineDistance;
				break;
			}
			SplinePos.Move(LinkLength);
			auto NewLink = CreateLink(SplinePos);
			Links.Add(NewLink);
		}
	}

	private ASummitDragDrawBridgeChainLink CreateLink(FSplinePosition SplinePos)
	{
		auto NewLink = SpawnActor(LinkClass, SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator());
		NewLink.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
		FVector NewScale = NewLink.ActorScale3D * LinkScale;
		NewLink.SetActorScale3D(NewScale);
		DisableComp.AutoDisableLinkedActors.Add(NewLink);
		return NewLink;
	}
};