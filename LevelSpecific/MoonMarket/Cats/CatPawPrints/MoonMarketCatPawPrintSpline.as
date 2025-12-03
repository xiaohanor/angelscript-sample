class AMoonMarketCatPawPrintSpline : ASplineActor
{
	// #if EDITOR
	// 	UPROPERTY(DefaultComponent, Attach = Root)
	// 	UEditorBillboardComponent Visual;
	// 	default Visual.SetWorldScale3D(FVector(4));
	// 	default Visual.SpriteName = "S_Pawn";
	// #endif

	// UPROPERTY(EditInstanceOnly)
	// ASplineActor SplineActor;
	// UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent CatProgressComp;

	UPROPERTY(EditInstanceOnly)
	AActor CatActor;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ACatPawPrint> CatPawClass;
	TArray<ACatPawPrint> CatPawPrints;

	UPROPERTY(EditAnywhere)
	AMoonMarketCat DedicatedCat;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	float StepDistance = 50.0;
	float OffsetRightDistance = 10.0;
	bool bCatFinishedMoving;
	bool bCatCollected;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DedicatedCat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");

		float CurrentDistance = 0.0;
		bool bIsRightSide = false;

		while (CurrentDistance < Spline.SplineLength)
		{
			FVector Location = Spline.GetWorldLocationAtSplineDistance(CurrentDistance);
			FRotator Rotation = Spline.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator();

			float RandomRight = Math::RandRange(0.0, 5.5);

			if (bIsRightSide)
				Location += Rotation.RightVector * (OffsetRightDistance + RandomRight);
			else	
				Location -= Rotation.RightVector * (OffsetRightDistance + RandomRight);

			ACatPawPrint Paw = Cast<ACatPawPrint>(SpawnActor(CatPawClass, Location, Rotation, bDeferredSpawn = true));
			Paw.AlphaAlongSpline = GetSplineAlpha(CurrentDistance);
			Paw.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
			FinishSpawningActor(Paw);
			CatPawPrints.AddUnique(Paw);

			float RandomForward = Math::RandRange(0.0, 50.5);
			CurrentDistance += StepDistance + RandomForward;
			bIsRightSide = !bIsRightSide;
		}

		CatProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		bCatCollected = true;
		
		for (ACatPawPrint Paw : CatPawPrints)
		{
			Paw.SetPawVisible(false);
		}
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		bCatCollected = true;

		for (ACatPawPrint Paw : CatPawPrints)
		{
			Paw.SetPawVisible(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bCatCollected)
			return;
		
		if (!bCatFinishedMoving)
		{
			FVector Location = CatActor.ActorLocation;

			auto SkelMesh = Cast<AHazeSkeletalMeshActor>(CatActor); 
			if (SkelMesh != nullptr)
				Location = SkelMesh.Mesh.GetBoneTransform(n"Hips").Location;
			
			float Alpha = GetSplineAlpha(Spline.GetClosestSplineDistanceToWorldLocation(Location));

			if (bDebug)
				PrintToScreen(f"{Alpha}" + " For: " + this);
			int PawCount = 0;

			for (ACatPawPrint Paw : CatPawPrints)
			{
				if (Paw.AlphaAlongSpline < Alpha)
				{
					Paw.SetPawVisible(true);
					// Print("Paw Visible For: " + CatActor.Name);
					// Debug::DrawDebugSphere(Spline.GetClosestSplineWorldLocationToWorldLocation(CatActor.ActorLocation), 100, 12, FLinearColor::Green, 10.0, 10.0);
					// Print("Alpha: " + Alpha);
					PawCount++;
				}
				else
				{
					Paw.SetPawVisible(false);
				}
			}

			if (PawCount >= CatPawPrints.Num())
			{
				bCatFinishedMoving = true;
			}
		}
	}

	float GetSplineAlpha(float DistanceAlongSpline)
	{
		return Math::Saturate(DistanceAlongSpline / Spline.SplineLength);
	}

	UFUNCTION()
	void SetAllPawsVisible()
	{
		for (ACatPawPrint Paw : CatPawPrints)
		{
			Paw.SetPawVisible(true);
		}	
		bCatFinishedMoving = true;
	}
};