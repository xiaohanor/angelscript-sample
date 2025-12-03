
UCLASS(Abstract)
class UWorld_Shared_Platform_KineticSplineActor_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AKineticSplineFollowActor SplineActor;
	TArray<AHazePlayerCharacter> Players;
	UPrimitiveComponent MultiPositionComp;

	UPROPERTY()
	bool bAlwaysActive = true;

	UPROPERTY(Category = "Positioning")
	bool bUseMultiPosition = false;

	UPROPERTY(Category = "Positioning", Meta = (EditCondition = "bUseMultiPosition"))
	bool bAttachToChild = false;

	UPROPERTY(Category = "Positioning", Meta = (EditCondition = "bUseMultiPosition"))
	FName MultiPositionColliderName;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SplineActor = Cast<AKineticSplineFollowActor>(HazeOwner);
		devCheck(SplineActor != nullptr, f"{GetName()} was used on an actor that's not a AKineticSplineFollowActor!");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
	#if TEST
		if(SplineActor == nullptr)
			return false;
	#endif

		if(bAlwaysActive)
			return true;

		return SplineActor.IsActive();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bAlwaysActive)
			return false;
		
		return !SplineActor.IsActive();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplineActor.OnReachedEnd.AddUFunction(this, n"OnSplineReachEnd");
		Players = Game::GetPlayers();

		if(bUseMultiPosition && MultiPositionColliderName != NAME_None)
		{
			if(bAttachToChild)
			{
				TArray<AActor> AttachedActors;
				SplineActor.GetAttachedActors(AttachedActors);

				// Let's just assume that there's only one...
				if(AttachedActors.Num() > 0)
				{
					MultiPositionComp = UPrimitiveComponent::Get(AttachedActors[0], MultiPositionColliderName);
				}
			}
			else
			{
				MultiPositionComp = UPrimitiveComponent::Get(SplineActor, MultiPositionColliderName);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplineActor.OnReachedEnd.UnbindObject(this);
	}

	UFUNCTION(BlueprintPure)
	float GetSplineAlpha()
	{
		int _;
		float SplineDistance;
		
		SplineActor.GetSplineDistanceAtTime(SplineActor.GetCurrentTime(), SplineDistance, _);
		return SplineDistance / SplineActor.GetFollowSpline().Spline.SplineLength;
	}

	UFUNCTION(BlueprintPure)
	float GetDirectionOnSpline()
	{
		return SplineActor.IsReversed() ? 1.0 : 1.0;
	}

	UFUNCTION()
	void OnSplineReachEnd()
	{
		const float Alpha = GetSplineAlpha();
		if(Math::IsNearlyEqual(Alpha, 0.0, 0.01))
			StartForward();
		else
			StartBackward();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(MultiPositionComp != nullptr)
		{
			TArray<FAkSoundPosition> SoundPositions;

			for(auto& Player : Players)
			{
				FVector ClosestPos;
				const float Dist = MultiPositionComp.GetClosestPointOnCollision(Player.ActorLocation, ClosestPos);
				if(Dist < 0)
					ClosestPos = MultiPositionComp.WorldLocation;
				
				SoundPositions.Add(FAkSoundPosition(ClosestPos));
			}

			DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
		}
	}

	UFUNCTION(BlueprintEvent)
	void StartForward() {}

	UFUNCTION(BlueprintEvent)
	void StartBackward() {}
}