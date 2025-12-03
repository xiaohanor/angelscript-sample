class ASummitWeightedPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsWeightComponent WeightComp;
	default WeightComp.MassScale = 0.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 90000.0;

	UPROPERTY(EditAnywhere)
	float ZTargetOffset = -4000;

	UPROPERTY(EditAnywhere)
	bool bUseMeltable;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition="!bUseMeltable", EditConditionHides))
	ASummitCounterWeight CounterWeight;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition="bUseMeltable", EditConditionHides))
	AMeltableCounterWeight MeltableCounterWeight;

	UPROPERTY(EditInstanceOnly)
	TArray<ASummitFruitPressStatueWheels> Wheels;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	FVector TargetLocation;
	FVector StartLocation;

	bool bStartedFalling;
	bool bFinishedFalling;
	bool bFalling;
	bool bHitConstraint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			Actor.AttachToComponent(TranslateComp, NAME_None, EAttachmentRule::KeepWorld);
		}
		
		StartLocation = ActorLocation;
		TargetLocation = ActorLocation + FVector(0,0,ZTargetOffset);

		if (bUseMeltable)
		{
			MeltableCounterWeight.OnWeightStartsFalling.AddUFunction(this, n"OnMeltableWeightStartsFalling");
			TranslateComp.OnConstraintHit.AddUFunction(this, n"OnConstraintHit");
		}
	}
	
	UFUNCTION()
	private void OnMeltableWeightStartsFalling(AMeltableCounterWeight CurrentMeltableCounterWeight)
	{
		bFalling = true;
		USummitWeightedPlatformEffectHandler::Trigger_OnClimbWallStartDrop(this);
	}

	UFUNCTION()
	private void OnConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (!bHitConstraint)
		{
			USummitWeightedPlatformEffectHandler::Trigger_OnClimbWallEndDrop(this);
			bHitConstraint = true;

			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (CameraShake != nullptr)
					Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000.0, 5000.0);
				if (Rumble != nullptr)
				{
					float Distance = Player.GetDistanceTo(this);
					float Alpha = Distance / 5000.0;
					Alpha = Math::Clamp(Alpha, 0.0, 0.8);
					Player.PlayForceFeedback(Rumble, false, false, this, Alpha);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bUseMeltable)
		{
			if (bFalling)
			{
				WeightComp.MassScale = 1.0;
			}
		}
		else
		{
			ActorLocation = Math::VLerp(TargetLocation, StartLocation, FVector(CounterWeight.GetAlpha()));

			if (!bStartedFalling && CounterWeight.GetAlpha() < 1.0)
			{
				bStartedFalling = true;
				USummitWeightedPlatformEffectHandler::Trigger_OnWeightPlatformStartDropped(this);
			}

			if (!bFinishedFalling && CounterWeight.GetAlpha() < 0.01)
			{
				bFinishedFalling = true;
				USummitWeightedPlatformEffectHandler::Trigger_OnWeightPlatformReachedEnd(this);
			}
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FVector Start = ActorLocation;
		FVector End = ActorLocation + FVector(0,0,ZTargetOffset);
		Debug::DrawDebugLine(Start, End, FLinearColor::Blue, 20.0);
		Debug::DrawDebugCircle(End, 200.0, 12, FLinearColor::Blue, 15.0);
	}
#endif
};