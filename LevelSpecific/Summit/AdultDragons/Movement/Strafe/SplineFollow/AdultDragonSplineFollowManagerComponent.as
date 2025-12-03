struct FAdultDragonSplineFollowData
{
	access InternalSplinePos = private, UAdultDragonSplineFollowManagerComponent;

	access:InternalSplinePos FSplinePosition InternalPrevSplinePos;
	access:InternalSplinePos FSplinePosition InternalCurrentSplinePos;
	access:InternalSplinePos float FollowCurrentSplineAlpha = 1;
	access:InternalSplinePos float FollowCurrentSplineBlendTime = 0;

	USummitAdultDragonSplineFollowComponent SplineFollowComp;
	FName SplineTag = NAME_None;

	bool IsValid() const
	{
		if (!InternalCurrentSplinePos.IsValid())
			return false;

		return true;
	}

	FVector GetWorldLocation() const property
	{
		if (FollowCurrentSplineAlpha > 1 - SMALL_NUMBER)
			return InternalCurrentSplinePos.WorldLocation;
		if (!InternalPrevSplinePos.IsValid())
			return InternalCurrentSplinePos.WorldLocation;

		// return InternalCurrentSplinePos.WorldLocation;
		return Math::Lerp(InternalPrevSplinePos.WorldLocation, InternalCurrentSplinePos.WorldLocation, GetInternalAlpha());
	}

	FQuat GetWorldRotation() const property
	{
		if (FollowCurrentSplineAlpha > 1 - SMALL_NUMBER)
			return InternalCurrentSplinePos.WorldRotation;
		if (!InternalPrevSplinePos.IsValid())
			return InternalCurrentSplinePos.WorldRotation;
		// return InternalCurrentSplinePos.WorldRotation;

		return FQuat::FastLerp(InternalPrevSplinePos.WorldRotation, InternalCurrentSplinePos.WorldRotation, GetInternalAlpha());
	}

	FVector GetWorldForwardVector() const property
	{
		if (FollowCurrentSplineAlpha > 1 - SMALL_NUMBER)
			return InternalCurrentSplinePos.WorldForwardVector;
		if (!InternalPrevSplinePos.IsValid())
			return InternalCurrentSplinePos.WorldForwardVector;
		// return InternalCurrentSplinePos.WorldForwardVector;
		return Math::Lerp(InternalPrevSplinePos.WorldForwardVector, InternalCurrentSplinePos.WorldForwardVector, GetInternalAlpha()).GetSafeNormal();
	}

	FVector GetWorldUpVector() const property
	{
		if (FollowCurrentSplineAlpha > 1 - SMALL_NUMBER)
			return InternalCurrentSplinePos.WorldUpVector;
		if (!InternalPrevSplinePos.IsValid())
			return InternalCurrentSplinePos.WorldUpVector;
		// return InternalCurrentSplinePos.WorldUpVector;
		return Math::Lerp(InternalPrevSplinePos.WorldUpVector, InternalCurrentSplinePos.WorldUpVector, GetInternalAlpha()).GetSafeNormal();
	}

	FVector GetWorldRightVector() const property
	{
		if (FollowCurrentSplineAlpha > 1 - SMALL_NUMBER)
			return InternalCurrentSplinePos.WorldRightVector;
		if (!InternalPrevSplinePos.IsValid())
			return InternalCurrentSplinePos.WorldRightVector;

		// return InternalCurrentSplinePos.WorldRightVector;
		return Math::Lerp(InternalPrevSplinePos.WorldRightVector, InternalCurrentSplinePos.WorldRightVector, GetInternalAlpha()).GetSafeNormal();
	}

	FTransform GetWorldTransform() const property
	{
		return FTransform(GetWorldRotation(), GetWorldLocation());
	}

	float GetSplineLength() const property
	{
		if (InternalCurrentSplinePos.CurrentSpline == nullptr)
			return -1;
		return InternalCurrentSplinePos.CurrentSpline.SplineLength;
	}

	float GetCurrentSplineDistance() const property
	{
		return InternalCurrentSplinePos.CurrentSplineDistance;
	}

	bool HasReachedEndOfSpline(float MoveDirection) const
	{
		FSplinePosition PositionToTest = InternalCurrentSplinePos;
		bool bCouldMove = PositionToTest.Move(MoveDirection);
		return !bCouldMove;
	}

	FSplinePosition GetMostActiveSplinePosition() const
	{
		return InternalCurrentSplinePos;
	}

	private float GetInternalAlpha() const
	{
		return Math::EaseOut(0, 1, FollowCurrentSplineAlpha, 2);
	}
}

struct FInstigatedAutoSelectableSplines
{
	TArray<ASplineActor> AutoSelectableSplines;
}

class UAdultDragonSplineFollowManagerComponent : UActorComponent
{
	TOptional<FAdultDragonSplineFollowData> CurrentSplineFollowData;
	private FAdultDragonSplineFollowData InternalSplineFollowData;
	private UHazeSplineComponent MainSplineToFollow;
	TArray<AActor> SplineQueue;
	float RubberBandingMoveSpeedMultiplier = 1;

	AHazePlayerCharacter Player;
	bool bForceLockedStrafe = false;

	// Splines added that can be auto selected
	TMap<AActor, FInstigatedAutoSelectableSplines> AutoSelectableSplines;

	AAdultDragonSplineFollowSelectionZone SelectionZone;

	AActor CurrentSplineActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UPlayerHealthComponent::Get(Player).OnDeathTriggered.AddUFunction(this, n"OnDeath");
	}

	UFUNCTION()
	private void OnDeath()
	{
		AutoSelectableSplines.Empty();
	}

	void AddSplinesToConsider(AActor Instigator, TArray<ASplineActor> Splines)
	{
		AutoSelectableSplines.FindOrAdd(Instigator).AutoSelectableSplines.Append(Splines);
	}
	void RemoveSplinesToConsider(AActor Instigator)
	{
		AutoSelectableSplines.Remove(Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if (CurrentSplineActor == nullptr)
			return;
		if (!CurrentSplineFollowData.IsSet())
			return;

		TEMPORAL_LOG(this)
			.Value("CurrentSplineActor", CurrentSplineActor)
			.DirectionalArrow("CurrentSplineFollowData;UpVector", Owner.ActorLocation, CurrentSplineFollowData.Value.WorldUpVector * 10000, 100, 100, FLinearColor::LucBlue);

		if (SelectionZone != nullptr)
		{
			TEMPORAL_LOG(this)
				.Value("SelectionZone", SelectionZone.ActorNameOrLabel)
				.Value("SplineSwitchBlendTime", SelectionZone.SplineSwitchBlendTime);
		}
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetSplineToFollow(AActor ActorWithSplineFollowComponent, bool bClearSplineQueue = true, FName SplineTag = NAME_None, float BlendTime = 0)
	{
		SetSplineToFollow(ActorWithSplineFollowComponent, bClearSplineQueue, SplineTag, BlendTime);
	}
	/**
	 * @bClearSplineQueue; if you have added splines to the upcoming spline queue, that will be cleared and you would have to add a new queue
	 */
	UFUNCTION(BlueprintCallable)
	void SetSplineToFollow(AActor ActorWithSplineFollowComponent, bool bClearSplineQueue = true, FName SplineTag = NAME_None, float BlendTime = 0)
	{
		auto NewSplineFollowComponent = USummitAdultDragonSplineFollowComponent::Get(ActorWithSplineFollowComponent);
		if (CurrentSplineFollowData.IsSet() && CurrentSplineFollowData.Value.SplineFollowComp == NewSplineFollowComponent)
			return;

		devCheck(NewSplineFollowComponent != nullptr, "Adult Dragon Spline Follow Manager: Setting Spline to follow failed, actor probably had no spline follow component");

		FSplinePosition SplinePos = NewSplineFollowComponent.SplineComp.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		FAdultDragonSplineFollowData NewFollowData;
		NewFollowData.SplineFollowComp = NewSplineFollowComponent;
		NewFollowData.SplineTag = SplineTag;
		NewFollowData.InternalCurrentSplinePos = SplinePos;

		NewFollowData.InternalPrevSplinePos = GetSplineFollowData().InternalCurrentSplinePos;
		if (!NewFollowData.InternalPrevSplinePos.IsValid())
			NewFollowData.InternalPrevSplinePos = NewFollowData.InternalCurrentSplinePos;

		if (BlendTime > SMALL_NUMBER)
		{
			NewFollowData.FollowCurrentSplineAlpha = 0;
			NewFollowData.FollowCurrentSplineBlendTime = BlendTime;
		}
		else
		{
			NewFollowData.FollowCurrentSplineAlpha = 1;
			NewFollowData.FollowCurrentSplineBlendTime = 0;
		}

		CurrentSplineFollowData.Set(NewFollowData);

		if (SplineTag == NAME_None)
		{
			MainSplineToFollow = SplinePos.CurrentSpline;
		}

		if (bClearSplineQueue)
		{
			SplineQueue.Reset();
		}

		CurrentSplineActor = ActorWithSplineFollowComponent;
	}

	void AddSplinesToQueue(TArray<AActor> ActorsWithSplineFollowComponent)
	{
#if EDITOR
		for (auto It : ActorsWithSplineFollowComponent)
		{
			auto NewSplineFollowComponent = USummitAdultDragonSplineFollowComponent::Get(It);
			devCheck(NewSplineFollowComponent != nullptr, f"AddSplinesToQueue: {It} is missing a 'SummitAdultDragonSplineFollowComponent'");
		}
#endif

		SplineQueue.Append(ActorsWithSplineFollowComponent);
	}

	FAdultDragonSplineFollowData UpdateInternalSplinePosition(float DeltaTime)
	{
		InternalSplineFollowData = CurrentSplineFollowData.Value;
		if (InternalSplineFollowData.FollowCurrentSplineBlendTime > SMALL_NUMBER)
		{
			float InterpSpeed = 1 / InternalSplineFollowData.FollowCurrentSplineBlendTime;
			InternalSplineFollowData.FollowCurrentSplineAlpha = Math::FInterpConstantTo(InternalSplineFollowData.FollowCurrentSplineAlpha, 1, DeltaTime, InterpSpeed);
		}
		else
			InternalSplineFollowData.FollowCurrentSplineAlpha = 1;

		auto NewSplinePos = InternalSplineFollowData.InternalCurrentSplinePos.CurrentSpline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);
		// Update current spline if we change from one spline to another through connections
		if (NewSplinePos.CurrentSpline.Owner != CurrentSplineFollowData.Value.SplineFollowComp.Owner)
		{
			SetSplineToFollow(NewSplinePos.CurrentSpline.Owner);
			InternalSplineFollowData = CurrentSplineFollowData.Value;
		}

		InternalSplineFollowData.InternalCurrentSplinePos = NewSplinePos;
		if (InternalSplineFollowData.FollowCurrentSplineAlpha < 1 - SMALL_NUMBER)
			InternalSplineFollowData.InternalPrevSplinePos = InternalSplineFollowData.InternalPrevSplinePos.CurrentSpline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);

		CurrentSplineFollowData.Set(InternalSplineFollowData);

		// We have a queue, so we try to update the spline distance with the current velocity,
		// If we can't move that amount, we have reached the end and should transfer to the next spline
		if (SplineQueue.Num() > 0)
		{
			float VelocityInSplineDir = InternalSplineFollowData.WorldForwardVector.DotProduct(Player.ActorVelocity * DeltaTime);
			if (InternalSplineFollowData.HasReachedEndOfSpline(VelocityInSplineDir))
			{
				auto NewSpline = SplineQueue[0];
				SplineQueue.RemoveAt(0); // Keep the order
				SetSplineToFollow(NewSpline, false);
			}
		}

		return CurrentSplineFollowData.Value;
	}

	FAdultDragonSplineFollowData GetSplineFollowData()
	{
		return InternalSplineFollowData;
	}

	UHazeSplineComponent GetRubberBandSplineFollowData()
	{
		return MainSplineToFollow;
	}
};