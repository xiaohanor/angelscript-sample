class UTundraGnatBeaverSpearEntryBehaviour : UBasicBehaviour
{
	// Control only, relevant data is replicated by movement capability
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeActorRespawnableComponent RespawnComp;
	UTundraGnatComponent GnatComp;
	UTundraGnatSettings Settings;
	ATundraBeaverSpear Spear;
	float MoveTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnatComp = UTundraGnatComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");	
		Settings = UTundraGnatSettings::GetSettings(Owner); 
	}

	UFUNCTION()
	private void OnRespawn()
	{
		GnatComp.bHasCompletedEntry = false;
		if (RespawnComp.Spawner == nullptr)
			return;
		AActor Host = RespawnComp.Spawner.AttachParentActor;
		if (Host == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (GnatComp.bHasCompletedEntry)
			return false;
		if (GnatComp.PassengerOnBeaverSpear == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (GnatComp.bHasCompletedEntry)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Spear = Cast<ATundraBeaverSpear>(GnatComp.PassengerOnBeaverSpear); 
		MoveTime = BIG_NUMBER;

		BuildSpline();
		GnatComp.ClimbDistAlongSpline = 0.0;
		GnatComp.Host = Spear.WalkingStickRef;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GnatComp.PassengerOnBeaverSpear = nullptr;
	}

	void BuildSpline()
	{
		UScenepointComponent Scenepoint = UHazeActorRespawnableComponent::Get(Owner).SpawnParameters.Scenepoint;
		FVector SpearAxis = Spear.SpearMesh.WorldRotation.UpVector;
		FVector SpearLoc = Spear.SpearMesh.WorldLocation;
		float SpearRadius = Math::ProjectPositionOnInfiniteLine(SpearLoc, SpearAxis, Scenepoint.WorldLocation).Distance(Scenepoint.WorldLocation);

		FVector SpearUp = FVector::UpVector.VectorPlaneProject(SpearAxis).GetSafeNormal();
		FVector SpearDest = Spear.RotationRoot.WorldLocation - SpearAxis * 400.0;
		SpearDest = Math::ProjectPositionOnInfiniteLine(SpearLoc, SpearAxis, SpearDest) + SpearUp * SpearRadius;

		TArray<FVector> Locs;
		TArray<FVector> Ups;

		FVector StartLoc = Scenepoint.WorldLocation;
		FVector StartUp = Scenepoint.WorldRotation.UpVector;
		Locs.Add(StartLoc);
		Ups.Add(StartUp);

		float StartAlongSpear = SpearAxis.DotProduct(StartLoc - SpearLoc);
		float DestAlongSpear = SpearAxis.DotProduct(SpearDest - SpearLoc);
		for (float Alpha = 0.25; Alpha < 0.99; Alpha += 0.25)
		{
			FVector Up = StartUp.SlerpVectorTowardsAroundAxis(SpearUp, SpearAxis, Alpha);
			Locs.Add(SpearLoc + SpearAxis * Math::Lerp(StartAlongSpear, DestAlongSpear, Alpha) + Up * SpearRadius);
			Ups.Add(Up);  	
		}

		Locs.Add(SpearDest);
		Ups.Add(SpearUp);

		GnatComp.ClimbSpline.SetPointsAndUpDirections(Locs, Ups);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Need to rebuild spline for now, when building it in spear mesh local space we would only need to do it in OnActivated
		BuildSpline();

		// Cling onto spear until it's struck the walking stick, then climb down along it.		
		if ((MoveTime == BIG_NUMBER) && (ActiveDuration > 1.0) && !Spear.bThrowSpear)
		{
			// The spear just struck home
			MoveTime = ActiveDuration + 0.5;
		}

		if (ActiveDuration > MoveTime)
		{
			DestinationComp.MoveTowardsIgnorePathfinding(GnatComp.ClimbSpline.GetLocation(1.0), Settings.BeaverSpearClimbMoveSpeed);
			if (GnatComp.IsAtEndOfSpline(20.0))
				GnatComp.bHasCompletedEntry = true;

	#if EDITOR
			//Owner.bHazeEditorOnlyDebugBool = true;
			if (Owner.bHazeEditorOnlyDebugBool)
			{
				int nPoints = 100;
				TArray<FVector> SplineLocs;
				GnatComp.ClimbSpline.GetLocations(SplineLocs, nPoints);
				TArray<FRotator> SplineRots;
				GnatComp.ClimbSpline.GetRotations(SplineRots, nPoints);
				for (int i = 1; i < SplineLocs.Num(); i++)
				{
					FVector From = SplineLocs[i-1];
					FVector To = SplineLocs[i]; 
					Debug::DrawDebugLine(From, To, FLinearColor::Purple);
					if ((i % 5) == 1)
						Debug::DrawDebugLine(From, From + SplineRots[i - 1].UpVector * 30.0, FLinearColor::DPink);
				}
			}
	#endif
		}
	}
}
