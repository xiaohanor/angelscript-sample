event void FVillageWobblyPerchPole(AVillageWobblyPerchPole Pole);

UCLASS(Abstract)
class AVillageWobblyPerchPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PoleRoot;

	UPROPERTY(DefaultComponent, Attach = PoleRoot)
	USceneComponent PerchRoot;

	UPROPERTY(DefaultComponent, Attach = PerchRoot)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent EnterZone;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.0;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence WobblePlayerAnim;

	UPROPERTY()
	FVillageWobblyPerchPole CriticalWobbling;

	UPROPERTY(EditAnywhere)
	bool bVisuallyWobble = true;

	TArray<AHazePlayerCharacter> PlayersOnPole;
	float WobbleMultiplier = 0.0;

	float TimeSinceLanded = 0.0;
	bool bUnbalanced = false;

	bool bDisabled = false;
	float DisableDuration = 0.5;
	float CurrentDisableDuration = 0.0;

	float StartWobbleDuration = 1.2;
	float ThrowOffDuration = 3.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"StartPerching");
		PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"StopPerching");
	}

	UFUNCTION()
	private void StartPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PlayersOnPole.AddUnique(Player);

		UVillageWobblyPerchPoleEffectEventHandler::Trigger_PlayerLanded(this);
	}

	UFUNCTION()
	private void StopPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		Player.StopSlotAnimation();

		PlayersOnPole.Remove(Player);

		if (PlayersOnPole.Num() == 0)
		{
			WobbleMultiplier = 0.0;
			TimeSinceLanded = 0.0;
			bUnbalanced = false;

			UVillageWobblyPerchPoleEffectEventHandler::Trigger_StopWobbling(this);
		}

		if (!Player.IsAnyCapabilityActive(n"Knockdown"))
			UVillageWobblyPerchPoleEffectEventHandler::Trigger_PlayerJumpedOff(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerOnPole(EHazePlayer InPlayer)
	{
		for (AHazePlayerCharacter Player : PlayersOnPole)
		{
			if (Player.Player == InPlayer)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDisabled)
		{
			CurrentDisableDuration += DeltaTime;
			if (CurrentDisableDuration >= DisableDuration)
			{
				bDisabled = false;
				CurrentDisableDuration = 0.0;
				PerchPointComp.Enable(this);
			}
			return;
		}
		
		if (PlayersOnPole.Num() != 0 && !bDisabled)
		{
			if (bVisuallyWobble)
			{
				WobbleMultiplier = Math::Clamp(WobbleMultiplier + (0.3 * DeltaTime), 0.0, 1.0);
				float PitchWobble = Math::Sin(Time::GameTimeSeconds * 12.0) * 2.0 * WobbleMultiplier;
				float RollWobble = Math::Sin(Time::GameTimeSeconds * 8.0) * 1.5 * WobbleMultiplier;

				PoleRoot.SetRelativeRotation(FRotator(PitchWobble, 0.0, RollWobble));
			}

			if (bUnbalanced)
			{
				for (AHazePlayerCharacter Player : PlayersOnPole)
				{
					float FFFrequency = 30.0;
					float FFIntensity = 0.4;
					FHazeFrameForceFeedback FF;
					FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * (FFIntensity * WobbleMultiplier); 
					FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * (FFIntensity * WobbleMultiplier);
					Player.SetFrameForceFeedback(FF);
				}
			}

			TimeSinceLanded += DeltaTime;

			if (!bUnbalanced && TimeSinceLanded >= StartWobbleDuration)
				StartUnbalancedState();

			if (TimeSinceLanded >= ThrowOffDuration)
				ThrowOffPlayers();
		}
		else
		{
			FRotator Rot = Math::RInterpShortestPathTo(PoleRoot.RelativeRotation, FRotator::ZeroRotator, DeltaTime, 2.0);
			PoleRoot.SetRelativeRotation(Rot);
		}
	}

	void StartUnbalancedState()
	{
		if (bUnbalanced)
			return;

		bUnbalanced = true;

		for (AHazePlayerCharacter Player : PlayersOnPole)
		{
			Player.PlaySlotAnimation(Animation = WobblePlayerAnim, bLoop = true, PlayRate = 1.5);
		}

		CriticalWobbling.Broadcast(this);

		UVillageWobblyPerchPoleEffectEventHandler::Trigger_StartWobbling(this);
	}

	void ThrowOffPlayers()
	{
		bDisabled = true;
		PerchPointComp.Disable(this);

		FVector Dir = PoleRoot.UpVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FVector Force = Dir * 800.0 + (FVector::UpVector * 100.0);

		for (AHazePlayerCharacter Player : PlayersOnPole)
			Player.ApplyKnockdown(Force, 3.0);

		UVillageWobblyPerchPoleEffectEventHandler::Trigger_PlayerKnockedOff(this);
	}
}

class UVillageWobblyPerchPoleEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void PlayerLanded() {}
	UFUNCTION(BlueprintEvent)
	void PlayerJumpedOff() {}
	UFUNCTION(BlueprintEvent)
	void StartWobbling() {}
	UFUNCTION(BlueprintEvent)
	void StopWobbling() {}
	UFUNCTION(BlueprintEvent)
	void PlayerKnockedOff() {}
}