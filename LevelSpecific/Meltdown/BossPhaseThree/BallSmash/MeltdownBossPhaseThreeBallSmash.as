delegate void FMeltdownBossPhaseThreeBallSmashDone();

class UAnimNotify_MeltdownBossPhaseThreeBallSmash : UAnimNotify {}

UCLASS(Abstract)
class AMeltdownBossPhaseThreeBallSmash : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SceneRoot;

	private FTransform OriginalTransform;
	private FMeltdownBossPhaseThreeBallSmashDone OnDone;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeTelegraph> TelegraphClass;
	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeShockwave> ShockwaveClass;

	// To make the cubes move up with the shockwave.
	UPROPERTY(EditAnywhere)
	AStaticMeshActor BossPhase3Floor;

	UPROPERTY()
	float TelegraphRadius = 500.0;
	UPROPERTY()
	float ShockwaveMaxRadius = 4000.0;
	UPROPERTY()
	float ShockwaveDuration = 4.0;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> DefaultSmashLocations;

	UPROPERTY(EditInstanceOnly)
	TArray<float> AttackStartTimings;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> SmashShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SmashFeedback;

	UPROPERTY(EditInstanceOnly)
	AMeltdownPhaseThreeBoss Rader;

	AMeltdownBossPhaseThreeTelegraph Telegraph;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		OriginalTransform = ActorTransform;
	}

	UFUNCTION()
	void OnSmash() 
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(SmashShake, this);
			Player.PlayForceFeedback(SmashFeedback, false, true, this);
		}

		BP_OnSmash();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_OnSmash(){}

	UFUNCTION(DevFunction)
	void Launch(FMeltdownBossPhaseThreeBallSmashDone OnSmashesDone)
	{
		Root.SetAbsolute(false, false, true);
		Rader.CurrentLocomotionTag = n"BallBossPortal";
		Rader.PortalLocomotionTag = n"BallBossPortal";
		AttachToComponent(Rader.Mesh, n"LeftAttach");

		TArray<UAnimSequence> Sequences = GetAttackSequences();

		float TelegraphTime = 1.0;
		for (int i = 0, Count = Sequences.Num(); i < Count; ++i)
		{
			TArray<float32> AttackPoints;
			Sequences[i].GetAnimNotifyTriggerTimes(UAnimNotify_MeltdownBossPhaseThreeBallSmash, AttackPoints);

			for (int AttackIndex = 0, AttackCount = AttackPoints.Num(); AttackIndex < AttackCount; ++AttackIndex)
			{
				FMeltdownBossBallSmashAttackParameters Params;

				Params.Duration = AttackPoints[AttackIndex];
				if (AttackIndex > 0)
					Params.Duration -= AttackPoints[AttackIndex - 1];

				Params.AttackStartTime = 0.0;
				Params.TelegraphStartTime = Math::Max(0.0, Params.Duration - TelegraphTime);
				Params.TelegraphClass = TelegraphClass;
				Params.TelegraphRadius = TelegraphRadius;
				Params.ShockwaveClass = ShockwaveClass;
				Params.ShockwaveMaxRadius = ShockwaveMaxRadius;
				Params.ShockwaveDuration = ShockwaveDuration;
				Params.RandomStream = FRandomStream((i * 100) + AttackIndex);
				Params.BossPhase3Floor = BossPhase3Floor;

				if (i == Sequences.Num() - 1)
					Params.DebrisCount = 3;
				else
					Params.DebrisCount = 10;

				Params.BallSmash = this;

				FTransform BoneTransform;
				Sequences[i].GetAnimBoneTransform(BoneTransform, n"LeftAttach", AttackPoints[AttackIndex]);

				Params.AttackRelativePosition = BoneTransform.Location;
				Params.AttackRelativePosition.Z = 0;

				Rader.ActionQueue.Capability(
					UMeltdownBossBallSmashAttackCapability,
					Params
				);
			}

			// Idle for the remainder of the attack animation
			if (AttackPoints.Num() == 0)
				Rader.ActionQueue.Idle(Sequences[i].SequenceLength);
			else
				Rader.ActionQueue.Idle(Sequences[i].SequenceLength - AttackPoints.Last());
		}

		OnDone = OnSmashesDone;
		Rader.ActionQueue.Event(this, n"SmashesDone");

		RemoveActorDisable(this);
	}

	UFUNCTION()
	private void SmashesDone()
	{
		AddActorDisable(this);
		OnDone.ExecuteIfBound();
	}

	TArray<UAnimSequence> GetAttackSequences()
	{
		auto Feature = Cast<ULocomotionFeatureBallBossPortal>(Rader.Mesh.GetFeatureByTag(n"BallBossPortal"));

		TArray<UAnimSequence> Sequences;
		Sequences.Add(Feature.AnimData.EnterBallBoss.Sequence);
		Sequences.Add(Feature.AnimData.Attack1.Sequence);
		Sequences.Add(Feature.AnimData.Attack2.Sequence);
		Sequences.Add(Feature.AnimData.Attack3.Sequence);
		Sequences.Add(Feature.AnimData.Attack4.Sequence);
		Sequences.Add(Feature.AnimData.Attack5.Sequence);
		Sequences.Add(Feature.AnimData.FreakOut.Sequence);
		return Sequences;
	}
};

struct FMeltdownBossPhaseThreeBallSmashImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseThreeBallSmashEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashImpact(FMeltdownBossPhaseThreeBallSmashImpactParams ImpactParams) {}
}