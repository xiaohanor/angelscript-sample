class ABattlefieldHoverboard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
	UBattlefieldHoverboardComponent HoverboardComp;

	UFUNCTION(BlueprintEvent)
	void BP_SetTrailEffectHiddenState(bool bShouldHide) {}

	UFUNCTION(BlueprintEvent)
	void AttachBattlefieldSoundDef() {}
};

enum EBattlefieldWinState
{
	MioWon,
	ZoeWon,
	BothDraw
}

namespace Hoverboard
{
	UFUNCTION(BlueprintPure)
	ABattlefieldHoverboard GetHoverboard(AHazePlayerCharacter Player)
	{
		auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		return HoverboardComp.Hoverboard;
	};

	UFUNCTION(BlueprintCallable)
	void DisableSnowEffects(AHazePlayerCharacter Player)
	{
		auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		HoverboardComp.bSnowEffectsEnabled = false;
	}

	UFUNCTION(BlueprintCallable)
	void DisableHoverboardBackwardsSnipe(AHazePlayerCharacter Player)
	{
		auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		HoverboardComp.bBackwardsSnipeEnabled = false;
	}

	UFUNCTION(BlueprintCallable)
	void StartHoverboardFinishLineSlowdown(AHazePlayerCharacter Player, AActor MioFinishActorReference, AActor ZoeFinishActorReference)
	{
		auto HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		HoverboardComp.bHasFinished = true;
		HoverboardComp.MioFinishLineActor = MioFinishActorReference;
		HoverboardComp.ZoeFinishLineActor = ZoeFinishActorReference;
		Player.BlockCapabilities(CapabilityTags::Tutorial, n"Hoverboard::StartHoverboardFinishLineSlowdown");
	}

	UFUNCTION(BlueprintCallable)
	EBattlefieldWinState GetBattlefieldWinnerState()
	{
		const float MioFinishTime = UBattlefieldHoverboardComponent::Get(Game::Mio).FinishTime;
		const float ZoeFinishTime = UBattlefieldHoverboardComponent::Get(Game::Zoe).FinishTime;

		devCheck(MioFinishTime >= 0.0);
		devCheck(ZoeFinishTime >= 0.0);

		const float MioFinishPoints = UBattlefieldHoverboardComponent::Get(Game::Mio).FinishPoints;
		const float ZoeFinishPoints = UBattlefieldHoverboardComponent::Get(Game::Zoe).FinishPoints;

		//Whoever has more points wins
		if (MioFinishPoints > ZoeFinishPoints)
			return EBattlefieldWinState::MioWon;
		else if (MioFinishPoints < ZoeFinishPoints)
			return EBattlefieldWinState::ZoeWon;
		//Points draw, whoever crossed victory line first wins
		else
		{

			if(MioFinishTime <= ZoeFinishTime)
				return EBattlefieldWinState::MioWon;
			else
				return EBattlefieldWinState::ZoeWon;
		}
	}

	UFUNCTION(BlueprintCallable)
	void AttachBattlefieldSoundDef(AHazePlayerCharacter Player)
	{
		auto Hoverboard = GetHoverboard(Player);
		Hoverboard.AttachBattlefieldSoundDef();
	}
}