
UCLASS(Abstract)
class UWorld_Shared_Platform_KineticRotatingActor_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AKineticRotatingActor RotatingActor;

	private FRotator PreviousRotation;
	private float CurrRotationSpeed;
	private float LastRotationSpeed;
	private float CurrRotationDelta;

	TArray<AHazePlayerCharacter> Players;
	UPrimitiveComponent MultiPositionComp;

	UPROPERTY()
	bool bAlwaysActive = true;

	UPROPERTY(Category = "Positioning")
	bool bUseMultiPosition = false;

	UPROPERTY(Category = "Positioning", Meta = (EditCondition = "bUseMultiPosition"))
	FName MultiPositionColliderName;

	UPROPERTY(Category = "Positioning", Meta = (EditCondition = "bUseMultiPosition"))
	int MultiPositionColliderChildIndex = 0;

	UPROPERTY(Category = "Positioning")
	FVector PositionalOffset = FVector::ZeroVector;

	private bool bWasPaused = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		RotatingActor = Cast<AKineticRotatingActor>(HazeOwner);
		bWasPaused = RotatingActor.WasPausedFromStart();
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = RotatingActor;
		ComponentName = n"PlatformMesh";
		bUseAttach = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(bAlwaysActive)
			return true;

		return !RotatingActor.IsPaused() && RotatingActor.IsActive();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bAlwaysActive)
			return false;
		
		return RotatingActor.IsPaused() || !RotatingActor.IsActive();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RotatingActor.OnStartForward.AddUFunction(this, n"GoForward");
		RotatingActor.OnStartBackward.AddUFunction(this, n"GoBackward");

		if (PositionalOffset != FVector::ZeroVector)
		{
			DefaultEmitter.AudioComponent.SetRelativeLocation(PositionalOffset);
		}

		Players = Game::GetPlayers();

		if(bUseMultiPosition)
		{
			TArray<AActor> AttachedActors;
			RotatingActor.GetAttachedActors(AttachedActors);

			// Let's just assume that there's only one...
			if(AttachedActors.IsValidIndex(MultiPositionColliderChildIndex))
			{
				MultiPositionComp = UPrimitiveComponent::Get(AttachedActors[MultiPositionColliderChildIndex], MultiPositionColliderName);
			}
		}

		// If we activated after a pause the delegates will already have fired, so call them manually here
		if(bWasPaused)
		{
			if(RotatingActor.IsMovingBackwardAtTime(RotatingActor.GetCurrentTime()))
				GoBackward();
			else
				GoForward();
		}

		bWasPaused = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RotatingActor.OnStartForward.UnbindObject(this);
		RotatingActor.OnStartBackward.UnbindObject(this);

		bWasPaused = RotatingActor.IsPaused();		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FRotator CurrRotation = RotatingActor.GetActorRotation();
		float RotationDistance = CurrRotation.Quaternion().AngularDistance(PreviousRotation.Quaternion());
		CurrRotationSpeed = RotationDistance / DeltaSeconds;
		CurrRotationDelta = CurrRotationSpeed - LastRotationSpeed;

		PreviousRotation = CurrRotation;
		LastRotationSpeed = CurrRotationSpeed;

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
	void GoForward() {}

	UFUNCTION(BlueprintEvent)
	void GoBackward() {}

	UFUNCTION(BlueprintPure)
	void GetRotationSpeed(float&out Speed, float&out Delta)
	{
		Speed = CurrRotationSpeed;
		Delta = CurrRotationDelta;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Moving Alpha"))
	float GetMovingAlpha()
	{
		return RotatingActor.GetCurrentAlpha();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Direction Value"))
	float GetDirectionSign()
	{
		return RotatingActor.IsMovingBackwardAtTime(RotatingActor.GetCurrentTime()) ? -1.0 : 1.0;
	}
}