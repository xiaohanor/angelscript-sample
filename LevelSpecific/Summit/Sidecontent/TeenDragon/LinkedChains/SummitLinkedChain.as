class ASummitLinkedChain : ASplineActor
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<ASummitChainLink> ChainLinkClass;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<USummitChainLinkSpeedAudioComponent> AudioCompClass;
	
	UPROPERTY(DefaultComponent, ShowOnActor)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 35000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bIsTopDownChain = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float TopDownCullMaxDistance = 50000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float NonTopDownCullMaxDistance = 45000.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Attachment")
	bool bFirstLinkIsLocked = false;

	UPROPERTY(EditAnywhere, Category = "Settings|Attachment", Meta = (EditCondition = "bFirstLinkIsLocked", EditConditionHides))
	bool bFirstLinkRotationLock = false;

	UPROPERTY(EditAnywhere, Category = "Settings|Attachment", Meta = (EditCondition = "bFirstLinkIsLocked", EditConditionHides))
	AActor FirstLinkAttachActor;

	UPROPERTY(EditAnywhere, Category = "Settings|Attachment", Meta = (EditCondition = "bFirstLinkIsLocked && FirstLinkAttachActor != nullptr", EditConditionHides))
	FName FirstLinkAttachComponentName = NAME_None;

	UPROPERTY(EditAnywhere, Category = "Settings|Attachment")
	bool bLastLinkIsLocked = false;

	UPROPERTY(EditAnywhere, Category = "Settings|Attachment", Meta = (EditCondition = "bLastLinkIsLocked", EditConditionHides))
	bool bLastLinkRotationLock = false;

	UPROPERTY(EditAnywhere, Category = "Settings|Attachment", Meta = (EditCondition = "bLastLinkIsLocked", EditConditionHides))
	AActor LastLinkAttachActor;

	UPROPERTY(EditAnywhere, Category = "Settings|Attachment", Meta = (EditCondition = "bLastLinkIsLocked && LastLinkAttachActor != nullptr", EditConditionHides))
	FName LastLinkAttachComponentName = NAME_None;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LinkGravity = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bUseStartRight = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int ConstraintSolverIterationsPerFrame = 100;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LinkScale = 1.0;

	/** How much of the link distance gets added as an additional spacing */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float LinkDistanceMultiplier = 1.02; 

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartSleeping = false;

	UPROPERTY(EditAnywhere, Category = "Settings|Disabling")
	bool bUpperDisablePlane = true;

	UPROPERTY(EditAnywhere, Category = "Settings|Disabling", Meta = (EditCondition = "bUpperDisablePlane", EditConditionHides))
	float UpperDisablePlaneOffset = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Disabling")
	bool bLowerDisablePlane = true;

	UPROPERTY(EditAnywhere, Category = "Settings|Disabling", Meta = (EditCondition = "bLowerDisablePlane", EditConditionHides))
	float LowerDisablePlaneOffset = 10000.0;

	private float UpperDisablePlaneHeightRelativeToActor = 0.0;
	private float LowerDisablePlaneHeightRelativeToActor = 0.0;

	UPROPERTY(NotVisible, BlueprintHidden)
	TArray<ASummitChainLink> Links;

	private USummitChainLinkSpeedAudioComponent FirstAudioComp;
	private USummitChainLinkSpeedAudioComponent LastAudioComp;

	USummitChainLinkSpeedAudioComponent GetFirstLinkedAudioComp() const
	{
		return FirstAudioComp;
	}

	USummitChainLinkSpeedAudioComponent GetLastLinkedAudioComp() const
	{
		return LastAudioComp;
	}

	bool bIsSleeping = false;

	float TimeLastWokenUp = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, true);

		for(auto Actor : AttachedActors)
		{
			auto Link = Cast<ASummitChainLink>(Actor);
			if(Link == nullptr)
				continue;
			
			if(bIsTopDownChain)
			{
				Link.MeshComp.LDMaxDrawDistance = TopDownCullMaxDistance;
				Link.MeshComp.MinDrawDistance = 0.0;
				Link.RerunConstructionScripts();
			}
			else
			{
				Link.MeshComp.LDMaxDrawDistance = NonTopDownCullMaxDistance;
				Link.MeshComp.MinDrawDistance = 0.0;
				Link.RerunConstructionScripts();
			}
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Links.Num() == 0)
			InitializeLinks();
		
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		
		for(int i = 0; i < Links.Num(); i++)
		{
			auto Link = Links[i];
			Link.StartUp = Link.ActorUpVector;
			Link.StartRight = Link.ActorRightVector;

			auto TempLogPage = TEMPORAL_LOG(this).Page(f"Link {i}");

			if(i < Links.Num() - 1)
			{
				Link.NextLink = Links[i + 1];
				Link.NextLink.OnNightQueenMetalMelted.AddUFunction(Link, n"NextLinkWasMelted");
				TempLogPage.Arrow("Next Link", Link.ActorLocation, Link.NextLink.ActorLocation, 5, 4000, FLinearColor::White);
			}
			if(i > 0)
			{
				Link.PreviousLink = Links[i - 1];
				Link.PreviousLink.OnNightQueenMetalMelted.AddUFunction(Link, n"PreviousLinkWasMelted");
				TempLogPage.Arrow("Previous Link", Link.ActorLocation, Link.PreviousLink.ActorLocation, 5, 4000, FLinearColor::Black);
			}
			Link.DesiredLocation = Link.ActorLocation;
			Link.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			Link.OnLinkMelted.AddUFunction(this, n"OnLinkMelted");
			TempLogPage
				.Sphere("Link", Link.ActorLocation, 50, FLinearColor::LucBlue, 10)
			;
			DisableComp.AutoDisableLinkedActors.Add(Link);
		}

		HandleInitialLinkLocksAndAttaches();

		UpperDisablePlaneHeightRelativeToActor = Spline.GetWorldLocationAtSplineFraction(1.0).Z + UpperDisablePlaneOffset - ActorLocation.Z;
		LowerDisablePlaneHeightRelativeToActor = Spline.GetWorldLocationAtSplineFraction(0.0).Z - LowerDisablePlaneOffset - ActorLocation.Z;

		TimeLastWokenUp = Time::GameTimeSeconds;

		if(bStartSleeping)
			CrumbStartSleeping();
	}

	private void HandleInitialLinkLocksAndAttaches()
	{
		if(bFirstLinkIsLocked)
		{
			auto FirstLink = Links[0];
			FirstLink.bIsLocked = true;
			if(bFirstLinkRotationLock)
				FirstLink.bRotationIsLocked = true;

			if(FirstLinkAttachActor != nullptr)
			{
				USceneComponent AttachComp;
				if(FirstLinkAttachComponentName != NAME_None)
					AttachComp = FirstLinkAttachActor.GetComponent(USceneComponent, FirstLinkAttachComponentName);

				if(AttachComp != nullptr)
					FirstLink.AttachToComponent(AttachComp, AttachmentRule = EAttachmentRule::KeepWorld);
				else
					FirstLink.AttachToActor(FirstLinkAttachActor, AttachmentRule = EAttachmentRule::KeepWorld);
			}

			if(!bLastLinkIsLocked)
				LastAudioComp = CreateAudioComp(Links[Links.Num() - 1]);
		}
		if(bLastLinkIsLocked)
		{
			auto LastLink = Links.Last();
			LastLink.bIsLocked = true;

			if(bLastLinkRotationLock)
				LastLink.bRotationIsLocked = true;

			if(LastLinkAttachActor != nullptr)
			{
				USceneComponent AttachComp;
				if(LastLinkAttachComponentName != NAME_None)
					AttachComp = LastLinkAttachActor.GetComponent(USceneComponent, LastLinkAttachComponentName);

				if(AttachComp != nullptr)
					LastLink.AttachToComponent(AttachComp, AttachmentRule = EAttachmentRule::KeepWorld);
				else
					LastLink.AttachToActor(LastLinkAttachActor, AttachmentRule = EAttachmentRule::KeepWorld);
			}

			if(!bFirstLinkIsLocked)
				FirstAudioComp = CreateAudioComp(Links[0]);
		}
	}

	private int LinksSpawned = 0;
	private ASummitChainLink CreateLink(FSplinePosition SplinePos, bool bFromEditorFunction = false)
	{
		auto NewLink = SpawnActor(ChainLinkClass, SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator(), bDeferredSpawn = true);
		if(!bFromEditorFunction)
			NewLink.MakeNetworked(this, LinksSpawned);
		if(bFromEditorFunction)
			NewLink.AttachToComponent(Spline, AttachmentRule = EAttachmentRule::KeepWorld);
		LinksSpawned++;
		FinishSpawningActor(NewLink);
		FVector NewScale = NewLink.ActorScale3D * LinkScale;
		NewLink.SetActorScale3D(NewScale);
		return NewLink;
	}

	UFUNCTION()
	private void OnLinkMelted(ASummitChainLink Link)
	{
		FSummitLinkedChainOnLinkMeltedParams Params;
		Params.LocationOfLink = Link.ActorLocation;
		int LinksFalling = 0;

		auto SelectedLink = Link;
		int LinksInFront = 0;
		bool bLastLinkFromSegmentLocked = true;
		while(true)
		{
			if(SelectedLink.NextLink == nullptr)
			{
				bLastLinkFromSegmentLocked = false;
				break;
			}

			LinksInFront++;

			if(SelectedLink.NextLink.bIsLocked)
				break;

			SelectedLink = SelectedLink.NextLink;
		}
		if(!bLastLinkFromSegmentLocked)
			LinksFalling += LinksInFront;

		SelectedLink = Link;
		int LinksBehind = 0;
		bool bFirstLinkFromSegmentLocked = true;
		while(true)
		{
			if(SelectedLink.PreviousLink == nullptr)
			{
				bFirstLinkFromSegmentLocked = false;
				break;
			}

			LinksBehind++;
			if(SelectedLink.PreviousLink.bIsLocked)
				break;
			SelectedLink = SelectedLink.PreviousLink;
		}

		if(!bFirstLinkFromSegmentLocked)
			LinksFalling += LinksBehind;
		
		Params.NumberOfLinksFalling = LinksFalling;
		
		/* Was connected both ways, didn't have any components before
		* Two new ends of the chain has been created */
		if(bFirstLinkFromSegmentLocked
		&& bLastLinkFromSegmentLocked)
		{
			FirstAudioComp = CreateAudioComp(Link.NextLink);
			LastAudioComp = CreateAudioComp(Link.PreviousLink);
		}
		// This is the attachment link, the rest should fall
		else if(Link.bIsLocked)
		{
			// Has an AudioComp, probably has nothing under it
			if(Link.AudioComp != nullptr)
				Link.AudioComp.DestroyAudioComp();

			// Link is connected forwards, destroying audio comp at end
			if(Link.NextLink != nullptr
			&& LastAudioComp != nullptr)
				LastAudioComp.DestroyAudioComp();
			// Link is connected backwards, destroying audio comp at beginning
			if(Link.PreviousLink != nullptr
			&& FirstAudioComp != nullptr)
				FirstAudioComp.DestroyAudioComp();
		}
		// Is only connected forwards, moving audio comp to next step
		else if(bLastLinkFromSegmentLocked
		&& FirstAudioComp != nullptr)
			FirstAudioComp.AttachToLink(Link.NextLink);
		// Is only connected backwards, moving audio comp to previous step
		else if(bFirstLinkFromSegmentLocked
		&& LastAudioComp != nullptr)
			LastAudioComp.AttachToLink(Link.PreviousLink);

		USummitLinkedChainEventHandler::Trigger_OnLinkMelted(this, Params);
		
		if(HasControl())
			CrumbWakeUp();
	}

	private USummitChainLinkSpeedAudioComponent CreateAudioComp(ASummitChainLink LinkToAttachTo)
	{
		auto AudioComp = CreateComponent(AudioCompClass);
		AudioComp.AttachToLink(LinkToAttachTo);
		return AudioComp;
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void CreateLinks()
	{
		InitializeLinks(true);
	}

	void InitializeLinks(bool bIsInEditor = false)
	{
		RemoveAllLinks();

		float LinkLength = ChainLinkClass.DefaultObject.LinkLength * LinkScale * LinkDistanceMultiplier;
		FSplinePosition SplinePos = Spline.GetSplinePositionAtSplineDistance(0);
		
		SplinePos.Move(LinkLength * 0.5);
		auto InitialLink = CreateLink(SplinePos, bIsInEditor);
		Links.Add(InitialLink);
		for(float Distance = SplinePos.CurrentSplineDistance; Distance < Spline.SplineLength; Distance += LinkLength)
		{
			float RemainingSplineDistance = Spline.SplineLength - SplinePos.CurrentSplineDistance;
			if(RemainingSplineDistance < LinkLength)
				break;
			SplinePos.Move(LinkLength);
			auto NewLink = CreateLink(SplinePos, bIsInEditor);
			if(Links.Num() % 2 == 1)
				NewLink.MeshComp.AddLocalRotation(FRotator(0.0, 0.0, 90));
			Links.Add(NewLink);
		}
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

	UFUNCTION(CallInEditor, Category = "Setup")
	void ToggleAutoAimOnLinks(bool bToggleOn)
	{
		for(auto Link : Links)
		{
			Link.AutoAimComp.bIsAutoAimEnabled = bToggleOn;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsSleeping)
			return;

		bool bAllLinksAreStill = true;
		bool bAllLinksAreDisabled = true;
		for(int i = 0; i < Links.Num(); i++)
		{
			auto Link = Links[i];

			DisableIfOutsideOfPlanes(Link);

			if(!IsLinkValid(Link))
				continue;

			FVector Velocity = AddVelocityBasedOnPreviousFrame(Link, DeltaSeconds);
			if(!Velocity.IsNearlyZero(1))
				bAllLinksAreStill = false;

			if(!Link.IsActorDisabledBy(this))
				bAllLinksAreDisabled = false;

			if(Link.bIsLocked)
				continue;

			AddGravity(Link, DeltaSeconds);
		}

		if(HasControl()
		&& bAllLinksAreStill
		&& Time::GetGameTimeSince(TimeLastWokenUp) > 1.0)
			CrumbStartSleeping();

		if(bAllLinksAreDisabled)
			AddActorDisable(this);

		for(int j = 0; j < ConstraintSolverIterationsPerFrame; j++)
		{
			for(int i = 0; i < Links.Num(); i++)
			{
				auto Link = Links[i];

				if(!IsLinkValid(Link))
					continue;
				
				auto NextLink = Link.NextLink;
				if(NextLink != nullptr)
					ConstrainLinksBasedOnDistance(Link, NextLink);
				auto PreviousLink = Link.PreviousLink;
				if(PreviousLink != nullptr)
					ConstrainLinksBasedOnDistance(Link, PreviousLink);
			}
		}

		for(auto Link : Links)
		{
			if(Link.bRotationIsLocked)
				continue;

			FVector DeltaToLink;
			auto NextLink = Link.NextLink;
			auto PreviousLink = Link.PreviousLink;
			if(NextLink != nullptr)
				DeltaToLink = Link.DesiredLocation - NextLink.DesiredLocation;
			else if(PreviousLink != nullptr)
				DeltaToLink = PreviousLink.DesiredLocation - Link.DesiredLocation;
			else
			{
				Link.SetActorLocation(Link.DesiredLocation);
				continue;
			}

			FVector Forward = DeltaToLink.GetSafeNormal();
			FQuat Rotation;
			if(bUseStartRight)
			{
				FVector Right = Link.StartRight;
				Rotation = FQuat::MakeFromYX(Right, Forward);
			}
			else
			{
				FVector Up = Link.StartUp;
				Rotation = FQuat::MakeFromZX(Up, Forward);
			}
			Link.SetActorLocationAndRotation(Link.DesiredLocation, Rotation);
		}
	}

	private FVector AddVelocityBasedOnPreviousFrame(ASummitChainLink Link, float DeltaTime)
	{
		FVector Temp = Link.ActorLocation;
		FVector Velocity = (Link.ActorLocation - Link.PreviousLocation) / DeltaTime;
		Link.DesiredLocation = Link.ActorLocation + Velocity * DeltaTime;
		Link.PreviousLocation = Temp;

		return Velocity;
	}

	private void AddGravity(ASummitChainLink Link, float DeltaTime)
	{
		Link.DesiredLocation += FVector::DownVector * LinkGravity * DeltaTime;
	}

	private void ConstrainLinksBasedOnDistance(ASummitChainLink Link, ASummitChainLink OtherLink)
	{
		FVector DeltaToNextLink = Link.DesiredLocation - OtherLink.DesiredLocation;
		float DistToNextLinkSqrd = DeltaToNextLink.SizeSquared();
		if(DistToNextLinkSqrd > Math::Square(Link.LinkLength * Link.ActorScale3D.X))
		{
			DeltaToNextLink = DeltaToNextLink.GetClampedToMaxSize(Link.LinkLength * Link.ActorScale3D.X);
			FVector Offset = (Link.DesiredLocation - OtherLink.DesiredLocation) - DeltaToNextLink;
			if(!OtherLink.bIsLocked)
				OtherLink.DesiredLocation += Offset * 0.5;
			if(!Link.bIsLocked)
				Link.DesiredLocation -= Offset * 0.5;
		}
	}

	private bool IsLinkValid(ASummitChainLink Link)
	{
		if(Link.bIsMelted)
			return false;

		return true;
	}

	private void DisableIfOutsideOfPlanes(ASummitChainLink Link)
	{
		if(bUpperDisablePlane)
		{
			if(Link.ActorLocation.Z > ActorLocation.Z + UpperDisablePlaneHeightRelativeToActor)
				Link.AddActorDisable(this);
		}
		if(bLowerDisablePlane)
		{
			if(Link.ActorLocation.Z < ActorLocation.Z + LowerDisablePlaneHeightRelativeToActor)
				Link.AddActorDisable(this);
		}		
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartSleeping()
	{
		bIsSleeping = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbWakeUp()
	{
		bIsSleeping = false;
		TimeLastWokenUp = Time::GameTimeSeconds;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		const FVector EndOfSplineLocation = Spline.GetWorldLocationAtSplineFraction(1.0);
		const FVector StartOfSplineLocation = Spline.GetWorldLocationAtSplineFraction(0.0);

		float DiskRadius = 1000.0;
		if(bUpperDisablePlane)
		{
			FVector PlaneLocation = EndOfSplineLocation + FVector::UpVector * UpperDisablePlaneOffset;
			FLinearColor Color = FLinearColor::Purple;
			Color.A = 0.7;
			Debug::DrawDebugSolidDisk(PlaneLocation, FVector::UpVector, DiskRadius, Color);
			Debug::DrawDebugString(PlaneLocation, "Upper Disable Plane", FLinearColor::Purple);
		}
		if(bLowerDisablePlane)
		{
			FVector PlaneLocation = StartOfSplineLocation - FVector::UpVector * LowerDisablePlaneOffset;
			FLinearColor Color = FLinearColor::Green;
			Color.A = 0.7;
			Debug::DrawDebugSolidDisk(PlaneLocation, FVector::UpVector, DiskRadius, Color);
			Debug::DrawDebugString(PlaneLocation, "Lower Disable Plane", FLinearColor::Green);
		}
	}
#endif
};