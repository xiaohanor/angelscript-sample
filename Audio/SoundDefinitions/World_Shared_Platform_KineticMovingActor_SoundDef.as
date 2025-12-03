
UCLASS(Abstract)
class UWorld_Shared_Platform_KineticMovingActor_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadWrite, NotVisible, DisplayName = "Velocity - Linear Normalized")
	float VelocityLinearNormalized = 0.0;

	UPROPERTY(BlueprintReadWrite, NotVisible, DisplayName = "Velocity - Angular Combined")
	float VelocityAngularCombined = 0.0;

	UPROPERTY(BlueprintReadWrite, NotVisible, DisplayName = "Velocity - Linear Delta")
	float VelocityLinearDelta = 0.0;

	AKineticMovingActor MovingActor;

	TArray<AHazePlayerCharacter> Players;
	UPrimitiveComponent MultiPositionComp;

	UPROPERTY()
	bool bAlwaysActive = true;

	UPROPERTY(Category = "Positioning")
	bool bUseMultiPosition = false;

	UPROPERTY(Category = "Positioning", Meta = (EditCondition = "bUseMultiPosition"))
	FName MultiPositionColliderName;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MovingActor = Cast<AKineticMovingActor>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bAlwaysActive)
			return true;

		return MovingActor.IsActive();	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bAlwaysActive)
			return false;

		return !MovingActor.IsActive();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovingActor.OnStartForward.AddUFunction(this, n"GoForward");
		MovingActor.OnReachedForward.AddUFunction(this, n"OnReachForward");
		MovingActor.OnStartBackward.AddUFunction(this, n"GoBackward");
		MovingActor.OnReachedBackward.AddUFunction(this, n"OnReachBackward");

		Players = Game::GetPlayers();

		if(bUseMultiPosition && MultiPositionColliderName != NAME_None)
		{
			TArray<AActor> AttachedActors;
			MovingActor.GetAttachedActors(AttachedActors);

			// Let's just assume that there's only one...
			int NumActors = AttachedActors.Num();
			if(NumActors > 0)
			{
				MultiPositionComp = UPrimitiveComponent::Get(AttachedActors[NumActors - 1], MultiPositionColliderName);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MovingActor.OnStartForward.UnbindObject(this);
		MovingActor.OnStartBackward.UnbindObject(this);
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

		#if EDITOR
		auto TemporalLog = TEMPORAL_LOG(f"{HazeOwner.GetName()}/Audio");
		TemporalLog.
		Value("Velocity - Linear Normalized: ", VelocityLinearNormalized).
		Value("Velocity - Angular Combined: ", VelocityAngularCombined).
		Value("Velocity - Linear Delta: ", VelocityLinearDelta).
		Value("Moving Alpha: ", GetMovingAlpha()).
		Value("Direction Value: ", GetDirectionSign());
		#endif
	}

	UFUNCTION(BlueprintPure)
	float GetSpeakerPanning_SpatializationMixValue()
	{
		for(auto Player : Game::GetPlayers())
		{
			if(Player.GetCurrentGameplayPerspectiveMode() != EPlayerMovementPerspectiveMode::ThirdPerson)
				return 0.0;
		}

		return 1.0;
	}

	UFUNCTION(BlueprintEvent)
	void GoForward() {}

	UFUNCTION(BlueprintEvent)
	void GoBackward() {}

	UFUNCTION(BlueprintEvent)
	void OnReachForward() {}

	UFUNCTION(BlueprintEvent)
	void OnReachBackward() {}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Moving Alpha"))
	float GetMovingAlpha() const
	{
		int ReachedForwardCount = 0;
		int ReachedBackwardCount = 0;

		return MovingActor.GetCurrentAlpha(ReachedForwardCount, ReachedBackwardCount);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Direction Value"))
	float GetDirectionSign() const
	{
		return MovingActor.IsMovingBackward() ? -1.0 : 1.0;
	}
}