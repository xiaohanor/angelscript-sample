UCLASS(Abstract)
class USplitTraversalWaterPotEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFilled() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterLanded() {}
}

class ASplitTraversalWaterPot : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsConeRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent HookYawRotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent PotYawRotateComp;
	FHazeAcceleratedRotator AccPotRot;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsWeightComponent WeightComp;

	UPROPERTY(DefaultComponent, Attach = PotYawRotateComp)
	UStaticMeshComponent PotMeshComp;

	UPROPERTY(DefaultComponent, Attach = PotYawRotateComp)
	USceneComponent PotWaterRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FallingWaterRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	FHazeTimeLike WaterFallTimeLike;

	UPROPERTY()
	FHazeTimeLike FillTimeLike;
	default FillTimeLike.UseSmoothCurveZeroToOne();

	bool bFilled = false;

	UFUNCTION(BlueprintPure)
	bool IsFilled() const
	{
		return bFilled;
	}

	UPROPERTY()
	float FallHeight = 1000.0;

	UPROPERTY()
	float MovementSpeed = 300.0;

	UPROPERTY()
	float WaterFillValue = 50;

	UHazeSplineComponent SplineComp;
	float ProgressAlongSpline = 0.0;
	float CrumbTimeOfStart = 0.0;

	ASplitTraversalFireGate FireGate;
	ASplitTraversalWaterPotSpawner Spawner;

	FHazeAcceleratedRotator AccHookRot;
	

	bool bShot = false;

	FVector StartLocation;
	FVector EndLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetActorControlSide(Game::Mio);

		WaterFallTimeLike.BindUpdate(this, n"WaterFallTimeLikeUpdate");
		WaterFallTimeLike.BindFinished(this, n"WaterFallTimeLikeFinished");
		FillTimeLike.BindUpdate(this, n"FilledTimeLikeUpdate");

		PotWaterRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SplineComp == nullptr)
			return;

		ProgressAlongSpline = MovementSpeed * (Time::GetActorControlCrumbTrailTime(Game::Zoe) - CrumbTimeOfStart);
		SetActorLocation(SplineComp.GetWorldLocationAtSplineDistance(ProgressAlongSpline));
		
		if (ProgressAlongSpline > SplineComp.SplineLength)
			DestroyActor();
		
		FVector SplineForward = SplineComp.GetWorldForwardVectorAtSplineDistance(ProgressAlongSpline);
		FRotator TargetRot = FRotator::MakeFromZX(FVector::UpVector, SplineForward);
		AccPotRot.AccelerateTo(TargetRot, 3.0, DeltaSeconds);
		AccHookRot.AccelerateTo(TargetRot, 0.2, DeltaSeconds);

		PotYawRotateComp.SetRelativeRotation(AccPotRot.Value);
		HookYawRotateComp.SetRelativeRotation(AccHookRot.Value);
	}

	UFUNCTION(CrumbFunction)
	void CrumbFilled(FVector ImpulseLocation)
	{
		if (bFilled)
			return;

		USplitTraversalWaterPotEventHandler::Trigger_OnFilled(this);		
		RotateComp.ApplyImpulse(ImpulseLocation, FVector::DownVector * 500.0);

		bFilled = true;
		FillTimeLike.Play();
		PotWaterRoot.SetHiddenInGame(false, true);

		BP_Filled();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Filled(){}

	UFUNCTION()
	private void FilledTimeLikeUpdate(float CurrentValue)
	{
		PotWaterRoot.SetRelativeLocation(FVector::UpVector * CurrentValue * WaterFillValue);
	}

	void Shot()
	{
		if (bShot)
			return;

		if (HasControl())
			CrumbShot(bFilled);
	}

	UFUNCTION(CrumbFunction)
	void CrumbShot(bool bIsFilled)
	{
		bFilled = bIsFilled;
		BP_Shot(bFilled);

		SetActorEnableCollision(false);

		bShot = true;
		PotMeshComp.SetHiddenInGame(true, true);
		PotWaterRoot.SetHiddenInGame(true, true);

		StartLocation = FallingWaterRoot.WorldLocation;

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(StartLocation, StartLocation - FVector::UpVector * 3000.0);

		if (HitResult.bBlockingHit)
			EndLocation = HitResult.ImpactPoint;
		else
			EndLocation = StartLocation - FVector::UpVector * 3000.0;

		if (bFilled)
			WaterFallTimeLike.Play();

		USplitTraversalWaterPotEventHandler::Trigger_OnExplode(this);

		// This same function is for some reason also called when we reach the end of the spline. We don't want to play audio for that.
		if(ProgressAlongSpline < SplineComp.SplineLength)
		{
			USplitTraversalWaterPotSpawnerEventHandler::Trigger_OnPotDestroyed(Spawner, FSplitTraversalWaterPotSpawnerEventParams(this));
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Shot(bool bIsFilled) {}

	UFUNCTION()
	private void WaterFallTimeLikeUpdate(float CurrentValue)
	{
		FallingWaterRoot.SetWorldLocation(Math::Lerp(StartLocation, EndLocation, CurrentValue));
	}

	UFUNCTION()
	private void WaterFallTimeLikeFinished()
	{
		BP_WaterLanded();

		USplitTraversalWaterPotEventHandler::Trigger_OnWaterLanded(this);

		float GateDistance = FallingWaterRoot.WorldLocation.Distance(FireGate.FantasyRoot.WorldLocation);

		if (GateDistance < FireGate.TargetRadius && HasControl())
			FireGate.CrumbWatered();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_WaterLanded() {}
};