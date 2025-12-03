event void FPrisonBossButtonMashVersusEvent();

UCLASS(Abstract)
class APrisonBossVersusButtonMashManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	FPrisonBossButtonMashVersusEvent OnCompleted;

	UPROPERTY()
	FPrisonBossButtonMashVersusEvent OnFailed;

	UPROPERTY(EditDefaultsOnly)
	UBlendSpace ZoeBS;

	UPROPERTY(EditDefaultsOnly)
	UBlendSpace DarkMioBS;

	APrisonBoss BossActor;

	bool bCompleted = false;

	UPROPERTY(BlueprintReadOnly)
	float ProgressValue = 0.0;

	float BothProgressRate = 0.25;
	float MioIndividualProgressRate = 0.4;
	float ZoeIndividualProgressRate = 0.3;

	float ElapsedDuration = 0.0;
	float AutoFailDuration = 10.0;
	float AutoFailProgressRate = 0.15;

	bool bApplyBlackAndWhiteEffect = false;
	float BlackAndWhiteStrength = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BossActor = TListedActors<APrisonBoss>().GetSingle();
	}

	UFUNCTION()
	void SequenceStarted()
	{
		UPrisonBossEffectEventHandler::Trigger_FinisherSequenceStarted(BossActor);
	}

	UFUNCTION()
	void StartButtonMash()
	{
		FButtonMashSettings SharedMashSettings;
		SharedMashSettings.ButtonAction = ActionNames::Interaction;
		SharedMashSettings.Difficulty = EButtonMashDifficulty::Hard;
		SharedMashSettings.Duration = 2.0;
		SharedMashSettings.bAllowPlayerCancel = false;
		SharedMashSettings.bBlockOtherGameplay = true;

		FButtonMashSettings ZoeSettings = SharedMashSettings;
		ZoeSettings.WidgetAttachComponent = BossActor.ZoeButtonMashAttachComp;
		ZoeSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;

		FButtonMashSettings MioSettings = SharedMashSettings;
		MioSettings.WidgetAttachComponent = BossActor.MioButtonMashAttachComp;
		MioSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnlyIgnoreAutomatic;

		Game::Zoe.StartButtonMash(ZoeSettings, this);
		Game::Mio.StartButtonMash(MioSettings, this);

		Game::Mio.SetButtonMashAllowCompletion(this, false);
		Game::Zoe.SetButtonMashAllowCompletion(this, false);

		Game::Zoe.PlayBlendSpace(ZoeBS);
		BossActor.PlayBlendSpace(DarkMioBS);

		SetActorTickEnabled(true);

		UPrisonBossVersusButtonMashEffectEventHandler::Trigger_ButtonMashStarted(this);
		UPrisonBossEffectEventHandler::Trigger_FinisherButtonMashStarted(BossActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCompleted)
		{
			if (bApplyBlackAndWhiteEffect)
			{
				UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Game::Zoe);
				BlackAndWhiteStrength = Math::FInterpConstantTo(BlackAndWhiteStrength, 1.0, DeltaTime, 2.0);
				PostProcessComp.BlackAndWhiteStrength.Apply(BlackAndWhiteStrength, this);
			}

			return;
		}

		ElapsedDuration += DeltaTime;

		float MioMashRate = 0.0;
		bool bIsMioMashSufficient = false;
		Game::Mio.GetButtonMashCurrentRate(this, MioMashRate, bIsMioMashSufficient);

		float ZoeMashRate = 0.0;
		bool bIsZoeMashSufficient = false;
		Game::Zoe.GetButtonMashCurrentRate(this, ZoeMashRate, bIsZoeMashSufficient);

		if (bIsMioMashSufficient && bIsZoeMashSufficient)
		{
			// If both are mashing, slightly favor mio
			ProgressValue -= BothProgressRate * DeltaTime;
		}
		else if (bIsMioMashSufficient)
		{
			// Mio is mashing, reduce progress
			ProgressValue -= MioIndividualProgressRate * DeltaTime;
		}
		else if (bIsZoeMashSufficient)
		{
			// Zoe is mashing, increase progress
			ProgressValue += ZoeIndividualProgressRate * DeltaTime;
		}
		else if (ElapsedDuration >= AutoFailDuration)
		{
			// Progress automatically if waiting too long
			ProgressValue -= AutoFailProgressRate * DeltaTime;
		}

		ProgressValue = Math::Clamp(ProgressValue, -1.0, 1.0);
		
		Game::Zoe.SetBlendSpaceValues(ProgressValue, 0.0);
		BossActor.SetBlendSpaceValues(ProgressValue, 0.0);

		float ProgressAlpha = Math::GetMappedRangeValueClamped(FVector2D(-1.0, 1.0), FVector2D(0.0, 1.0), ProgressValue);
		float LeftFFMultiplier = Math::Lerp(1.0, 0.0, ProgressAlpha);
		float RightFFMultiplier = Math::Lerp(0.0, 1.0, ProgressAlpha);
		float LeftFF = Math::Sin(Time::GameTimeSeconds * 20.0) * (0.05 * LeftFFMultiplier);
		float RightFF = Math::Sin(-Time::GameTimeSeconds * 20.0) * (0.05 * RightFFMultiplier);
		Game::Mio.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
		Game::Zoe.SetFrameForceFeedback(RightFF, LeftFF, 0.0, 0.0);

		if (HasControl())
		{
			if (ProgressValue >= 1.0)
				NetComplete();
			else if (ProgressValue <= -1.0)
				NetFail();
		}
	}

	UFUNCTION(NetFunction)
	void NetComplete()
	{
		Stop();

		OnCompleted.Broadcast();

		UPrisonBossVersusButtonMashEffectEventHandler::Trigger_Success(this);
		UPrisonBossEffectEventHandler::Trigger_FinisherSuccess(BossActor);
	}

	UFUNCTION(NetFunction)
	void NetFail()
	{
		Stop();

		OnFailed.Broadcast();

		Timer::SetTimer(this, n"StartApplyingBlackAndWhiteEffect", 3.8);

		UPrisonBossVersusButtonMashEffectEventHandler::Trigger_Fail(this);
		UPrisonBossEffectEventHandler::Trigger_FinisherFail(BossActor);
	}

	UFUNCTION()
	private void StartApplyingBlackAndWhiteEffect()
	{
		bApplyBlackAndWhiteEffect = true;
	}

	void Stop()
	{
		bCompleted = true;

		Game::Mio.StopButtonMash(this);
		Game::Zoe.StopButtonMash(this);
	}
}