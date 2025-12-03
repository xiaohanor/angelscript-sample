class ASanctuaryHydraSplineRunBreathPrototype : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadTargetRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;
	FTransform HeadBaseTransform;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent UpperJawRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent LowerJawRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UGodrayComponent GodRayComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UGodrayComponent TelegraphGodRayComp;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UNiagaraComponent WaterSplashComp;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UStaticMeshComponent BreathMeshComp;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UNiagaraComponent BreathVFX;

	UPROPERTY(EditAnywhere)
	float DistanceToWaterLevel = 1000.0;

	UPROPERTY(EditAnywhere)
	bool bDetachGodray = false;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossMedallionHydra Hydra;

	UPROPERTY(EditAnywhere)
	float HeadAppearDuration = 1.0;
	UPROPERTY(EditAnywhere)
	float AnticipationDuration = 2.0;
	UPROPERTY(EditAnywhere)
	float StartBreathDuration = 0.5;
	UPROPERTY(EditAnywhere)
	float AttackDuration = 2.0;
	UPROPERTY(EditAnywhere)
	float StopBreathDuration = 1.0;
	UPROPERTY(EditAnywhere)
	float GodRayOpacity = 0.5;
	UPROPERTY(EditAnywhere)
	bool bFlyingAttack = false;

	float BreathLength = 30.0;

	ASanctuaryHydraSidescrollerBreathManager SidescrollerManager;
	ASanctuaryBossMedallionHydraReferences Refs;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DevToggleHydraPrototype::SplineRunBreath.MakeVisible();
		AddActorDisable(this);

		HeadBaseTransform = HeadRoot.RelativeTransform;

		if (DevToggleHydraPrototype::SplineRunBreath.IsEnabled())
		{
			auto KineticMovingActor = Cast<AKineticMovingActor>(AttachmentRootActor);
			if (KineticMovingActor != nullptr)
			{
				KineticMovingActor.OnReachedBackward.AddUFunction(this, n"Activate");
				KineticMovingActor.OnReachedForward.AddUFunction(this, n"StopAttacking");
			}
		}

		if (DevToggleHydraPrototype::SideScrollerVerticalBreath.IsEnabled())
		{
			SidescrollerManager = Cast<ASanctuaryHydraSidescrollerBreathManager>(AttachParentActor);
			if (SidescrollerManager != nullptr)
				SidescrollerManager.SetActive.AddUFunction(this, n"HandleSetActive");
		}

		if (bDetachGodray)
			GodRayComp.DetachFromParent(true);


		DevToggleHydraPrototype::SplineRunBreath.BindOnChanged(this, n"HandleDevToggledSplineRun");
		DevToggleHydraPrototype::SideScrollerVerticalBreath.BindOnChanged(this, n"HandleDevToggledSidescroller");

		BreathLength = BreathMeshComp.RelativeScale3D.Y;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		WaterSplashComp.SetWorldLocation(GetWaterSplashLocation());
	}

	UFUNCTION()
	private void HandleSetActive(bool bActive)
	{
		if (bActive)
			Activate();
		else
			StopAttacking();
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);

		if (Refs == nullptr)
			CacheRefs();

		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, EMedallionHydraMovePivotPriority::High, 1.0);
		Hydra.OneshotAnimation(EFeatureTagMedallionHydra::Roar);
	
		HeadRoot.SetRelativeTransform(HeadBaseTransform);

		LowerJawRoot.SetRelativeRotation(FRotator::ZeroRotator);
		UpperJawRoot.SetRelativeRotation(FRotator::ZeroRotator);
		BreathMeshComp.SetRelativeScale3D(FVector::ZeroVector);

		BreathVFX.Deactivate();
		WaterSplashComp.Deactivate();
		
		GodRayComp.SetGodrayOpacity(0.0);

		if (bFlyingAttack)
			PlaceTelegraph();

		if (SidescrollerManager != nullptr)
			SidescrollerManager.AccSplineProgress.SnapTo(SidescrollerManager.ProgressAlongSpline);
		
		QueueComp.Empty();
		QueueComp.Duration(HeadAppearDuration, this, n"HeadAppearUpdate");
		QueueComp.Duration(AnticipationDuration, this, n"AnticipationUpdate");
		QueueComp.Event(this, n"ActivateBreath");
		QueueComp.Duration(StartBreathDuration, this, n"StartBreathUpdate");
		QueueComp.Duration(AttackDuration, this, n"AttackUpdate");
		QueueComp.Event(this, n"StopAttacking");
	}

	private void PlaceTelegraph()
	{
		FVector PlaneFV = Refs.MedallionBossPlane2D.ActorForwardVector;
		FVector PlaneLoc = Refs.MedallionBossPlane2D.ActorLocation;

		FVector Point1 = Math::LinePlaneIntersection(HeadRoot.WorldLocation, 
													HeadRoot.WorldLocation + HeadRoot.WorldRotation.ForwardVector * 1000000.0, 
													PlaneLoc, 
													PlaneFV);

		FVector Point2 = Math::LinePlaneIntersection(HeadTargetRoot.WorldLocation, 
													HeadTargetRoot.WorldLocation + HeadTargetRoot.WorldRotation.ForwardVector * 1000000.0, 
													PlaneLoc, 
													PlaneFV);

		FVector AverageLocation = (Point1 + Point2) * 0.5;

		FVector TelegraphLocation = Math::ClosestPointOnLine(Point1, Point2, PlaneLoc);
		FVector TelegraphForward = (Point1 - Point2).GetSafeNormal();
		FRotator TelegraphRotation = FRotator::MakeFromXZ(PlaneFV, TelegraphForward);

		TelegraphRoot.SetWorldLocationAndRotation(TelegraphLocation, TelegraphRotation);
		TelegraphRoot.AttachToComponent(Refs.MedallionBossPlane2D.AttachmentRoot, AttachmentRule = EAttachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void StopAttacking()
	{
		QueueComp.Event(this, n"DeactivateBreath");
		QueueComp.Duration(StopBreathDuration, this, n"StopBreathUpdate");
		QueueComp.ReverseDuration(HeadAppearDuration, this, n"HeadAppearUpdate");
		QueueComp.Event(this, n"Deactivate");
	}

	UFUNCTION()
	private void Deactivate()
	{
		Hydra.MoveHeadPivotComp.Clear(this);
		AddActorDisable(this);
	}

	UFUNCTION()
	private void HeadAppearUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseOut(0.0, 1.0, Alpha, 2.0);
		HeadRoot.SetRelativeLocation(FVector::ForwardVector * Math::Lerp(-2400.0, 0.0, CurrentValue));
	}

	UFUNCTION()
	private void AnticipationUpdate(float Alpha)
	{
		float CurrentValue = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);
		
		LowerJawRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, -30.0, CurrentValue), 0.0, 0.0));
		UpperJawRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, 15.0, CurrentValue), 0.0, 0.0));

		GodRayComp.SetGodrayOpacity(Alpha * GodRayOpacity);
	}

	UFUNCTION()
	private void ActivateBreath()
	{
		BreathVFX.Activate();
		WaterSplashComp.Activate();
	}

	UFUNCTION()
	private void StartBreathUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseOut(0.0, 1.0, Alpha, 2.5);
		BreathMeshComp.SetRelativeScale3D(FVector(CurrentValue, BreathLength, CurrentValue));
		TelegraphGodRayComp.SetGodrayOpacity(Alpha * GodRayOpacity);
	}

	UFUNCTION()
	private void AttackUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseOut(0.0, 1.0, Alpha, 1.0);

		FTransform Transform;
		Transform.Location = Math::Lerp(HeadBaseTransform.Location, HeadTargetRoot.RelativeLocation, CurrentValue);
		Transform.Rotation = Math::LerpShortestPath(HeadBaseTransform.Rotation.Rotator(), HeadTargetRoot.RelativeRotation, CurrentValue).Quaternion();
		
		HeadRoot.SetRelativeTransform(Transform);
		TelegraphGodRayComp.SetGodrayOpacity(Math::Lerp(GodRayOpacity, 0.0, Alpha));

		if (bFlyingAttack)
		{

		}
	}

	UFUNCTION()
	private void DeactivateBreath()
	{
		BreathVFX.Deactivate();
		WaterSplashComp.Deactivate();
		GodRayComp.SetGodrayOpacity(0.0);
	}

	UFUNCTION()
	private void StopBreathUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseIn(1.0, 0.0, Alpha, 2.5);
		BreathMeshComp.SetRelativeScale3D(FVector(CurrentValue, BreathLength, CurrentValue));
		LowerJawRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, -30.0, CurrentValue), 0.0, 0.0));
		UpperJawRoot.SetRelativeRotation(FRotator(Math::Lerp(0.0, 15.0, CurrentValue), 0.0, 0.0));
	}

	private FVector GetWaterSplashLocation()
	{
		return Math::LinePlaneIntersection(ActorLocation, ActorLocation + ActorForwardVector * 200000.0, ActorLocation - FVector::UpVector * DistanceToWaterLevel, FVector::UpVector);
	}

	UFUNCTION()
	private void HandleDevToggledSplineRun(bool bNewState)
	{
		if (bNewState)
		{
			auto KineticMovingActor = Cast<AKineticMovingActor>(AttachmentRootActor);
			if (KineticMovingActor != nullptr)
			{
				KineticMovingActor.OnReachedBackward.AddUFunction(this, n"Activate");
				KineticMovingActor.OnReachedForward.AddUFunction(this, n"StopAttacking");
			}
		}
		else
		{
			auto KineticMovingActor = Cast<AKineticMovingActor>(AttachmentRootActor);
			if (KineticMovingActor != nullptr)
			{
				KineticMovingActor.OnReachedBackward.UnbindObject(this);
				KineticMovingActor.OnReachedForward.UnbindObject(this);
			}

			Deactivate();
		}
	}

	UFUNCTION()
	private void HandleDevToggledSidescroller(bool bNewState)
	{
		if (bNewState)
		{
			SidescrollerManager = Cast<ASanctuaryHydraSidescrollerBreathManager>(AttachParentActor);
			if (SidescrollerManager != nullptr)
				SidescrollerManager.SetActive.AddUFunction(this, n"HandleSetActive");
		}
		else
		{
			if (SidescrollerManager != nullptr)
				SidescrollerManager.SetActive.UnbindObject(this);

			Deactivate();
		}
	}
	private void CacheRefs()
	{
		TListedActors<ASanctuaryBossMedallionHydraReferences> ListedRefs;
		Refs = ListedRefs.Single;
	}
};