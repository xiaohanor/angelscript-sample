UCLASS(Abstract)
class AFlyingPig : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PigRoot;

	UPROPERTY(DefaultComponent, Attach = PigRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UPlayerLookAtTriggerComponent PlayerLookAtTriggerComp;

	UPROPERTY(EditAnywhere)
	UAnimSequence FlyAnimation;

	UPROPERTY(EditInstanceOnly)
	ASplineActor TargetSpline;

	UPROPERTY(EditAnywhere)
	float SplineSpeed = 2000.0;

	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float StartFraction = 0.0;

	float VerticalOffset = 0.0;

	bool bFlapping = true;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AFlyingPigPoop> PoopClass;

	bool bWeighedDown = false;
	int NumPoops = 0;

	UPROPERTY(EditAnywhere)
	bool bPoop = true;

	UPROPERTY(EditAnywhere)
	bool bUseTimeLike = false;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FlyTimeLike;

	UPROPERTY(EditInstanceOnly)
	bool bTriggerLookAtReaction = true;

	UPlayerPigSiloComponent MioPig;
	UPlayerPigSiloComponent ZoePig;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PlayerLookAtTriggerComp.bStartDisabled = !bTriggerLookAtReaction;

		if (TargetSpline == nullptr)
			return;
		
		FRotator Rot = TargetSpline.Spline.GetWorldRotationAtSplineDistance(TargetSpline.Spline.SplineLength * StartFraction).Rotator();
		Rot.Roll = 0.0;
		Rot.Pitch = 0.0;
		SetActorLocationAndRotation(TargetSpline.Spline.GetWorldLocationAtSplineFraction(StartFraction), Rot);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bPoop)
			Timer::SetTimer(this, n"Poop", Math::RandRange(3.0, 6.0), true);
		
		PlayerLookAtTriggerComp.OnBeginLookAt.AddUFunction(this, n"PigSighted");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = FlyAnimation;
		AnimParams.BlendTime = 0.0;
		AnimParams.bLoop = true;
		AnimParams.StartTime = Math::RandRange(0.0, FlyAnimation.PlayLength);
		SkelMesh.PlaySlotAnimation(AnimParams);
	}

	// We cannot update the platforms position during the TimeLike tick group
	// That leads to the movement not being accounted for when simulating physics on the players
	// Moved this into Tick instead
	// UFUNCTION()
	// private void UpdateFly(float CurValue)
	// {
	// 	FVector Loc = TargetSpline.Spline.GetWorldLocationAtSplineFraction(CurValue);
	// 	FRotator Rot = TargetSpline.Spline.GetWorldRotationAtSplineFraction(CurValue).Rotator();
	// 	Rot.Pitch = 0.0;
	// 	Rot.Roll = 0.0;
	// 	SetActorLocationAndRotation(Loc, Rot);
	// }

	UFUNCTION(NotBlueprintCallable)
	void Poop()
	{
		// no poopy while in silo slide bc they get destroyed whacky in network when transitioning to sausage lvl
		if (HasControl() && !PlayersAreInSiloSlide()) 
			CrumbPoop(ActorLocation);
	}

	private bool PlayersAreInSiloSlide()
	{
		if (MioPig == nullptr || ZoePig == nullptr)
		{
			MioPig = UPlayerPigSiloComponent::Get(Game::Mio);
			ZoePig = UPlayerPigSiloComponent::Get(Game::Zoe);
		}
		if (MioPig == nullptr || ZoePig == nullptr)
			return false;
		return MioPig.IsSiloMovementActive() || ZoePig.IsSiloMovementActive();
	}

	UFUNCTION(CrumbFunction)
	void CrumbPoop(FVector Location)
	{
		auto Poopy = SpawnActor(PoopClass, Location, FRotator::ZeroRotator, NAME_None, true);
		Poopy.MakeNetworked(this, NumPoops);
		NumPoops++;
		FinishSpawningActor(Poopy);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetSpline == nullptr)
		{
			PigRoot.SetRelativeLocation(FVector(0.0, 0.0, VerticalOffset));
			return;
		}

		if (bUseTimeLike)
		{
			float TimeLikeTime = StartFraction;
			TimeLikeTime += Time::PredictedGlobalCrumbTrailTime / FlyTimeLike.Duration;
			TimeLikeTime = Math::Wrap(TimeLikeTime, 0.0, 1.0);
			const float Value = FlyTimeLike.Curve.GetFloatValue(TimeLikeTime);

			FVector Loc = TargetSpline.Spline.GetWorldLocationAtSplineFraction(Value);
			FRotator Rot = TargetSpline.Spline.GetWorldRotationAtSplineFraction(Value).Rotator();
			Rot.Pitch = 0.0;
			Rot.Roll = 0.0;
			SetActorLocationAndRotation(Loc, Rot);			
		}
		else
		{
			const FTransform SplineTransform = GetSplineTransform();
			FVector Loc = SplineTransform.Location + (FVector::UpVector * VerticalOffset);
			SetActorLocationAndRotation(Loc, SplineTransform.Rotation);
		}
	}

	UFUNCTION()
	void WeighDown(bool bWeigh)
	{
		bWeighedDown = bWeigh;
	}

	UFUNCTION()
	private void PigSighted(AHazePlayerCharacter Player)
	{
		FFlyingPigSightedEventHandlerParams Params;
		Params.Player = Player;
		UFlyingPigSightedEventHandler::Trigger_FlyingPigSighted(this, Params);
	}

	FTransform GetSplineTransform() const
	{
		float SplineDist = StartFraction * TargetSpline.Spline.SplineLength;
		SplineDist += Time::PredictedGlobalCrumbTrailTime * SplineSpeed;

		SplineDist = Math::Wrap(SplineDist, 0, TargetSpline.Spline.SplineLength);

		return TargetSpline.Spline.GetWorldTransformAtSplineDistance(SplineDist);
	}
}