class USanctuaryBossAttackTriggerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	ESanctuaryBossHydraAttackType AttackType = ESanctuaryBossHydraAttackType::Smash;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "AttackType == ESanctuaryBossHydraAttackType::FireBreath", EditConditionHides))
	ASplineActor HeadSpline;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "AttackType == ESanctuaryBossHydraAttackType::FireBreath", EditConditionHides))
	ASplineActor TargetSpline;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "AttackType == ESanctuaryBossHydraAttackType::FireBreath", EditConditionHides))
	float SweepDuration = -1.0;

	UPROPERTY(EditAnywhere)
	ESanctuaryBossHydraIdentifier Identifier = ESanctuaryBossHydraIdentifier::MAX;

	UPROPERTY(EditAnywhere)
	bool bAttackPlayer = false;

	UPROPERTY(EditAnywhere)
	bool bTriggerOnImpact = false;

	UPROPERTY(EditAnywhere)
	float Delay = 2.0;

	UPROPERTY(EditAnywhere)
	float TelegraphDuration = -1.0;

	UPROPERTY(EditAnywhere)
	float RecoverDuration = -1.0;

	bool bIsTriggered = false;

	AHazePlayerCharacter Player; 

	UMovementImpactCallbackComponent ImpactComp;
	USanctuaryBossMovablePlayerTriggerComponent TriggerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp = UMovementImpactCallbackComponent::GetOrCreate(Owner);
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");

		TriggerComp = USanctuaryBossMovablePlayerTriggerComponent::Get(Owner);
		if (TriggerComp != nullptr)
			TriggerComp.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter InPlayer)
	{
		if (!bTriggerOnImpact)
			return;
		
		Trigger(InPlayer);
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter InPlayer)
	{	
		Trigger(InPlayer);
	}

	UFUNCTION()
	private void Trigger(AHazePlayerCharacter InPlayer)
	{
		if (bIsTriggered)
			return;

		bIsTriggered = true;

		Player = InPlayer;

		Timer::SetTimer(this, n"Attack", Delay);
	}

	UFUNCTION()
	void Attack()
	{
		auto Hydra = Hydra::GetHydraBase();
		if (Hydra == nullptr)
			return;

		auto TargetActor = GetTargetActor();
		USceneComponent PlatformComponent = USanctuaryBossHydraPlatformComponent::Get(TargetActor);
		if (PlatformComponent == nullptr)
			PlatformComponent = TargetActor.RootComponent;

		if (AttackType == ESanctuaryBossHydraAttackType::Smash)
		{
			auto TelegraphComponent = USanctuaryBossHydraTelegraphComponent::Get(Owner);
			
			Hydra.TriggerSmash(
				TargetActor.ActorLocation,
				PlatformComponent,
				TelegraphComponent,
				TelegraphDuration,
				RecoverDuration,
				Identifier = Identifier
			);
		}
		else if (AttackType == ESanctuaryBossHydraAttackType::FireBreath)
		{
			// TODO: Way too much data to send over network by default :^)
			float HeadSplineSampleStepSize = HeadSpline.Spline.SplineLength * 0.3;
			float TargetSplineSampleStepSize = TargetSpline.Spline.SplineLength * 0.3;

			Hydra.TriggerFireBreath(
				HeadSpline.Spline.BuildRuntimeSplineFromHazeSpline(HeadSplineSampleStepSize),
				TargetSpline.Spline.BuildRuntimeSplineFromHazeSpline(TargetSplineSampleStepSize),
				PlatformComponent,
				SweepDuration,
				TelegraphDuration,
				RecoverDuration,
				bInfiniteHeight = true,
				Identifier = Identifier
			);
		}
		else
		{
			devError(f"Unhandled attack type: {AttackType}");
		}
	}

	AActor GetTargetActor() const
	{
		if (bAttackPlayer)
			return Player;
		
		return Owner;
	}
};